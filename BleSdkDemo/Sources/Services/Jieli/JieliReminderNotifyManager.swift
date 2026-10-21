import UIKit
import UserNotifications

/// Demo counterpart of HaWoFit ReminderNotifyManager. Device selection is left to the customer.
final class JieliReminderNotifyManager: NSObject {
    static let shared = JieliReminderNotifyManager()
    private let repo = BleRepository.shared
    private let notifications = UNUserNotificationCenter.current()
    private var callback: HwReminderNotifyCallback?
    private var session: UUID?
    private var ownerMAC: String?
    private var ownerUUID: String?
    private var installed = false
    private(set) var history = JieliReminderHistory()
    private(set) var status = L10n.tr("jl_notify_stopped")
    private(set) var goalSummary = ""
    private(set) var notificationStatus = ""
    private var alerts: [JieliReminderEvent] = []
    private var alert: UIAlertController?
    private var alertEvent: JieliReminderEvent?
    private var alertRetry: DispatchWorkItem?
    private var goalWork: DispatchWorkItem?
    private var goalTimeout: DispatchWorkItem?
    private var goalRequest: UUID?
    private var pendingGoal = false
    private var goalWaitStarted: TimeInterval = 0

    var isListening: Bool { callback != nil }

    func install() {
        guard !installed else { return }
        installed = true
        NotificationCenter.default.addObserver(self, selector: #selector(becameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        repo.addConnectionHandler { [weak self] _ in
            guard let self else { return }
            self.syncWithBindState()
            if !self.repo.isConnected() { self.clearGoalSync() }
            self.changed()
        }
    }

    func start() {
        guard !isListening else { return }
        guard let bound = repo.loadBoundDevice(), !bound.macAddress.isEmpty,
              repo.isConnected(), let uuid = repo.connectedUUID(),
              repo.connectedMac()?.caseInsensitiveCompare(bound.macAddress) == .orderedSame else {
            status = L10n.tr("jl_notify_need_bound")
            changed(log: status)
            return
        }
        install()
        history.clear()
        goalSummary = ""
        ownerMAC = bound.macAddress
        ownerUUID = uuid
        let token = UUID()
        session = token
        let handler: HwReminderNotifyCallback = { [weak self] type, data in
            DispatchQueue.main.async { self?.receive(type, data: data, token: token) }
        }
        callback = handler
        HwBluetoothSDK.sharedInstance().addReminderNotifyCallback(handler)
        status = L10n.tr("jl_notify_listening")
        changed(log: status)
        requestNotificationPermission()
    }

    func stop() {
        if let callback { HwBluetoothSDK.sharedInstance().removeReminderNotifyCallback(callback) }
        callback = nil
        let identifiers = notificationIdentifiers()
        session = nil
        ownerMAC = nil
        ownerUUID = nil
        clearGoalSync()
        alertRetry?.cancel()
        alertRetry = nil
        alerts.removeAll()
        alert?.dismiss(animated: false)
        alert = nil
        alertEvent = nil
        notifications.removePendingNotificationRequests(withIdentifiers: identifiers)
        notifications.removeDeliveredNotifications(withIdentifiers: identifiers)
        status = L10n.tr("jl_notify_stopped")
        changed()
    }

    func syncWithBindState() {
        guard isListening else { return }
        guard let bound = repo.loadBoundDevice(), bound.macAddress == ownerMAC else {
            stop()
            clearHistory()
            return
        }
        if repo.isConnected(), !matchesOwner() {
            stop()
            clearHistory()
        }
    }

    func clearHistory() {
        history.clear()
        goalSummary = ""
        changed()
    }

