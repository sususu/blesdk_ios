import UIKit

class FeatureBaseViewController: UIViewController {
    let repo = BleRepository.shared
    let statusLabel = UIHelpers.makeLabel("", style: .headline)
    let resultLabel = UIHelpers.makeLabel("", style: .footnote)
    let actionsStack = UIStackView()
    private var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        statusLabel.text = L10n.tr("feature_ready")
        let content = UIStackView(arrangedSubviews: [
            UIHelpers.makeCard([statusLabel], title: L10n.tr("ui_status")),
            UIHelpers.makeCard([actionsStack], title: L10n.tr("ui_actions")),
            UIHelpers.makeCard([resultLabel], title: L10n.tr("ui_results"))
        ])
        actionsStack.axis = .vertical
        actionsStack.spacing = 8
        resultLabel.textColor = .secondaryLabel
        UIHelpers.installScrollableContent(content, in: view)
        buildActions()
        let buttons = actionsStack.arrangedSubviews.compactMap { $0 as? UIButton }
        for button in buttons {
            actionsStack.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        actionsStack.addArrangedSubview(UIHelpers.makeGrid(buttons))
    }

    func buildActions() {}

    private var actionHandlers: [UIButton: () -> Void] = [:]

    func addAction(_ title: String, destructive: Bool = false, handler: @escaping () -> Void) {
        let b = UIHelpers.makeButton(title)
        if destructive { b.setTitleColor(.systemRed, for: .normal) }
        actionHandlers[b] = handler
        b.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
        actionsStack.addArrangedSubview(b)
    }

    @objc private func actionTapped(_ sender: UIButton) {
        actionHandlers[sender]?()
    }

    func run(_ status: String, _ work: (@escaping (Result<String, Error>) -> Void) -> Void) {
        guard !busy else { return }
        busy = true
        statusLabel.text = status
        setActionsEnabled(false)
        work { [weak self] result in
            guard let self = self else { return }
            self.busy = false
            self.setActionsEnabled(true)
            switch result {
            case .success(let text):
                self.statusLabel.text = L10n.tr("feature_success")
                self.resultLabel.text = text
            case .failure(let e):
                self.statusLabel.text = L10n.tr("feature_failed")
                self.resultLabel.text = e.localizedDescription
            }
        }
    }

    private func setActionsEnabled(_ enabled: Bool) {
        actionHandlers.keys.forEach { $0.isEnabled = enabled }
    }
}

final class GoalsViewController: FeatureBaseViewController {
    override func viewDidLoad() {
        title = L10n.tr("goals")
        super.viewDidLoad()
    }

    override func buildActions() {
        addAction(L10n.tr("goals_get")) {
            self.run(L10n.tr("goals_getting")) { done in
                self.repo.getGoals { result in
                    done(result.map { self.formatGoal($0) })
                }
            }
        }
        addAction(L10n.tr("goals_set_demo")) {
            self.run(L10n.tr("goals_setting")) { done in
                self.repo.setDemoGoals { result in
                    switch result {
                    case .failure(let e): done(.failure(e))
                    case .success:
                        self.repo.getGoals { gResult in
                            done(gResult.map { L10n.tr("goals_set_ok") + "\n" + self.formatGoal($0) })
                        }
                    }
                }
            }
        }
    }

    /// 对齐 Android：展示单位（中英文走 L10n）
    private func formatGoal(_ goal: HwGoal) -> String {
        let stepProtocol = Int(goal.step)
        let otKm = Double(intValue(goal, keys: ["OTDistance", "otDistance"])) / 10.0
        let otMile = Double(intValue(goal, keys: ["OTDistanceMile", "otDistanceMile"])) / 10.0
        return [
            L10n.tr("goals_step", stepProtocol * 100, stepProtocol),
            L10n.tr("goals_calorie", Int(goal.calorie)),
            L10n.tr("goals_distance", Int(goal.distance)),
            L10n.tr("goals_sleep", Int(goal.sleep)),
            L10n.tr("goals_duration", Int(goal.duration)),
            L10n.tr("goals_ot_km", otKm),
            L10n.tr("goals_ot_mile", otMile)
        ].joined(separator: "\n")
    }

    private func intValue(_ object: NSObject, keys: [String]) -> Int {
        for key in keys {
            guard object.responds(to: NSSelectorFromString(key)) else { continue }
            if let n = object.value(forKey: key) as? NSNumber {
                return n.intValue
            }
        }
        return 0
    }
}

