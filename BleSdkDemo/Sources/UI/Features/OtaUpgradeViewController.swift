import UIKit

/// Sifli firmware OTA demo screen (aligned with Android `OtaUpgradeFragment`).
///
/// # Flow
/// 1. **Refresh** — `getDeviceInfo` (+ `getFirmwareVersion` fallback)
/// 2. **Check update** — `OtaFirmwareApi.checkUpgrade` against test server
/// 3. **Start upgrade** — battery ≥ 30%, upgrade status `none`, then
///    `BleRepository.startSifliOta` (download/unzip + `SFOTAManager.startOTANand`)
/// 4. **Cancel** — `cancelTransfer` → `SifliOtaPusher.stop`
///
/// Push path is **Sifli-only** (HaWoFit `OtaHandler.startSifliOta`). JL / Realtek are not implemented.
final class OtaUpgradeViewController: UIViewController {
    private let repo = BleRepository.shared

    private let statusLabel = UIHelpers.makeLabel("")
    private let macLabel = UIHelpers.makeLabel("")
    private let firmwareLabel = UIHelpers.makeLabel("")
    private let parsedLabel = UIHelpers.makeLabel("")
    private let newVersionLabel = UIHelpers.makeLabel("")
    private let infoLabel = UIHelpers.makeLabel("")
    private let phaseLabel = UIHelpers.makeLabel("")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()

    private var cachedMac = ""
    private var cachedFw = ""
    private var cachedType = ""
    private var cachedDeviceId = ""
    private var upgradeInfo: OtaUpgradeInfo?
    private var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("ota")
        view.backgroundColor = .systemBackground
        statusLabel.text = L10n.tr("feature_ready")
        macLabel.text = L10n.tr("ota_mac", "-")
        firmwareLabel.text = L10n.tr("ota_firmware", "-")
        parsedLabel.text = L10n.tr("ota_parsed", "-")
        newVersionLabel.text = ""
        infoLabel.text = ""
        infoLabel.textColor = .secondaryLabel
        phaseLabel.textColor = .secondaryLabel