    func refreshNotificationStatus() {
        notifications.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationStatus = L10n.tr(Self.permissionKey(settings.authorizationStatus))
                self?.changed()
            }
        }
    }

    func requestNotificationPermission() {
        notifications.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .notDetermined else { self.refreshNotificationStatus(); return }
            self.notifications.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                DispatchQueue.main.async {
                    if let error { self.status = error.localizedDescription }
                    self.refreshNotificationStatus()
                }
            }
        }
    }

    private static func permissionKey(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "jl_notify_permission_on"
        case .denied: return "jl_notify_permission_off"
        default: return "jl_notify_permission_unknown"
        }
    }

    private func matchesOwner() -> Bool {
        guard let ownerMAC, let bound = repo.loadBoundDevice(), bound.macAddress == ownerMAC,
              repo.isConnected(), repo.connectedUUID() == ownerUUID else { return false }
        return repo.connectedMac()?.caseInsensitiveCompare(ownerMAC) == .orderedSame
    }

    private func isCurrent(_ token: UUID) -> Bool { session == token && matchesOwner() }

    private func receive(_ type: HwReminderNotifyType, data: Data?, token: UUID) {
        guard isCurrent(token), let event = JieliReminderEvent(type: type, data: data), history.append(event) else { return }
        status = L10n.tr("jl_notify_listening")
        changed(log: event.message)
        if event.isDailyGoal { requestGoalSync() }
        if UIApplication.shared.applicationState == .background {
            postNotification(event, token: token)
        } else {
            enqueueAlert(event)
        }
    }

    private func enqueueAlert(_ event: JieliReminderEvent) {
        alerts.append(event)
        // ponytail: show at most 20 queued alerts; full recent history (200 events) remains on the page.
        if alerts.count > 20 { alerts.removeFirst(alerts.count - 20) }
        showNextAlert()
    }

    @objc private func becameActive() {
        syncWithBindState()
        refreshNotificationStatus()
        showNextAlert()
    }

    @objc private func enteredBackground() {
        alertRetry?.cancel()
        alertRetry = nil
        if let alertEvent { alerts.insert(alertEvent, at: 0) }
        alert?.dismiss(animated: false)
        alert = nil
        alertEvent = nil
        if let token = session { alerts.forEach { postNotification($0, token: token) } }
        alerts.removeAll()
    }

    private func showNextAlert() {
        guard let token = session, isCurrent(token), alert == nil, !alerts.isEmpty,
              UIApplication.shared.applicationState == .active else { return }
        guard let top = topViewController(), !(top is UIAlertController),
              !top.isBeingDismissed, !top.isBeingPresented, top.viewIfLoaded?.window != nil else {
            alertRetry?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.showNextAlert() }
            alertRetry = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
            return
        }
        let event = alerts.removeFirst()
        let popup = UIAlertController(title: L10n.tr("jieli_reminder_notify"), message: event.message, preferredStyle: .alert)
        popup.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.session == token else { return }
                self.alert = nil
                self.alertEvent = nil
                self.showNextAlert()
            }
        })
        alert = popup
        alertEvent = event
        top.present(popup, animated: true)
    }

    private func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }.first { $0.isKeyWindow }
        var top = window?.rootViewController
        while let current = top {
            if let presented = current.presentedViewController { top = presented }
            else if let nav = current as? UINavigationController { top = nav.visibleViewController }
            else if let tabs = current as? UITabBarController { top = tabs.selectedViewController }
            else { break }
        }
        return top
    }

    private func notificationIdentifier(_ type: HwReminderNotifyType, token: UUID) -> String {
        "blesdkdemo.jieli.reminder.\(token.uuidString).\(type.rawValue)"
    }

    private func notificationIdentifiers() -> [String] {
        guard let session else { return [] }
        return JieliReminderEvent.messageKeys.keys.map { notificationIdentifier($0, token: session) }
    }

    private func postNotification(_ event: JieliReminderEvent, token: UUID) {
        let identifier = notificationIdentifier(event.type, token: token)
        notifications.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self, self.isCurrent(token) else { return }
                // Permission lookup may finish after the app has returned to the foreground.
                if UIApplication.shared.applicationState == .active {
                    self.enqueueAlert(event)
                    return
                }
                guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
                let content = UNMutableNotificationContent()
                content.title = L10n.tr("app_name")
                content.body = event.message
                content.sound = .default
                self.notifications.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil)) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if !self.isCurrent(token) {
                            self.notifications.removeDeliveredNotifications(withIdentifiers: [identifier])
                            self.notifications.removePendingNotificationRequests(withIdentifiers: [identifier])
                        } else if let error {
                            self.status = error.localizedDescription
                            self.changed(log: self.status)
                        }
                    }
                }
            }
        }
    }

    private func requestGoalSync() {
        if !pendingGoal { goalWaitStarted = ProcessInfo.processInfo.systemUptime }
        pendingGoal = true
        scheduleGoalSync(after: 0.5)
    }

    private func scheduleGoalSync(after delay: TimeInterval) {
        goalWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.runGoalSync() }
        goalWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func runGoalSync() {
        guard pendingGoal, goalRequest == nil, let token = session, isCurrent(token) else { return }
        guard ProcessInfo.processInfo.systemUptime - goalWaitStarted <= 180 else {
            pendingGoal = false
            goalSummary = L10n.tr("jl_notify_goal_timeout")
            changed(log: goalSummary)
            return
        }
        // Wait while other feature pages, a home operation, or a file transfer owns the device.
        let top = topViewController()
        let homeReady = (top as? HomeViewController).map { !$0.isPerformingOperation } ?? false
        if repo.isTransferring || UIApplication.shared.applicationState != .active
            || !(homeReady || top is JieliReminderNotifyViewController) {
            scheduleGoalSync(after: 1)
            return
        }
        pendingGoal = false
        let request = UUID()
        goalRequest = request
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.goalRequest == request else { return }
            self.goalRequest = nil
            self.goalSummary = L10n.tr("jl_notify_goal_timeout")
            self.changed(log: self.goalSummary)
            if self.pendingGoal { self.scheduleGoalSync(after: 1) }
        }
        goalTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeout)
        // Read-only: the generic syncHealthData demo deletes device records after reading.
        JieliHealthRepository.shared.getSportDetail { [weak self] result in
            guard let self, self.goalRequest == request, self.isCurrent(token) else { return }
            self.goalTimeout?.cancel()
            self.goalTimeout = nil
            self.goalRequest = nil
            switch result {
            case .success(let data):
                self.goalSummary = L10n.tr("jl_notify_goal_synced", data.count)
                self.changed(log: self.goalSummary, goalCount: data.count)
            case .failure(let error):
                self.goalSummary = error.localizedDescription
                self.changed(log: self.goalSummary)
            }
            if self.pendingGoal { self.scheduleGoalSync(after: 1) }
        }
    }

    private func clearGoalSync() {
        pendingGoal = false
        goalRequest = nil
        goalWork?.cancel()
        goalTimeout?.cancel()
        goalWork = nil
        goalTimeout = nil
    }

    private func changed(log: String? = nil, goalCount: Int? = nil) {
        var info: [String: Any] = [:]
        info["log"] = log
        info["goalCount"] = goalCount
        NotificationCenter.default.post(name: .jieliRemindersChanged, object: self, userInfo: info)
    }
}

extension Notification.Name {
    static let jieliRemindersChanged = Notification.Name("jieliRemindersChanged")
}
