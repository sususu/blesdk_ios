import UIKit

/// Host for Custom / Online / AI watchface tabs (Sifli path only).
///
/// # Business
/// Single entry from Home → Watchface. Tabs mirror Android demo / HaWoFit:
/// Custom editor, Online catalog install, AI (watch-driven via AiSDK).
///
/// # Install lock
/// Child VCs call `setInstalling(true)` while a push / AI transfer is in flight.
/// While locked: segment control disabled, back button hidden, interactive pop off,
/// and segment changes are ignored (selection snaps back).
/// This is **UI navigation** lock; BLE exclusivity still uses
/// `BleRepository.beginTransfer(.watchface)` for online/custom.
///
/// # Default tab
/// Online (index 1) — most common demo path after bind + connect.
final class JieliWatchfaceHostViewController: UIViewController {
    private let segmented = UISegmentedControl(items: ["", "", ""])
    private let container = UIView()
    private var childrenVCs: [UIViewController] = []
    private var currentIndex = 0
    /// True while any child reports an in-flight install / AI send.
    private(set) var installing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = L10n.tr("watchface_jieli")
        applyLocalizedSegments()

        let custom = JieliCustomWatchfaceViewController()
        let online = JieliOnlineWatchfaceViewController()
        let ai = JieliAiWatchfaceViewController()
        custom.host = self
        online.host = self
        ai.host = self
        childrenVCs = [custom, online, ai]

        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmented.selectedSegmentIndex = 1
        segmented.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)
        view.addSubview(container)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        showChild(at: 1)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLocalizedSegments()
    }

    /// Locks / unlocks tab switching and navigation while a transfer runs.
    func setInstalling(_ value: Bool) {
        installing = value
        segmented.isEnabled = !value
        navigationItem.hidesBackButton = value
        if value {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil, installing {
            // Prefer keeping installing=true so the user finishes / cancels in-tab
            // rather than popping mid-transfer. Hard block of pop is limited by UIKit;
            // back button is already hidden while installing.
        }
    }

    private func applyLocalizedSegments() {
        segmented.setTitle(L10n.tr("wf_tab_custom"), forSegmentAt: 0)
        segmented.setTitle(L10n.tr("wf_tab_online"), forSegmentAt: 1)
        segmented.setTitle(L10n.tr("wf_tab_ai"), forSegmentAt: 2)
    }

    @objc private func segmentChanged() {
        guard !installing else {
            segmented.selectedSegmentIndex = currentIndex
            return
        }
        showChild(at: segmented.selectedSegmentIndex)
    }

    private func showChild(at index: Int) {
        guard childrenVCs.indices.contains(index) else { return }
        let previous = childrenVCs[safe: currentIndex]
        previous?.willMove(toParent: nil)
        previous?.view.removeFromSuperview()
        previous?.removeFromParent()

        let next = childrenVCs[index]
        addChild(next)
        next.view.frame = container.bounds
        next.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(next.view)
        next.didMove(toParent: self)
        currentIndex = index
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
