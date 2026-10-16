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
