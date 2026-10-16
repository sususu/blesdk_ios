import UIKit

/// Home hub with grouped device controls and feature demos.
final class HomeViewController: UIViewController {
    private var recognitionCallback: HwWorkoutTypeRecognitionCallback?
    private let repo = BleRepository.shared

    private var phase: DevicePhase = .idle
    private var device: BleDeviceItem?
    private var bound = false
    private var busy = false
    var isPerformingOperation: Bool { busy }
    private var logs: [String] = []
    private var syncSummary = ""
    private var manualDisconnect = false

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let statusLabel = UIHelpers.makeLabel("", style: .headline)
    private let statusSpinner = UIActivityIndicatorView(style: .medium)
    private let deviceLabel = UIHelpers.makeLabel("", style: .subheadline)
    private let syncLabel = UIHelpers.makeLabel("", style: .footnote)
    private let logToggle = UIHelpers.makeButton("")
    private let logView = UITextView()
    private var actionButtons: [String: UIButton] = [:]
    private var sectionLabels: [String: UILabel] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        applyLocalizedChrome()
        bootstrap()
        NotificationCenter.default.addObserver(self, selector: #selector(reminderUpdated(_:)), name: .jieliRemindersChanged, object: JieliReminderNotifyManager.shared)
        let recognition: HwWorkoutTypeRecognitionCallback = { [weak self] category in
            DispatchQueue.main.async { self?.showWorkoutRecognition(Int(category)) }
        }
        recognitionCallback = recognition
        HwBluetoothSDK.sharedInstance().addWorkoutTypeRecognitionCallback(recognition)
        repo.addConnectionHandler { [weak self] event in
            self?.handleConnection(event)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let recognitionCallback {
            HwBluetoothSDK.sharedInstance().removeWorkoutTypeRecognitionCallback(recognitionCallback)
        }
    }

    private func showWorkoutRecognition(_ category: Int) {
        let settings = JieliAlarmRepository.shared
        guard settings.canPromptWorkout, repo.isConnected(), !busy,
              UIApplication.shared.applicationState == .active,
              let key = JieliAlarmRepository.workoutTitleKey(category),
              let top = navigationController?.topViewController,
              (top === self || top is JieliAlarmReminderViewController),
              top.presentedViewController == nil, top.viewIfLoaded?.window != nil else { return }
        appendLog(L10n.tr(key))
        let alert = UIAlertController(title: L10n.tr("jieli_auto_workout"), message: L10n.tr(key), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("jieli_detect_ignore"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("jieli_detect_not_today"), style: .default) { _ in
            settings.muteWorkoutToday()
        })
        alert.addAction(UIAlertAction(title: L10n.tr("jieli_detect_disable"), style: .destructive) { _ in
            settings.autoDetectWorkouts = false
        })
        top.present(alert, animated: true)
    }

    private func setupUI() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        logToggle.addTarget(self, action: #selector(tapLogs), for: .touchUpInside)
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.isSelectable = true
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = 8
        logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        logView.textColor = .label
        logView.isHidden = true

        let logPanel = UIStackView(arrangedSubviews: [logToggle, logView])
        logPanel.axis = .vertical
        logPanel.spacing = 6
        logPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logPanel)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: logPanel.topAnchor, constant: -8),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
            logPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            logPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        // A hidden arranged view must be able to collapse to zero height.
        let logHeight = logView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.22)
        logHeight.priority = .defaultHigh
        logHeight.isActive = true

        let connection = makeSection("home_connection")
        connection.addArrangedSubview(makeStatusRow())
        deviceLabel.textColor = .secondaryLabel
        connection.addArrangedSubview(deviceLabel)
        connection.addArrangedSubview(UIHelpers.makeGrid([
            makeAction("scan_connect", action: #selector(tapScan), primary: true),
            makeAction("bind_watch", action: #selector(tapBind)),
            makeAction("disconnect", action: #selector(tapDisconnect)),
            makeAction("unbind_watch", action: #selector(tapUnbind))
        ]))
        actionButtons["unbind_watch"]?.setTitleColor(.systemRed, for: .normal)

        let health = makeSection("home_health")
        health.addArrangedSubview(UIHelpers.makeGrid([
            makeAction("sync_data", action: #selector(tapSync)),
            makeAction("jieli_sync_data", action: #selector(tapJieliSync)),
            makeAction("jieli_manual_measure", action: #selector(tapJieliMeasure)),
            makeAction("jieli_auto_monitor", action: #selector(tapJieliAutoMonitor)),
            makeAction("goals", action: #selector(tapGoals))
        ]))
        syncLabel.textColor = .systemBlue
        health.addArrangedSubview(syncLabel)

        let daily = makeSection("home_daily")
        daily.addArrangedSubview(UIHelpers.makeGrid([
            makeAction("alarms", action: #selector(tapAlarms)),
            makeAction("jieli_alarms", action: #selector(tapJieliAlarms)),
            makeAction("jieli_reminder_notify", action: #selector(tapReminderNotify)),
            makeAction("notify", action: #selector(tapNotify))
        ]))

        let media = makeSection("home_media")
        media.addArrangedSubview(UIHelpers.makeGrid([
            makeAction("watchface", action: #selector(tapWatchface)),
            makeAction("watchface_jieli", action: #selector(tapJieliWatchface)),
            makeAction("music", action: #selector(tapMusic)),
            makeAction("album", action: #selector(tapAlbum)),
            makeAction("ai_section", action: #selector(tapAi))
        ]))

        let maintenance = makeSection("home_maintenance")
        maintenance.addArrangedSubview(UIHelpers.makeGrid([
            makeAction("agps", action: #selector(tapAgps)),
            makeAction("ota", action: #selector(tapOta)),
            makeAction("jieli_ota", action: #selector(tapJieliOta))
        ]))
    }

    private func makeSection(_ titleKey: String) -> UIStackView {
        let heading = UIHelpers.makeLabel("", style: .headline)
        heading.adjustsFontForContentSizeCategory = true
        heading.accessibilityTraits.insert(.header)
        sectionLabels[titleKey] = heading

        let section = UIHelpers.makeCard([heading])
        content.addArrangedSubview(section)
        return section
    }

    private func makeAction(_ key: String, action: Selector, primary: Bool = false) -> UIButton {
        let button = UIHelpers.makeButton("", primary: primary)
        button.accessibilityIdentifier = key
        button.addTarget(self, action: action, for: .touchUpInside)
        actionButtons[key] = button
        return button
    }

    @objc private func tapLogs() {
        logView.isHidden.toggle()
        updateLogToggle()
    }

    private func updateLogToggle() {
        logToggle.setTitle(L10n.tr(logView.isHidden ? "home_show_logs" : "home_hide_logs"), for: .normal)
        logToggle.setImage(UIImage(systemName: logView.isHidden ? "chevron.up" : "chevron.down"), for: .normal)
    }

    private func makeStatusRow() -> UIView {
        let row = UIStackView(arrangedSubviews: [statusSpinner, statusLabel])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        statusSpinner.hidesWhenStopped = true
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return row
    }

    private func applyLocalizedChrome() {
        title = L10n.tr("app_name")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "v\(repo.version())", style: .plain, target: nil, action: nil
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.tr("language"), style: .plain, target: self, action: #selector(tapLanguage)
        )

        for (key, button) in actionButtons {
            button.setTitle(L10n.tr(key), for: .normal)
        }
        for (key, label) in sectionLabels {
            label.text = L10n.tr(key)
        }
        updateLogToggle()
        refreshUI()
        renderLogs()
    }

    @objc private func tapLanguage() {
        let sheet = UIAlertController(title: L10n.tr("language"), message: nil, preferredStyle: .actionSheet)
        for lang in AppLanguage.allCases {
            let mark = (lang == LocaleHelper.current) ? " ✓" : ""
            sheet.addAction(UIAlertAction(title: lang.displayName + mark, style: .default) { [weak self] _ in
                LocaleHelper.current = lang
                self?.applyLocalizedChrome()
                NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("ok"), style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(sheet, animated: true)
    }

    private func bootstrap() {
        if let saved = repo.loadBoundDevice() {
            bound = true
            phase = .bound
            device = BleDeviceItem(name: saved.name, macAddress: saved.macAddress)
            repo.setAutoReconnectEnabled(true)
            statusLabel.text = L10n.tr("status_bound_local")
            appendLog(L10n.tr("log_load_bound", saved.macAddress))
            // 对齐 BleConnectManager：已绑定则立即 startConnectBluetooth
            repo.startConnectBluetooth(reasonKey: "reason_boot")
        } else {
            statusLabel.text = L10n.tr("status_sdk_ready")
            appendLog(L10n.tr("log_init_ok", repo.version()))
        }
        refreshUI()
    }

    private func handleConnection(_ event: ConnectionEvent) {
        switch event {
        case .connected(let name, let mac):
            manualDisconnect = false
            if let mac = mac, !mac.isEmpty {
                device = BleDeviceItem(name: name, macAddress: mac)
            }
            phase = bound ? .bound : .connected
            statusLabel.text = L10n.tr("status_connected", name ?? mac ?? "")
            appendLog(L10n.tr("log_conn_connected"))
        case .disconnected:
            if phase == .unbinding { return }
            statusLabel.text = bound
                ? (manualDisconnect ? L10n.tr("status_manual_disconnect") : L10n.tr("status_bound_disconnected"))
                : L10n.tr("status_disconnected")
            if !bound { phase = .idle }
            appendLog(L10n.tr("log_conn_disconnected"))
            // 自动重连由 BleRepository（对齐 BleConnectManager）处理
        case .reconnecting(let attempt, let reason):
            statusLabel.text = L10n.tr("status_reconnecting", reason)
            appendLog(L10n.tr("log_reconnect_start", reason, attempt))
        case .reconnectFailed(let attempt, let message):
            appendLog(L10n.tr("log_reconnect_failed", attempt, message))
            if bound && !manualDisconnect {
                statusLabel.text = L10n.tr("status_bound_disconnected")
            }
        }
        refreshUI()
    }

    private func refreshUI() {
        if let d = device {
            let state = bound ? L10n.tr("bound") : L10n.tr("connected")
            deviceLabel.text = "\(d.name ?? L10n.tr("unknown_device"))\n\(d.macAddress)\n\(state)"
        } else {
            deviceLabel.text = L10n.tr("no_device")
        }
        syncLabel.text = syncSummary
        syncLabel.isHidden = syncSummary.isEmpty

        let hasDevice = device != nil
        // 对齐 Android：同步在已绑定或已连接相位即可点（断线时会先重连）
        let canBind = !busy && hasDevice && !bound && repo.isConnected()
        let canSync = !busy && (bound || phase == .connected || hasDevice)
        let canUnbind = !busy && bound
        let canFeature = !busy && hasDevice && (bound || phase == .connected)

        for (key, button) in actionButtons {
            switch key {
            case "scan_connect", "jieli_reminder_notify": button.isEnabled = !busy
            case "bind_watch": button.isEnabled = canBind
            case "sync_data", "jieli_sync_data": button.isEnabled = canSync
            case "unbind_watch": button.isEnabled = canUnbind
            case "disconnect": button.isEnabled = !busy && hasDevice
            default: button.isEnabled = canFeature
            }
        }

        if busy { statusSpinner.startAnimating() } else { statusSpinner.stopAnimating() }
    }

    private func appendLog(_ msg: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.insert("\(ts)  \(msg)", at: 0)
        if logs.count > 200 { logs.removeLast(logs.count - 200) }
        renderLogs()
    }

    private func renderLogs() {
        logView.text = logs.joined(separator: "\n")
        // 保持顶部最新一条可见
        logView.setContentOffset(.zero, animated: false)
    }

    private func requireConnectedFeature() -> Bool {
        guard repo.isConnected() else {
            appendLog(L10n.tr("status_need_connect"))
            statusLabel.text = L10n.tr("status_need_connect")
            return false
        }
        return true
    }

    // MARK: - Actions (bind / sync / unbind)

    @objc private func tapScan() {
        let vc = ScanConnectViewController()
        vc.onConnected = { [weak self] item in
            self?.device = item
            self?.phase = self?.bound == true ? .bound : .connected
            self?.statusLabel.text = L10n.tr("status_connected", item.name ?? item.macAddress)
            self?.appendLog(L10n.tr("log_connect_success", item.macAddress))
            self?.refreshUI()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Presents `BindFlowViewController`. On success:
    /// - marks local `bound`, enables auto-reconnect, and persists `BoundDeviceStore`
    ///   (Android `setBind` equivalent — iOS has no system bind flag beyond pairing).
    @objc private func tapBind() {
        guard repo.isConnected() else { return }
        let vc = BindFlowViewController()
        vc.onFinished = { [weak self] success, info in
            guard let self = self, success else { return }
            self.bound = true
            self.phase = .bound
            self.manualDisconnect = false
            self.repo.setAutoReconnectEnabled(true)
            if let d = self.device {
                self.repo.saveBoundDevice(mac: d.macAddress, name: d.name, info: info)
                self.appendLog(L10n.tr("log_bound_saved", d.macAddress))
            }
            self.statusLabel.text = L10n.tr("status_bind_success")
            self.refreshUI()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    /// Health data sync entry. If BLE is down but a bound MAC exists, reconnects first
    /// then runs `BleRepository.syncHealthData` (count → fetch → delete on device).
    @objc private func tapSync() {
        guard !busy else { return }
        guard bound || phase == .connected || device != nil else {
            statusLabel.text = L10n.tr("error_no_device_to_sync")
            appendLog(L10n.tr("error_no_device_to_sync"))
            return
        }
        busy = true
        phase = .syncing
        syncSummary = ""
        statusLabel.text = L10n.tr("status_syncing")
        appendLog(L10n.tr("log_sync_start"))
        refreshUI()

        let runSync: () -> Void = { [weak self] in
            self?.repo.syncHealthData { result in
                guard let self = self else { return }
                self.busy = false
                self.phase = self.bound ? .bound : .connected
                switch result {
                case .success(let summary):
                    self.syncSummary = summary
                    self.statusLabel.text = L10n.tr("status_sync_done")
                    self.appendLog(L10n.tr("log_sync_done", summary.replacingOccurrences(of: "\n", with: " / ")))
                case .failure(let e):
                    self.statusLabel.text = L10n.tr("status_sync_failed", e.localizedDescription)
                    self.appendLog(L10n.tr("log_sync_failed", e.localizedDescription))
                }
                self.refreshUI()
            }
        }

        if repo.isConnected() {
            runSync()
        } else if let mac = device?.macAddress ?? repo.loadBoundDevice()?.macAddress, !mac.isEmpty {
            // Align Android: allow “sync” to reconnect then pull when bound but offline.
            repo.connect(mac: mac) { [weak self] result in
                switch result {
                case .success:
                    runSync()
                case .failure(let e):
                    self?.busy = false
                    self?.phase = self?.bound == true ? .bound : .idle
                    self?.statusLabel.text = L10n.tr("status_sync_failed", e.localizedDescription)
                    self?.appendLog(L10n.tr("log_sync_failed", e.localizedDescription))
                    self?.refreshUI()
                }
            }
        } else {
            busy = false
            phase = bound ? .bound : .idle
            statusLabel.text = L10n.tr("error_no_device_to_sync")
            appendLog(L10n.tr("error_no_device_to_sync"))
            refreshUI()
        }
    }

    @objc private func tapJieliAutoMonitor() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(JieliAutoMonitorViewController(), animated: true)
    }

    @objc private func tapJieliMeasure() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(JieliManualMeasureViewController(), animated: true)
    }

    @objc private func tapJieliSync() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(JieliHealthSyncViewController(), animated: true)
    }

    /// Presents `UnbindFlowViewController`. Disables auto-reconnect first.
    /// On success, clears home bind state. The flow itself prompts the user to
    /// **Forget This Device** in system Bluetooth settings (iOS cannot `removeBond`).
    @objc private func tapUnbind() {
        repo.setAutoReconnectEnabled(false)
        phase = .unbinding
        let vc = UnbindFlowViewController()
        vc.onFinished = { [weak self] success in
            guard let self = self, success else {
                // User cancelled mid-flow — restore reconnect if still considered bound.
                self?.phase = self?.bound == true ? .bound : .connected
                if self?.bound == true {
                    self?.repo.setAutoReconnectEnabled(true)
                }
                return
            }
            self.bound = false
            self.phase = .idle
            self.device = nil
            self.syncSummary = ""
            self.manualDisconnect = false
            self.statusLabel.text = L10n.tr("status_unbound")
            self.appendLog(L10n.tr("log_unbind_done"))
            self.refreshUI()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    @objc private func tapDisconnect() {
        busy = true
        manualDisconnect = true
        repo.setAutoReconnectEnabled(false)
        refreshUI()
        repo.disconnect { [weak self] _ in
            self?.busy = false
            self?.statusLabel.text = self?.bound == true
                ? L10n.tr("status_manual_disconnect")
                : L10n.tr("status_disconnected")
            self?.appendLog(L10n.tr("log_manual_disconnect"))
            self?.refreshUI()
        }
    }

    @objc private func tapGoals() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(GoalsViewController(), animated: true)
    }
    @objc private func tapAlarms() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(AlarmsViewController(), animated: true)
    }
    @objc private func tapReminderNotify() {
        navigationController?.pushViewController(JieliReminderNotifyViewController(), animated: true)
    }

    @objc private func reminderUpdated(_ note: Notification) {
        if let text = note.userInfo?["log"] as? String { appendLog(text) }
        if let count = note.userInfo?["goalCount"] as? Int, !busy {
            syncSummary = L10n.tr("jl_notify_goal_synced", count)
            refreshUI()
        }
    }

    @objc private func tapJieliAlarms() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(JieliAlarmReminderViewController(), animated: true)
    }
    @objc private func tapNotify() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(NotifyViewController(), animated: true)
    }
    @objc private func tapMusic() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(MusicTransferViewController(), animated: true)
    }
    @objc private func tapAlbum() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(AlbumTransferViewController(), animated: true)
    }
    @objc private func tapAgps() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(AgpsUpdateViewController(), animated: true)
    }
    @objc private func tapOta() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(OtaUpgradeViewController(), animated: true)
    }
    @objc private func tapJieliOta() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(JieliOtaUpgradeViewController(), animated: true)
    }
    @objc private func tapWatchface() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(WatchfaceHostViewController(), animated: true)
    }
    @objc private func tapJieliWatchface() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(JieliWatchfaceHostViewController(), animated: true)
    }

    /// Usage guide first, then AI DEMO (iOS AiSDK / Example HwMainVC).
    @objc private func tapAi() {
        guard requireConnectedFeature() else { return }
        navigationController?.pushViewController(AiHostViewController(), animated: true)
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}