final class AlarmsViewController: FeatureBaseViewController {
    override func viewDidLoad() {
        title = L10n.tr("alarms")
        super.viewDidLoad()
    }

    override func buildActions() {
        addAction(L10n.tr("alarms_get")) {
            self.run(L10n.tr("alarms_getting")) { done in
                self.repo.getAlarms { result in
                    done(result.map { list in
                        if list.isEmpty { return L10n.tr("alarms_empty") }
                        return list.map { self.formatAlarm($0) }.joined(separator: "\n")
                    })
                }
            }
        }
        addAction(L10n.tr("alarms_add_demo")) {
            self.run(L10n.tr("alarms_adding")) { done in
                self.repo.addDemoAlarm { result in
                    switch result {
                    case .failure(let e): done(.failure(e))
                    case .success:
                        self.repo.getAlarms { listResult in
                            done(listResult.map { list in
                                let detail = list.isEmpty
                                    ? L10n.tr("alarms_empty")
                                    : list.map { self.formatAlarm($0) }.joined(separator: "\n")
                                return L10n.tr("alarms_add_ok") + "\n" + detail
                            })
                        }
                    }
                }
            }
        }
        addAction(L10n.tr("alarms_delete_all"), destructive: true) {
            self.run(L10n.tr("alarms_deleting")) { done in
                self.repo.deleteAllAlarms { result in
                    done(result.map { L10n.tr("alarms_delete_all_ok") })
                }
            }
        }
        addAction(L10n.tr("reminders_get_sedentary")) {
            self.run(L10n.tr("reminders_getting")) { done in
                self.repo.getSedentary { result in
                    done(result.map { self.formatSedentary($0) })
                }
            }
        }
        addAction(L10n.tr("reminders_set_sedentary")) {
            self.run(L10n.tr("reminders_setting")) { done in
                self.repo.setDemoSedentary { result in
                    switch result {
                    case .failure(let e): done(.failure(e))
                    case .success:
                        self.repo.getSedentary { rResult in
                            done(rResult.map { L10n.tr("reminders_sedentary_ok") + "\n" + self.formatSedentary($0) })
                        }
                    }
                }
            }
        }
        addAction(L10n.tr("reminders_set_drink")) {
            self.run(L10n.tr("reminders_setting")) { done in
                self.repo.setDemoDrinkWater { result in
                    done(result.map { L10n.tr("reminders_drink_ok") })
                }
            }
        }
        addAction(L10n.tr("reminders_set_wash")) {
            self.run(L10n.tr("reminders_setting")) { done in
                self.repo.setDemoWashHand { result in
                    done(result.map { L10n.tr("reminders_wash_ok") })
                }
            }
        }
    }

    /// 对齐 Android `AlarmsViewModel.getAlarms`：时间 / 开关 / 文案 / 重复周（中英文走 L10n）
    private func formatAlarm(_ alarm: HwAlarm) -> String {
        let id = (alarm.value(forKey: "Id") as? NSNumber)?.intValue ?? 0
        let on = (alarm.value(forKey: "S") as? Bool) ?? false
        let time: String = {
            guard let points = alarm.times as? [HwTimePoint], let first = points.first else {
                return "--:--"
            }
            return String(format: "%02d:%02d", first.hour, first.minute)
        }()
        let content = alarm.custom ?? ""
        let weekRaw = (alarm.value(forKey: "week") as? NSNumber)?.intValue ?? Int(alarm.week.rawValue)
        return L10n.tr(
            "alarms_line",
            id,
            time,
            on ? L10n.tr("alarms_on") : L10n.tr("alarms_off"),
            content.isEmpty ? "-" : content,
            formatWeekMask(weekRaw)
        )
    }

    /// 对齐 Android `getSedentary`：开关 / 时段 / 间隔（秒）/ 重复周
    private func formatSedentary(_ r: HwSedentaryReminder) -> String {
        let start = formatTimePoint(r.startTime)
        let end = formatTimePoint(r.endTime)
        let weekRaw = (r.value(forKey: "week") as? NSNumber)?.intValue ?? Int(r.week.rawValue)
        return L10n.tr(
            "reminders_sedentary_detail",
            r.on ? L10n.tr("alarms_on") : L10n.tr("alarms_off"),
            start,
            end,
            Int(r.interval),
            formatWeekMask(weekRaw)
        )
    }