        let refresh = UIHelpers.makeButton(L10n.tr("ota_refresh"))
        let check = UIHelpers.makeButton(L10n.tr("ota_check"))
        let start = UIHelpers.makeButton(L10n.tr("ota_start"), primary: true)
        let cancel = UIHelpers.makeButton(L10n.tr("ota_cancel"))
        refresh.addTarget(self, action: #selector(refreshDeviceInfo), for: .touchUpInside)
        check.addTarget(self, action: #selector(checkUpgrade), for: .touchUpInside)
        start.addTarget(self, action: #selector(startUpgrade), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelUpgrade), for: .touchUpInside)
        start.tag = 1001

        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemBackground
        logView.layer.cornerRadius = 8

        let stack = UIStackView(arrangedSubviews: [
            statusLabel, macLabel, firmwareLabel, parsedLabel, newVersionLabel, infoLabel,
            refresh, check, start, cancel, phaseLabel, progress, logView
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            logView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])
        updateStartEnabled()
        refreshDeviceInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only stop when leaving this screen — not on transient disappear events.
        guard busy, isMovingFromParent || isBeingDismissed else { return }
        repo.cancelTransfer()
        setBusy(false)
    }

    private func updateStartEnabled() {
        let start = view.viewWithTag(1001) as? UIButton
        start?.isEnabled = !busy && upgradeInfo != nil && !(upgradeInfo?.firmwares.isEmpty ?? true)
    }

    private func setBusy(_ value: Bool) {
        busy = value
        updateStartEnabled()
        UIApplication.shared.isIdleTimerDisabled = value
    }

    /// Step 1: pull MAC / firmware / type / deviceId from the connected watch (or bound store).
    @objc private func refreshDeviceInfo() {
        guard !busy else { return }
        statusLabel.text = L10n.tr("ota_refreshing")
        if !repo.isConnected() {
            if let bound = repo.loadBoundDevice() {
                cachedMac = bound.macAddress
                cachedFw = bound.firmwareVersion ?? ""
                cachedType = bound.type ?? ""
                cachedDeviceId = bound.deviceId ?? ""
                applyDeviceTexts()
            }
            statusLabel.text = L10n.tr("status_need_connect")
            append(L10n.tr("status_need_connect"))
            return
        }
        repo.getDeviceInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e):
                self.statusLabel.text = L10n.tr("feature_failed")
                self.append(e.localizedDescription)
            case .success(let info):
                self.cachedMac = info.mac?.nilIfEmpty ?? self.repo.connectedMac() ?? ""
                self.cachedFw = info.firmwareVersion ?? ""
                self.cachedType = info.type ?? ""
                self.cachedDeviceId = info.id ?? ""
                let finish: () -> Void = {
                    self.applyDeviceTexts()
                    self.statusLabel.text = L10n.tr("ota_refresh_ok")
                    self.append(L10n.tr("ota_log_device", self.cachedMac.nilIfEmpty ?? "-", self.cachedFw.nilIfEmpty ?? "-"))
                }
                if self.cachedFw.isEmpty {
                    self.repo.getFirmwareVersion { fwResult in
                        if case .success(let fw) = fwResult { self.cachedFw = fw }
                        finish()
                    }
                } else {
                    finish()
                }
            }
        }
    }

    private func applyDeviceTexts() {
        macLabel.text = L10n.tr("ota_mac", cachedMac.nilIfEmpty ?? "-")
        firmwareLabel.text = L10n.tr("ota_firmware", cachedFw.nilIfEmpty ?? "-")
        let parsed = FirmwareVersionUtils.formatDisplay(cachedFw)
        parsedLabel.text = L10n.tr("ota_parsed", parsed.nilIfEmpty ?? "-")
        
        HwBluetoothSDK.sharedInstance()
    }

    /// Step 2: ask the test server whether a newer package exists.
    @objc private func checkUpgrade() {
        guard !busy else { return }
        if cachedFw.isEmpty || cachedMac.isEmpty {
            refreshDeviceInfo()
        }
        guard !cachedFw.isEmpty else {
            append(L10n.tr("ota_err_no_fw"))
            return
        }
        setBusy(true)
        statusLabel.text = L10n.tr("ota_checking")
        phaseLabel.text = L10n.tr("ota_phase_check")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let info = try OtaFirmwareApi.checkUpgrade(
                    currentFirmwareRaw: self.cachedFw,
                    productCode: self.cachedType,
                    deviceId: self.cachedDeviceId
                )
                let newer = OtaFirmwareApi.isNewerThan(info, currentFirmwareRaw: self.cachedFw)
                DispatchQueue.main.async {
                    self.setBusy(false)
                    if newer, !info.firmwares.isEmpty {
                        self.upgradeInfo = info
                        let ver = info.version ?? "-"
                        let build = info.build.map(String.init) ?? "-"
                        self.newVersionLabel.text = L10n.tr("ota_new_version_arrow", "\(ver)(\(build))")
                        self.infoLabel.text = info.updateContent ?? ""
                        self.statusLabel.text = L10n.tr("ota_has_update")
                        self.append(L10n.tr("ota_log_channel_sifli"))
                        self.append(L10n.tr("ota_log_new_pkg", ver, build, info.firmwares.count))
                    } else {
                        self.upgradeInfo = nil
                        self.newVersionLabel.text = ""
                        self.infoLabel.text = ""
                        self.statusLabel.text = L10n.tr("ota_no_update")
                        self.append(L10n.tr("ota_no_update"))
                    }
                    self.updateStartEnabled()
                }
            } catch {
                DispatchQueue.main.async {
                    self.setBusy(false)
                    self.upgradeInfo = nil
                    self.updateStartEnabled()
                    self.statusLabel.text = L10n.tr("feature_failed")
                    self.append(error.localizedDescription)
                }
            }
        }
    }

    /// Step 3: battery / upgrade-status gates, then download + Sifli NAND DFU.
    @objc private func startUpgrade() {
        guard !busy else { return }
        guard let info = upgradeInfo, !info.firmwares.isEmpty else {
            append(L10n.tr("ota_err_no_package"))
            return
        }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        setBusy(true)
        progress.progress = 0
        phaseLabel.text = L10n.tr("ota_phase_prepare")
        statusLabel.text = L10n.tr("ota_preparing")

        repo.getBattery { [weak self] batResult in
            guard let self = self else { return }
            let battery: Int?
            switch batResult {
            case .success(let v): battery = v
            case .failure: battery = nil // soft: continue if query fails
            }
            if let battery = battery, battery < 30 {
                self.setBusy(false)
                self.statusLabel.text = L10n.tr("ota_battery_low", battery)
                self.append(L10n.tr("ota_battery_low", battery))
                return
            }
            self.repo.getDeviceUpgradeStatus { statusResult in
                switch statusResult {
                case .success(let state) where state != HwDeviceUpgradeState.none:
                    self.setBusy(false)
                    self.statusLabel.text = L10n.tr("ota_status_not_ready", "\(state.rawValue)")
                    self.append(L10n.tr("ota_status_not_ready", "\(state.rawValue)"))
                case .failure(let e):
                    // Soft: some firmwares lack the status API — continue.
                    self.append(e.localizedDescription)
                    self.runOta(info)
                case .success:
                    self.runOta(info)
                }
            }
        }
    }

    private func runOta(_ info: OtaUpgradeInfo) {
        append(L10n.tr("ota_log_channel_sifli"))
        repo.startSifliOta(info: info, onProgress: { [weak self] p, phase in
            self?.progress.progress = Float(p) / 100.0
            self?.phaseLabel.text = phase
            self?.statusLabel.text = L10n.tr("ota_progress", p)
        }, onLog: { [weak self] msg in
            self?.append(msg)
        }, completion: { [weak self] result in
            guard let self = self else { return }
            self.setBusy(false)
            // Re-enable reconnect if still bound locally.
            if self.repo.loadBoundDevice() != nil {
                self.repo.setAutoReconnectEnabled(true)
            }
            switch result {
            case .success:
                self.progress.progress = 1
                self.phaseLabel.text = L10n.tr("ota_phase_done")
                self.statusLabel.text = L10n.tr("ota_success")
                self.append(L10n.tr("ota_success"))
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.refreshDeviceInfo()
                }
            case .failure(let e):
                self.statusLabel.text = L10n.tr("ota_failed")
                self.append(e.localizedDescription)
            }
        })
    }

    @objc private func cancelUpgrade() {
        repo.cancelTransfer()
        setBusy(false)
        statusLabel.text = L10n.tr("ota_cancelled")
        append(L10n.tr("ota_cancelled"))
    }

    private func append(_ s: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logView.text = (logView.text ?? "") + "\(ts)  \(s)\n"
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
