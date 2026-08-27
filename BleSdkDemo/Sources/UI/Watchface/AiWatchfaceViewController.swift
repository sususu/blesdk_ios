import UIKit

/// AI watchface tab — watch-driven pipeline via AiSDK (Sifli only).
///
/// # Business
/// The phone does **not** pick a prompt and push a dial by itself. The user starts
/// AiSDK listening, then triggers generation / install **from the watch**. This
/// screen supplies panel geometry + device id and shows result / preview / progress.
///
/// # Flow (aligned with AiSDK Example `HwMainVC`)
/// 1. `startWorking` — set logger, error provider, callback, then start AiSDK.
/// 2. Fill `AiDeviceInfo` (Id via KVC, mac/name/type, width/height/corners, locale,
///    `platformType = .sifli`) and call `setDeviceInfo`.
/// 3. Watch requests AI image → `aiImageDone` / `aiPreviewDone`.
/// 4. Watch confirms install → AiSDK builds `SlifiCustomWatchface` and pushes;
///    App observes `aiStartSendingWatchface` / progress / `aiSentWatchface`.
///
/// # Caveats
/// - `AiDeviceInfo.Id` must be set with KVC (`"Id"`) — Swift `id` keyword clash.
/// - Style raw values: anime = **3**, pencil = **9** (reconstructed AiSDK header).
/// - Leave / pop the tab → `stopWorking` so the SDK does not keep listening.
/// - AI BLE push is owned by AiSDK; UI uses `host.setInstalling` only (no
///   `beginTransfer(.watchface)` from this tab). Avoid starting Online/Custom
///   install while AI is sending.
/// - Requires microphone permission (`NSMicrophoneUsageDescription`) for voice path.
final class AiWatchfaceViewController: UIViewController {
    weak var host: WatchfaceHostViewController?

    private let repo = BleRepository.shared
    private let bridge = AiWatchfaceBridge()
    private let presets = WatchfaceSizePreset.aiDefaults
    /// True after a successful `startWorking` until `stopWorking`.
    private var started = false

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let statusLabel = UIHelpers.makeLabel("")
    private let deviceIdLabel = UIHelpers.makeLabel("")
    private let resultImage = UIImageView()
    private let previewImage = UIImageView()
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()
    private let animeSwitch = UISwitch()
    private let pencilSwitch = UISwitch()