    private func formatTimePoint(_ tp: HwTimePoint?) -> String {
        guard let tp = tp else { return "--:--" }
        return String(format: "%02d:%02d", tp.hour, tp.minute)
    }

    private func formatWeekMask(_ raw: Int) -> String {
        let days: [(Int, String)] = [
            (Int(HwWeek.monday.rawValue), L10n.tr("week_mon")),
            (Int(HwWeek.tuesday.rawValue), L10n.tr("week_tue")),
            (Int(HwWeek.wednesday.rawValue), L10n.tr("week_wed")),
            (Int(HwWeek.thursday.rawValue), L10n.tr("week_thu")),
            (Int(HwWeek.friday.rawValue), L10n.tr("week_fri")),
            (Int(HwWeek.saturday.rawValue), L10n.tr("week_sat")),
            (Int(HwWeek.sunday.rawValue), L10n.tr("week_sun"))
        ]
        let names = days.compactMap { flag, name -> String? in
            (raw & flag) != 0 ? name : nil
        }
        return names.isEmpty ? "-" : names.joined(separator: ",")
    }
}

final class NotifyViewController: FeatureBaseViewController {
    override func viewDidLoad() {
        title = L10n.tr("notify")
        super.viewDidLoad()
    }

    override func buildActions() {
        addAction(L10n.tr("notify_get_switches")) {
            self.run(L10n.tr("notify_getting_switches")) { done in
                self.repo.getSocialSwitches { result in
                    done(result.map { list in
                        if list.isEmpty { return L10n.tr("notify_switches_empty") }
                        // 对齐 Android：type=… on=…；仅展示已开启项，避免 256 路全量刷屏
                        let onList = list.filter { $0.s }
                        if onList.isEmpty { return L10n.tr("notify_switches_empty") }
                        return onList.map { "type=\($0.type.rawValue) on=\($0.s)" }.joined(separator: "\n")
                    })
                }
            }
        }
        addAction(L10n.tr("notify_enable_switches")) {
            self.run(L10n.tr("notify_setting_switches")) { done in
                self.repo.enableDemoSocialSwitches { result in
                    done(result.map { L10n.tr("notify_switches_ok") })
                }
            }
        }
        addAction(L10n.tr("notify_set_contacts")) {
            self.run(L10n.tr("notify_setting_contacts")) { done in
                self.repo.setDemoContacts { result in
                    done(result.map { L10n.tr("notify_contacts_ok") })
                }
            }
        }
        addAction(L10n.tr("notify_set_emergency")) {
            self.run(L10n.tr("notify_setting_emergency")) { done in
                self.repo.setEmergencyContact { result in
                    done(result.map { L10n.tr("notify_emergency_ok") })
                }
            }
        }
    }
}

/// iOS message-notification switches. Matches HaWoFit `NotificationsNewVC`:
/// read the system pair state, request pairing when needed, then show the
/// default apps the device reports and write each toggle with `setSocialSwitch`.
final class NotificationSwitchViewController: UITableViewController {
    private struct AppSpec {
        let type: HwSocialSwitchType
        let nameKey: String
    }

    private struct SwitchItem {
        let type: HwSocialSwitchType
        let nameKey: String
        var on: Bool
    }

    private enum Phase {
        case needConnect
        case reading
        case unpaired
        case pairing
        case paired
        case failed
    }

