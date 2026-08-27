import UIKit
import AVFoundation

/// AI DEMO — UI/logic aligned with AiSDK Example `HwMainVC` and Android `AiTestActivity`.
///
/// Flow: Start AiSDK → Apply device info (size / platform) → trigger AI on the watch →
/// observe logs, result/preview images, Q&A / translate / meeting callbacks.
final class AiDemoViewController: UIViewController {
    private let repo = BleRepository.shared
    private let bridge = AiDemoBridge()
    private let presets = WatchfaceSizePreset.aiDefaults
    private var started = false
    private var useJieli = false

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let statusLabel = UIHelpers.makeLabel("", style: .subheadline)
    private let deviceLabel = UIHelpers.makeLabel("", style: .footnote)
    private let resultImage = UIImageView()
    private let previewImage = UIImageView()
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()
    private let jieliSwitch = UISwitch()

    private let widthField = UITextField()
    private let heightField = UITextField()
    private let cornerField = UITextField()
    private let thumbWField = UITextField()
    private let thumbHField = UITextField()
    private let thumbCornerField = UITextField()

    private enum DefaultsKey {
        static let width = "ai_demo_width"
        static let height = "ai_demo_height"
        static let corner = "ai_demo_corner"
        static let thumbW = "ai_demo_thumb_w"
        static let thumbH = "ai_demo_thumb_h"
        static let thumbR = "ai_demo_thumb_r"
        static let jieli = "ai_demo_jieli"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("ai_demo")
        view.backgroundColor = .systemBackground
        statusLabel.text = L10n.tr("ai_demo_hint")
        statusLabel.numberOfLines = 0
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
        logView.backgroundColor = .black
        logView.textColor = .green
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        restoreFields()
        syncPlatformFromDevice(protocolVersion: repo.loadBoundDevice()?.protocolVersion)
        jieliSwitch.isOn = useJieli
        [widthField, heightField, cornerField, thumbWField, thumbHField, thumbCornerField].forEach {
            $0.borderStyle = .roundedRect
            $0.keyboardType = .numberPad
        }