    private let widthField = UITextField()
    private let heightField = UITextField()
    private let cornerField = UITextField()
    private let thumbWField = UITextField()
    private let thumbHField = UITextField()
    private let thumbCornerField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        statusLabel.text = L10n.tr("wf_ai_hint")
        progress.isHidden = true

        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -12),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -12),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -24)
        ])

        [resultImage, previewImage].forEach {
            $0.contentMode = .scaleAspectFit
            $0.backgroundColor = .secondarySystemBackground
            $0.layer.cornerRadius = 8
            $0.clipsToBounds = true
            $0.heightAnchor.constraint(equalToConstant: 160).isActive = true
        }
        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        applyPreset(presets[0])
        [widthField, heightField, cornerField, thumbWField, thumbHField, thumbCornerField].forEach {
            $0.borderStyle = .roundedRect
            $0.keyboardType = .numberPad
        }

        let presetBtn = UIHelpers.makeButton(L10n.tr("wf_size_preset"))
        presetBtn.addTarget(self, action: #selector(pickPreset), for: .touchUpInside)
        let applyBtn = UIHelpers.makeButton(L10n.tr("wf_ai_apply"), primary: true)
        applyBtn.addTarget(self, action: #selector(applyDeviceInfo), for: .touchUpInside)
        let startBtn = UIHelpers.makeButton(L10n.tr("wf_ai_start"))
        startBtn.addTarget(self, action: #selector(startAi), for: .touchUpInside)
        let stopBtn = UIHelpers.makeButton(L10n.tr("wf_ai_stop"))
        stopBtn.addTarget(self, action: #selector(stopAi), for: .touchUpInside)

        animeSwitch.isOn = true
        animeSwitch.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        pencilSwitch.addTarget(self, action: #selector(styleChanged), for: .valueChanged)

        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(deviceIdLabel)
        content.addArrangedSubview(presetBtn)
        content.addArrangedSubview(makeFieldRow("W", widthField, "H", heightField))
        content.addArrangedSubview(makeFieldRow("Corner", cornerField, "ThumbW", thumbWField))
        content.addArrangedSubview(makeFieldRow("ThumbH", thumbHField, "ThumbR", thumbCornerField))
        content.addArrangedSubview(makeSwitchRow(L10n.tr("wf_ai_style_anime"), animeSwitch))
        content.addArrangedSubview(makeSwitchRow(L10n.tr("wf_ai_style_pencil"), pencilSwitch))
        content.addArrangedSubview(startBtn)
        content.addArrangedSubview(applyBtn)
        content.addArrangedSubview(stopBtn)
        content.addArrangedSubview(UIHelpers.makeLabel(L10n.tr("wf_ai_result"), style: .footnote))
        content.addArrangedSubview(resultImage)
        content.addArrangedSubview(UIHelpers.makeLabel(L10n.tr("wf_ai_preview"), style: .footnote))
        content.addArrangedSubview(previewImage)
        content.addArrangedSubview(progress)
        content.addArrangedSubview(logView)

        bridge.onLog = { [weak self] msg in self?.append(msg) }
        bridge.onStatus = { [weak self] msg in self?.statusLabel.text = msg }
        bridge.onResultImage = { [weak self] img in self?.resultImage.image = img }
        bridge.onPreviewImage = { [weak self] img in self?.previewImage.image = img }
        bridge.onProgress = { [weak self] p in
            self?.progress.isHidden = false
            self?.progress.progress = p
            // Keep host locked for mid-transfer progress values.
            self?.host?.setInstalling(p > 0 && p < 1)
        }
        bridge.onInstalling = { [weak self] installing in
            self?.host?.setInstalling(installing)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            bridge.stopWorking()
            host?.setInstalling(false)
        }
    }

    private func makeFieldRow(_ a: String, _ fa: UITextField, _ b: String, _ fb: UITextField) -> UIStackView {
        let la = UILabel(); la.text = a; la.font = .systemFont(ofSize: 12)
        let lb = UILabel(); lb.text = b; lb.font = .systemFont(ofSize: 12)
        let row = UIStackView(arrangedSubviews: [la, fa, lb, fb])
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        return row
    }

    private func makeSwitchRow(_ title: String, _ sw: UISwitch) -> UIStackView {
        let label = UILabel(); label.text = title
        let row = UIStackView(arrangedSubviews: [label, sw])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        return row
    }

    @objc private func pickPreset() {
        let sheet = UIAlertController(title: L10n.tr("wf_size_preset"), message: nil, preferredStyle: .actionSheet)
        for p in presets {
            sheet.addAction(UIAlertAction(title: p.label, style: .default) { [weak self] _ in
                self?.applyPreset(p)
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        present(sheet, animated: true)
    }

    private func applyPreset(_ p: WatchfaceSizePreset) {
        widthField.text = "\(p.width)"
        heightField.text = "\(p.height)"
        cornerField.text = "\(p.corner)"
        thumbWField.text = "\(p.thumbW)"
        thumbHField.text = "\(p.thumbH)"
        thumbCornerField.text = "\(p.thumbCorner)"
    }

    /// Mutual exclusion between anime / pencil; at least one style must stay on.
    @objc private func styleChanged() {
        if animeSwitch.isOn { pencilSwitch.isOn = false; bridge.setAnimeStyle(true) }
        if pencilSwitch.isOn { animeSwitch.isOn = false; bridge.setAnimeStyle(false) }
        if !animeSwitch.isOn && !pencilSwitch.isOn {
            animeSwitch.isOn = true
            bridge.setAnimeStyle(true)
        }
    }

    @objc private func startAi() {
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        bridge.startWorking()
        started = true
        statusLabel.text = L10n.tr("wf_ai_started")
        append(L10n.tr("wf_ai_started"))
        fetchIdAndApply()
    }

    @objc private func stopAi() {
        bridge.stopWorking()
        started = false
        host?.setInstalling(false)
        statusLabel.text = L10n.tr("wf_ai_stopped")
        append(L10n.tr("wf_ai_stopped"))
    }

    /// Re-pushes geometry / id into AiSDK (also starts if not yet started).
    @objc private func applyDeviceInfo() {
        guard started else {
            startAi()
            return
        }
        fetchIdAndApply()
    }

    private func fetchIdAndApply() {
        repo.getDeviceInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e):
                self.append(e.localizedDescription)
                self.applyInfo(deviceId: self.repo.loadBoundDevice()?.deviceId ?? "",
                               protocolVersion: self.repo.loadBoundDevice()?.protocolVersion)
            case .success(let info):
                self.deviceIdLabel.text = L10n.tr("wf_ai_device_id", info.id ?? "-")
                self.applyInfo(deviceId: info.id ?? "", protocolVersion: info.protocolVersion)
            }
        }
    }

    /// Builds `AiDeviceInfo` from fields + connection metadata and pushes to AiSDK.
    private func applyInfo(deviceId: String, protocolVersion: Int?) {
        let panel = AiDeviceInfoBuilder.Panel(
            width: Int(widthField.text ?? "") ?? 480,
            height: Int(heightField.text ?? "") ?? 480,
            cornerRadius: Int(cornerField.text ?? "") ?? 240,
            thumbnailWidth: Int(thumbWField.text ?? "") ?? 264,
            thumbnailHeight: Int(thumbHField.text ?? "") ?? 264,
            thumbnailCornerRadius: Int(thumbCornerField.text ?? "") ?? 132
        )
        let info = AiDeviceInfoBuilder.make(
            repo: repo,
            deviceId: deviceId,
            panel: panel,
            protocolVersion: protocolVersion,
            userPrefersJieli: false
        )
        bridge.setDeviceInfo(info)
        append(L10n.tr("wf_ai_applied", info.width, info.height))
        let pv = protocolVersion ?? repo.loadBoundDevice()?.protocolVersion
        let platform = AiDeviceInfoBuilder.resolvedPlatform(
            protocolVersion: pv,
            userPrefersJieli: false,
            repo: repo
        )
        append("protocolVersion=\(pv.map(String.init) ?? "-") platform=\(AiPlatformHelper.platformLabel(platform)) type=\(info.type ?? "-")")
        statusLabel.text = L10n.tr("wf_ai_ready_on_watch")
    }

    private func append(_ s: String) {
        let work = { [weak self] in
            guard let self else { return }
            let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logView.text = (self.logView.text ?? "") + "\(ts)  \(s)\n"
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}

/// ObjC bridge for AiSDK callbacks (implements protocols from AiSDK headers).
///
/// Keeps UIKit updates on the main queue. Does not own BLE transfer locking —
/// that stays inside AiSDK / SifliWatchfaceSDK; the VC only mirrors progress
/// into `WatchfaceHostViewController.setInstalling`.
final class AiWatchfaceBridge: NSObject, AiSDKCallback, ILog, IAiErrorMessageProvider {
    var onLog: ((String) -> Void)?
    var onStatus: ((String) -> Void)?
    var onResultImage: ((UIImage?) -> Void)?
    var onPreviewImage: ((UIImage?) -> Void)?
    var onProgress: ((Float) -> Void)?
    var onInstalling: ((Bool) -> Void)?

    func startWorking() {
        clearAiPreviewZipCache()
        let ai = AiSDK.sharedInstance()
        ai.setLogger(self)
        ai.setAiErrorMessageProvider(self)
        ai.callback = self
        ai.startWorking()
        setAnimeStyle(true)
    }

    private func clearAiPreviewZipCache() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let caches else { return }
        let fm = FileManager.default
        for name in ["tempZipFolder", "target.zip", "JW_AIPreview1.bin"] {
            try? fm.removeItem(at: caches.appendingPathComponent(name))
        }
    }

    func stopWorking() {
        AiSDK.sharedInstance().stopWorking()
    }

    func setDeviceInfo(_ info: AiDeviceInfo) {
        AiSDK.sharedInstance().setDeviceInfo(info)
    }

    func setAnimeStyle(_ anime: Bool) {
        // AiStyleAnime = 3, AiStylePencilDrawing = 9 in reconstructed header.
        AiSDK.sharedInstance().aiStyle = AiStyle(rawValue: anime ? 3 : 9) ?? AiStyle(rawValue: 3)!
    }

    // MARK: - ILog
    func d(_ msg: String!) { emitLog("[D] \(msg ?? "")") }
    func i(_ msg: String!) { emitLog("[I] \(msg ?? "")") }
    func w(_ msg: String!) { emitLog("[W] \(msg ?? "")") }
    func e(_ msg: String!) { emitLog("[E] \(msg ?? "")") }

    private func emitLog(_ msg: String) {
        if Thread.isMainThread {
            onLog?(msg)
        } else {
            DispatchQueue.main.async { [weak self] in self?.onLog?(msg) }
        }
    }

    private func emitStatus(_ msg: String) {
        if Thread.isMainThread {
            onStatus?(msg)
        } else {
            DispatchQueue.main.async { [weak self] in self?.onStatus?(msg) }
        }
    }

    // MARK: - IAiErrorMessageProvider
    func message(forCode code: Int) -> String! {
        AiSDK.sharedInstance().errorMsg(withCode: code)
    }

    // MARK: - AiSDKCallback

    /// Cloud / on-device AI result bitmap for the generated face art.
    func aiImageDone(_ image: UIImage?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onResultImage?(image)
            if code != 0 {
                self.onStatus?(errorMsg ?? "aiImage code=\(code)")
                self.onLog?(errorMsg ?? "aiImage code=\(code)")
            } else {
                self.onStatus?(L10n.tr("wf_ai_image_ok"))
            }
        }
    }

    /// Dial preview (widgets composited) before / during install confirmation.
    func aiPreviewDone(_ image: UIImage?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onPreviewImage?(image)
            if code != 0 {
                self.onLog?(errorMsg ?? "preview code=\(code)")
            } else {
                self.onStatus?(L10n.tr("wf_ai_preview_ok"))
            }
        }
    }

    func aiStartSendingPreview() {
        DispatchQueue.main.async {
            self.onLog?("[CB] aiStartSendingPreview")
        }
    }

    func aiSentPreview(_ code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onLog?("[CB] aiSentPreview code=\(code) \(errorMsg ?? "")")
            if code != 0 {
                self.onStatus?(L10n.tr("ai_preview_push_failed_hint"))
            }
        }
    }

    func aiStartSendingWatchface() {
        DispatchQueue.main.async {
            self.onInstalling?(true)
            self.onStatus?(L10n.tr("wf_ai_installing"))
        }
    }

    /// Progress is typically `0...1` from AiSDK (not 0...100).
    func aiSendingWatchfaceProgressUpdated(_ progress: Float) {
        DispatchQueue.main.async { self.onProgress?(progress) }
    }

    func aiSentWatchface(_ watchface: SlifiCustomWatchface?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onInstalling?(false)
            self.onProgress?(code == 0 ? 1 : 0)
            if code == 0 {
                self.onStatus?(L10n.tr("wf_install_ok"))
                self.onLog?(L10n.tr("wf_install_ok") + " name=\(watchface?.name ?? "-")")
            } else {
                self.onStatus?(L10n.tr("wf_install_fail"))
                self.onLog?(errorMsg ?? "code=\(code)")
            }
        }
    }
}