    /// HaWoFit `socialapps.json` `defaultapps`, in the same order, plus Others.
    private static let catalog: [AppSpec] = [
        AppSpec(type: .calls, nameKey: "notify_app_calls"),
        AppSpec(type: .message, nameKey: "notify_app_sms"),
        AppSpec(type: .missCalls, nameKey: "notify_app_missed"),
        AppSpec(type: .email, nameKey: "notify_app_email"),
        AppSpec(type: .calendar, nameKey: "notify_app_calendar"),
        AppSpec(type: .whatsApp, nameKey: "notify_app_whatsapp"),
        AppSpec(type: .facebook, nameKey: "notify_app_facebook"),
        AppSpec(type: .twitter, nameKey: "notify_app_twitter"),
        AppSpec(type: .youtube, nameKey: "notify_app_youtube"),
        AppSpec(type: .instagram, nameKey: "notify_app_instagram"),
        AppSpec(type: .skype, nameKey: "notify_app_skype"),
        AppSpec(type: .linkedin, nameKey: "notify_app_linkedin"),
        AppSpec(type: .line, nameKey: "notify_app_line"),
        AppSpec(type: .snapchat, nameKey: "notify_app_snapchat"),
        AppSpec(type: .telegram, nameKey: "notify_app_telegram"),
        AppSpec(type: .kakaoTalk, nameKey: "notify_app_kakaotalk"),
        AppSpec(type: .wechat, nameKey: "notify_app_wechat"),
        AppSpec(type: .QQ, nameKey: "notify_app_qq"),
        AppSpec(type: .tikTok, nameKey: "notify_app_tiktok"),
        AppSpec(type: .gmail, nameKey: "notify_app_gmail"),
        AppSpec(type: .messenger, nameKey: "notify_app_messenger"),
        AppSpec(type: .pinterest, nameKey: "notify_app_pinterest"),
        AppSpec(type: .hangout, nameKey: "notify_app_hangout"),
        AppSpec(type: .outlook, nameKey: "notify_app_outlook"),
        AppSpec(type: .truecaller, nameKey: "notify_app_truecaller"),
        AppSpec(type: .tumblr, nameKey: "notify_app_tumblr"),
        AppSpec(type: .flickr, nameKey: "notify_app_flickr"),
        AppSpec(type: .VK, nameKey: "notify_app_vk"),
        AppSpec(type: .viber, nameKey: "notify_app_viber"),
        AppSpec(type: .hangouts, nameKey: "notify_app_hangouts"),
        AppSpec(type: .zalo, nameKey: "notify_app_zalo")
    ]

