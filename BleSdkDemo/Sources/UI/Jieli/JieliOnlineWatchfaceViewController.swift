import UIKit

/// Online watchface catalog + install (Jieli path).
///
/// # Business
/// Lists dials for the connected / bound `deviceType` from the Huawo test catalog,
/// then installs via `BleRepository.installJieliOnlineWatchface`.
///
/// # Flow
/// 1. Resolve `deviceType` (bound device first, else live `getDeviceInfo`).
/// 2. `WatchfaceApi.fetchOnlineWatchfaces` on a background queue.
/// 3. Tap cell → action sheet → install:
///    - Download the shared catalog package (+ MD5).
///    - Push it through JL multiple-file transfer (`onlineDial`).
///
/// # Caveats
/// - Requires BLE connected for install; list can load from bound type offline.
/// - `busy` + `host.setInstalling` block overlapping installs and tab switches.
final class JieliOnlineWatchfaceViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var host: JieliWatchfaceHostViewController?

    private let repo = BleRepository.shared
    private var items: [OnlineWatchface] = []
    /// Product type string used in the catalog URL path segment.
    private var deviceType = ""
    /// Local UI guard; repository still enforces the BLE transfer lock.
    private var busy = false

    private let statusLabel = UIHelpers.makeLabel("")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()
    private var collection: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        statusLabel.text = L10n.tr("feature_ready")
        progress.isHidden = true

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.register(JieliOnlineWatchfaceCell.self, forCellWithReuseIdentifier: JieliOnlineWatchfaceCell.reuseId)

        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = 8

        let refresh = UIHelpers.makeButton(L10n.tr("wf_refresh_list"))
        refresh.addTarget(self, action: #selector(refreshList), for: .touchUpInside)

        logView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        let stack = UIStackView(arrangedSubviews: [
            UIHelpers.makeCard([statusLabel, progress], title: L10n.tr("ui_status")),
            UIHelpers.makeCard([UIHelpers.makeGrid([refresh])], title: L10n.tr("ui_actions")),
            collection, UIHelpers.makeLogSection(logView)
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            collection.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        resolveDeviceTypeThenLoad()
    }

    /// Prefers bound `type`; if missing and connected, queries device info once.
    private func resolveDeviceTypeThenLoad() {
        if let bound = repo.loadBoundDevice(), let t = bound.type, !t.isEmpty {
            deviceType = t
            loadList()
            return
        }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        repo.getDeviceInfo { [weak self] result in
            guard let self = self else { return }
            if case .success(let info) = result, let t = info.type, !t.isEmpty {
                self.deviceType = t
            }
            self.loadList()
        }
    }

    @objc private func refreshList() {
        guard !busy else { return }
        if deviceType.isEmpty {
            resolveDeviceTypeThenLoad()
        } else {
            loadList()
        }
    }

    private func loadList() {
        guard !deviceType.isEmpty else {
            append(L10n.tr("wf_err_no_type"))
            statusLabel.text = L10n.tr("wf_err_no_type")
            return
        }
        statusLabel.text = L10n.tr("wf_loading")
        // Sync HTTP — keep off the main thread.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let list = try WatchfaceApi.fetchOnlineWatchfaces(deviceType: self.deviceType)
                DispatchQueue.main.async {
                    self.items = list
                    self.collection.reloadData()
                    self.statusLabel.text = L10n.tr("wf_list_count", list.count, self.deviceType)
                    self.append(L10n.tr("wf_list_count", list.count, self.deviceType))
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.text = L10n.tr("feature_failed")
                    self.append(error.localizedDescription)
                }
            }
        }
    }

    /// Runs the full install pipeline and locks host navigation until completion.
    private func install(_ item: OnlineWatchface) {
        guard !busy else { return }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        busy = true
        host?.setInstalling(true)
        progress.isHidden = false
        progress.progress = 0
        statusLabel.text = L10n.tr("wf_installing", item.name)
        append(L10n.tr("wf_install_start", item.name))

        repo.installJieliOnlineWatchface(item, onPhase: { [weak self] phase in
            self?.statusLabel.text = Self.phaseText(phase, name: item.name)
        }, onProgress: { [weak self] p in
            self?.progress.progress = Float(p) / 100.0
        }, onLog: { [weak self] msg in
            self?.append(msg)
        }, completion: { [weak self] result in
            guard let self = self else { return }
            self.busy = false
            self.host?.setInstalling(false)
            switch result {
            case .success:
                self.statusLabel.text = L10n.tr("wf_install_ok")
                self.append(L10n.tr("wf_install_ok"))
                self.progress.progress = 1
            case .failure(let e):
                self.statusLabel.text = L10n.tr("wf_install_fail")
                self.append(e.localizedDescription)
            }
        })
    }

    private static func phaseText(_ phase: OnlineWatchfaceInstallPhase, name: String) -> String {
        switch phase {
        case .idle: return L10n.tr("feature_ready")
        case .checking: return L10n.tr("wf_phase_checking")
        case .switching: return L10n.tr("wf_phase_switching")
        case .downloading: return L10n.tr("wf_phase_downloading")
        case .installing: return L10n.tr("wf_installing", name)
        case .success: return L10n.tr("wf_install_ok")
        case .failed: return L10n.tr("wf_install_fail")
        }
    }

    private func append(_ s: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logView.text = (logView.text ?? "") + "\(ts)  \(s)\n"
    }

    // MARK: - Collection

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JieliOnlineWatchfaceCell.reuseId, for: indexPath) as! JieliOnlineWatchfaceCell
        cell.configure(items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !busy else { return }
        let item = items[indexPath.item]
        let sheet = UIAlertController(title: item.name, message: L10n.tr("wf_size_kb", item.byteSizeKb), preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: L10n.tr("wf_install"), style: .default) { [weak self] _ in
            self?.install(item)
        })
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = collectionView.cellForItem(at: indexPath)
            pop.sourceRect = collectionView.cellForItem(at: indexPath)?.bounds ?? .zero
        }
        present(sheet, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = (collectionView.bounds.width - 8) / 2
        return CGSize(width: floor(w), height: floor(w) + 36)
    }
}

/// Grid cell: thumbnail + name. Cancels in-flight image loads on reuse.
private final class JieliOnlineWatchfaceCell: UICollectionViewCell {
    static let reuseId = "JieliOnlineWatchfaceCell"
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private var loadTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemFill
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ item: OnlineWatchface) {
        titleLabel.text = item.name
        imageView.image = nil
        loadTask?.cancel()
        let urlString = WatchfaceApi.resolveFileUrl(item.thumbnail)
        guard let url = URL(string: urlString), !urlString.isEmpty else { return }
        loadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.imageView.image = img }
        }
        loadTask?.resume()
    }
}