        let presetBtn = UIHelpers.makeButton(L10n.tr("wf_size_preset"))
        presetBtn.addTarget(self, action: #selector(pickPreset), for: .touchUpInside)
        let startBtn = UIHelpers.makeButton(L10n.tr("wf_ai_start"))
        startBtn.addTarget(self, action: #selector(startAi), for: .touchUpInside)
        let applyBtn = UIHelpers.makeButton(L10n.tr("wf_ai_apply"), primary: true)
        applyBtn.addTarget(self, action: #selector(applyDeviceInfo), for: .touchUpInside)
        let stopBtn = UIHelpers.makeButton(L10n.tr("wf_ai_stop"))
        stopBtn.addTarget(self, action: #selector(stopAi), for: .touchUpInside)
        let clearLogBtn = UIHelpers.makeButton(L10n.tr("ai_clear_log"))
        clearLogBtn.addTarget(self, action: #selector(clearLog), for: .touchUpInside)

        jieliSwitch.isOn = useJieli
        jieliSwitch.addTarget(self, action: #selector(platformChanged), for: .valueChanged)

        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(deviceLabel)
        content.addArrangedSubview(presetBtn)
        content.addArrangedSubview(makeFieldRow("W", widthField, "H", heightField))
        content.addArrangedSubview(makeFieldRow("Corner", cornerField, "ThumbW", thumbWField))
        content.addArrangedSubview(makeFieldRow("ThumbH", thumbHField, "ThumbR", thumbCornerField))
        content.addArrangedSubview(makeSwitchRow(L10n.tr("ai_platform_jieli"), jieliSwitch))
        content.addArrangedSubview(makeButtonRow([startBtn, stopBtn]))
        content.addArrangedSubview(applyBtn)
        content.addArrangedSubview(clearLogBtn)
        content.addArrangedSubview(makeImagePairRow())
        content.addArrangedSubview(progress)
        content.addArrangedSubview(UIHelpers.makeLabel(L10n.tr("logs"), style: .footnote))
        content.addArrangedSubview(logView)

        bridge.onLog = { [weak self] msg in self?.append(msg) }
        bridge.onStatus = { [weak self] msg in self?.statusLabel.text = msg }
        bridge.onResultImage = { [weak self] img in self?.resultImage.image = img }
        bridge.onPreviewImage = { [weak self] img in self?.previewImage.image = img }
        bridge.onProgress = { [weak self] p in
            self?.progress.isHidden = false
            self?.progress.progress = p
        }
        bridge.onBusy = { [weak self] busy in
            self?.progress.isHidden = !busy && (self?.progress.progress ?? 0) >= 1
        }

        refreshDeviceLabel()
        requestMicIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            bridge.stopWorking()
            started = false
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

    private func makeButtonRow(_ buttons: [UIButton]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: buttons)
        row.axis = .horizontal
        row.spacing = 10
        row.distribution = .fillEqually
        return row
    }

    private func makeImagePairRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [
            makeLabeledImageColumn(L10n.tr("wf_ai_result"), resultImage),
            makeLabeledImageColumn(L10n.tr("wf_ai_preview"), previewImage)
        ])
        row.axis = .horizontal
        row.spacing = 10
        row.distribution = .fillEqually
        row.alignment = .fill
        return row
    }

    private func makeLabeledImageColumn(_ title: String, _ imageView: UIImageView) -> UIStackView {
        let label = UIHelpers.makeLabel(title, style: .footnote)
        let col = UIStackView(arrangedSubviews: [label, imageView])
        col.axis = .vertical
        col.spacing = 4
        col.distribution = .fill
        return col
    }

    private func restoreFields() {
        let ud = UserDefaults.standard
        let p = presets[0]
        widthField.text = "\(ud.object(forKey: DefaultsKey.width) as? Int ?? p.width)"
        heightField.text = "\(ud.object(forKey: DefaultsKey.height) as? Int ?? p.height)"
        cornerField.text = "\(ud.object(forKey: DefaultsKey.corner) as? Int ?? p.corner)"
        thumbWField.text = "\(ud.object(forKey: DefaultsKey.thumbW) as? Int ?? p.thumbW)"
        thumbHField.text = "\(ud.object(forKey: DefaultsKey.thumbH) as? Int ?? p.thumbH)"
        thumbCornerField.text = "\(ud.object(forKey: DefaultsKey.thumbR) as? Int ?? p.thumbCorner)"
        useJieli = ud.bool(forKey: DefaultsKey.jieli)
    }

    private func persistFields() {
        let ud = UserDefaults.standard
        ud.set(Int(widthField.text ?? "") ?? 480, forKey: DefaultsKey.width)
        ud.set(Int(heightField.text ?? "") ?? 480, forKey: DefaultsKey.height)
        ud.set(Int(cornerField.text ?? "") ?? 240, forKey: DefaultsKey.corner)
        ud.set(Int(thumbWField.text ?? "") ?? 264, forKey: DefaultsKey.thumbW)
        ud.set(Int(thumbHField.text ?? "") ?? 264, forKey: DefaultsKey.thumbH)
        ud.set(Int(thumbCornerField.text ?? "") ?? 132, forKey: DefaultsKey.thumbR)
        ud.set(useJieli, forKey: DefaultsKey.jieli)
    }

    private func refreshDeviceLabel() {
        let name = repo.connectedName() ?? "-"
        let mac = repo.connectedMac() ?? "-"
        deviceLabel.text = "\(name)\n\(mac)\n\(useJieli ? "JieLi" : "Sifli")"
        deviceLabel.numberOfLines = 3
    }

    private func requestMicIfNeeded() {
        // AiSDK voice path needs mic; system prompt appears on first record if not granted.
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    @objc private func pickPreset() {
        let sheet = UIAlertController(title: L10n.tr("wf_size_preset"), message: nil, preferredStyle: .actionSheet)
        for p in presets {
            sheet.addAction(UIAlertAction(title: p.label, style: .default) { [weak self] _ in
                self?.widthField.text = "\(p.width)"
                self?.heightField.text = "\(p.height)"
                self?.cornerField.text = "\(p.corner)"
                self?.thumbWField.text = "\(p.thumbW)"
                self?.thumbHField.text = "\(p.thumbH)"
                self?.thumbCornerField.text = "\(p.thumbCorner)"
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        present(sheet, animated: true)
    }

    @objc private func platformChanged() {
        useJieli = jieliSwitch.isOn
        refreshDeviceLabel()
        if started { fetchIdAndApply() }
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
        statusLabel.text = L10n.tr("wf_ai_stopped")
        append(L10n.tr("wf_ai_stopped"))
    }

    /// Re-pushes geometry / platform / id into AiSDK (starts AiSDK first if needed).
    @objc private func applyDeviceInfo() {
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        guard started else {
            startAi()
            return
        }
        fetchIdAndApply()
    }

    @objc private func clearLog() {
        logView.text = ""
    }

    private func fetchIdAndApply() {
        repo.getDeviceInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e):
                self.append(e.localizedDescription)
                let bound = self.repo.loadBoundDevice()
                self.syncPlatformFromDevice(protocolVersion: bound?.protocolVersion)
                self.applyInfo(deviceId: bound?.deviceId ?? "", protocolVersion: bound?.protocolVersion)
            case .success(let info):
                self.append(L10n.tr("wf_ai_device_id", info.id ?? "-"))
                self.syncPlatformFromDevice(protocolVersion: info.protocolVersion)
                self.applyInfo(deviceId: info.id ?? "", protocolVersion: info.protocolVersion)
            }
        }
    }

    /// JieLi devices use protocolVersion >= 100 (see SDK_iOS.md / HaWoFit).
    private func syncPlatformFromDevice(protocolVersion: Int?) {
        let shouldUseJieli = AiPlatformHelper.isJieliProtocol(protocolVersion)
        if shouldUseJieli != useJieli {
            useJieli = shouldUseJieli
            jieliSwitch.setOn(shouldUseJieli, animated: true)
            if let pv = protocolVersion {
                append(L10n.tr(shouldUseJieli ? "ai_platform_detect_jieli" : "ai_platform_detect_sifli", pv))
            }
        }
    }

    private func applyInfo(deviceId: String) {
        applyInfo(deviceId: deviceId, protocolVersion: nil)
    }

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
            userPrefersJieli: useJieli
        )
        let pv = protocolVersion ?? repo.loadBoundDevice()?.protocolVersion
        let platform = AiDeviceInfoBuilder.resolvedPlatform(
            protocolVersion: pv,
            userPrefersJieli: useJieli,
            repo: repo
        )
        bridge.setDeviceInfo(info, platform: platform)
        persistFields()
        refreshDeviceLabel()
        append(L10n.tr("wf_ai_applied", info.width, info.height))
        append(L10n.tr("ai_platform_applied", AiPlatformHelper.platformLabel(platform)))
        if let pv = protocolVersion ?? repo.loadBoundDevice()?.protocolVersion {
            append("protocolVersion=\(pv) type=\(info.type ?? "-")")
        }
        statusLabel.text = L10n.tr("ai_demo_ready")
    }

    private func append(_ s: String) {
        let work = { [weak self] in
            guard let self else { return }
            let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.logView.text = (self.logView.text ?? "") + "\(ts)  \(s)\n"
            let bottom = NSRange(location: max((self.logView.text as NSString).length - 1, 0), length: 1)
            DispatchQueue.main.async {
                self.logView.scrollRangeToVisible(bottom)
            }
        }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