    private let repo = BleRepository.shared
    private var phase: Phase = .reading
    private var message = ""
    private var items: [SwitchItem] = []
    private var busy = false
    private var request: UUID?
    private var pairCallback: HwDevicePairStateCallback?

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh, target: self, action: #selector(reload)
        )
        let callback: HwDevicePairStateCallback = { [weak self] state in
            DispatchQueue.main.async { self?.handlePairEvent(state) }
        }
        pairCallback = callback
        HwBluetoothSDK.sharedInstance().addDevicePairStateCallback(callback)
        NotificationCenter.default.addObserver(
            self, selector: #selector(becameActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    deinit {
        if let pairCallback {
            HwBluetoothSDK.sharedInstance().removeDevicePairStateCallback(pairCallback)
        }
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    @objc private func becameActive() {
        guard phase == .unpaired || phase == .pairing else { return }
        reload()
    }

    @objc private func reload() {
        title = L10n.tr("notify_switch")
        guard repo.isConnected() else {
            phase = .needConnect
            message = L10n.tr("status_need_connect")
            items = []
            request = nil
            setBusy(false)
            return
        }
        phase = .reading
        message = L10n.tr("jieli_settings_reading")
        items = []
        let token = UUID()
        request = token
        setBusy(true)
        repo.getPairState { [weak self] result in
            guard let self, self.request == token else { return }
            switch result {
            case .failure(let error):
                self.phase = .failed
                self.message = error.localizedDescription
                self.request = nil
                self.setBusy(false)
            case .success(let paired):
                if paired {
                    self.loadSwitches(token: token)
                } else {
                    self.phase = .unpaired
                    self.message = L10n.tr("notify_switch_unpaired")
                    self.request = nil
                    self.setBusy(false)
                }
            }
        }
    }

    private func loadSwitches(token: UUID) {
        message = L10n.tr("notify_getting_switches")
        repo.getSocialSwitches { [weak self] result in
            guard let self, self.request == token else { return }
            self.request = nil
            switch result {
            case .failure(let error):
                self.phase = .failed
                self.message = error.localizedDescription
                self.items = []
            case .success(let list):
                self.phase = .paired
                self.message = L10n.tr("notify_switch_paired")
                self.items = Self.makeItems(list)
            }
            self.setBusy(false)
        }
    }

    private static func makeItems(_ list: [HwSocialSwitch]) -> [SwitchItem] {
        let states = Dictionary(list.map { ($0.type, $0.s) }, uniquingKeysWith: { _, latest in latest })
        var rows = catalog.compactMap { spec -> SwitchItem? in
            guard let on = states[spec.type] else { return nil }
            return SwitchItem(type: spec.type, nameKey: spec.nameKey, on: on)
        }
        rows.append(SwitchItem(type: .other, nameKey: "notify_app_other", on: states[.other] ?? false))
        return rows
    }

    private func setBusy(_ value: Bool) {
        busy = value
        navigationItem.rightBarButtonItem?.isEnabled = !value
        tableView.reloadData()
    }

    private func handlePairEvent(_ state: Int) {
        guard !busy else { return }
        switch state {
        case 0:
            reload()
        case 2:
            phase = .unpaired
            message = L10n.tr("notify_switch_pair_timeout")
            items = []
            tableView.reloadData()
        default:
            phase = .unpaired
            message = L10n.tr("notify_switch_pair_failed")
            items = []
            tableView.reloadData()
        }
    }

    @objc private func requestPair() {
        guard !busy, repo.isConnected(), phase == .unpaired || phase == .pairing else { return }
        phase = .pairing
        message = L10n.tr("notify_switch_pairing")
        let token = UUID()
        request = token
        setBusy(true)
        repo.requestDeviceToPair { [weak self] result in
            guard let self, self.request == token else { return }
            switch result {
            case .failure(let error):
                self.phase = .unpaired
                self.message = error.localizedDescription
                self.request = nil
                self.setBusy(false)
            case .success:
                self.repo.getPairState { [weak self] result in
                    guard let self, self.request == token else { return }
                    switch result {
                    case .success(true):
                        self.loadSwitches(token: token)
                    case .success(false):
                        self.phase = .pairing
                        self.message = L10n.tr("notify_switch_pairing")
                        self.request = nil
                        self.setBusy(false)
                    case .failure(let error):
                        self.phase = .pairing
                        self.message = error.localizedDescription
                        self.request = nil
                        self.setBusy(false)
                    }
                }
            }
        }
    }

    private var showsPairAction: Bool {
        phase == .unpaired || phase == .pairing
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        phase == .paired ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return showsPairAction ? 2 : 1 }
        return items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? L10n.tr("notify_switch_pair") : L10n.tr("notify_switch_apps")
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 { return L10n.tr("notify_switch_pair_note") }
        if items.isEmpty { return L10n.tr("notify_switch_none") }
        return L10n.tr("notify_switch_apps_note")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return indexPath.row == 0 ? statusCell() : pairActionCell()
        }
        let item = items[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = L10n.tr(item.nameKey)
        cell.textLabel?.numberOfLines = 0
        let toggle = UISwitch()
        toggle.isOn = item.on
        toggle.isEnabled = !busy
        toggle.tag = indexPath.row
        toggle.accessibilityLabel = L10n.tr(item.nameKey)
        toggle.addTarget(self, action: #selector(changed(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    private func statusCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = L10n.tr("notify_switch")
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = message
        cell.detailTextLabel?.numberOfLines = 0
        if busy {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            cell.accessoryView = spinner
        }
        return cell
    }

    private func pairActionCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = L10n.tr("notify_switch_pair_action")
        cell.textLabel?.textColor = busy ? .tertiaryLabel : .systemBlue
        cell.selectionStyle = busy ? .none : .default
        cell.accessibilityLabel = L10n.tr("notify_switch_pair_action")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0, indexPath.row == 1 else { return }
        requestPair()
    }

    @objc private func changed(_ sender: UISwitch) {
        let row = sender.tag
        guard items.indices.contains(row), phase == .paired, !busy, repo.isConnected() else {
            sender.isOn = items.indices.contains(row) ? items[row].on : false
            if !repo.isConnected() {
                phase = .needConnect
                message = L10n.tr("status_need_connect")
                items = []
                tableView.reloadData()
            }
            return
        }
        let previous = items[row].on
        let on = sender.isOn
        items[row].on = on
        message = L10n.tr("jieli_settings_saving")
        let token = UUID()
        request = token
        setBusy(true)
        repo.setSocialSwitch(items[row].type, on: on) { [weak self] result in
            guard let self, self.request == token else { return }
            self.request = nil
            switch result {
            case .success:
                self.message = L10n.tr("notify_switch_paired")
            case .failure(let error):
                if self.items.indices.contains(row) { self.items[row].on = previous }
                self.message = error.localizedDescription
            }
            self.setBusy(false)
        }
    }
}
