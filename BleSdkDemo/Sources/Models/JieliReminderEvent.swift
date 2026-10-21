import Foundation

struct JieliReminderEvent {
    static let typeGroups: [(titleKey: String, types: [HwReminderNotifyType])] = [
        ("jl_notify_group_daily", [.drinkWater, .washHand, .lowBattery, .sedentary]),
        ("jl_notify_group_goals", [.goalStep, .goalDistance, .goalCalorie, .goalDuration]),
        ("jl_notify_group_cycle", [.menstrualFertile, .menstrualPeriod]),
        ("jl_notify_group_alarm", [.alarm]),
        ("jl_notify_group_custom", [.customMeeting, .customSleep, .customSchedule, .customWorkout, .customMedicine, .customMeal, .customBill, .custom])
    ]

    static let messageKeys: [HwReminderNotifyType: String] = [
        .drinkWater: "jl_notify_drink", .washHand: "jl_notify_wash",
        .lowBattery: "jl_notify_low_battery", .sedentary: "jl_notify_sedentary",
        .goalStep: "jl_notify_goal_step", .goalDistance: "jl_notify_goal_distance",
        .goalCalorie: "jl_notify_goal_calorie", .goalDuration: "jl_notify_goal_duration",
        .menstrualFertile: "jl_notify_fertile", .menstrualPeriod: "jl_notify_period",
        .alarm: "jl_notify_alarm", .customMeeting: "jl_notify_meeting",
        .customSleep: "jl_notify_sleep", .customSchedule: "jl_notify_schedule",
        .customWorkout: "jl_notify_workout", .customMedicine: "jl_notify_medicine",
        .customMeal: "jl_notify_meal", .customBill: "jl_notify_bill", .custom: "jl_notify_custom"
    ]

    let type: HwReminderNotifyType
    let data: Data?
    let date: Date

    init?(type: HwReminderNotifyType, data: Data?, date: Date = Date()) {
        guard Self.messageKeys[type] != nil else { return nil }
        self.type = type
        self.data = data
        self.date = date
    }

    var isDailyGoal: Bool {
        [.goalStep, .goalDistance, .goalCalorie, .goalDuration].contains(type)
    }

    var alarmComponents: DateComponents {
        let bytes = data.map { Array($0) } ?? []
        if bytes.count == 2, bytes[0] < 24, bytes[1] < 60 {
            return DateComponents(hour: Int(bytes[0]), minute: Int(bytes[1]))
        }
        return Calendar.current.dateComponents([.hour, .minute], from: date)
    }

    var message: String {
        let key = Self.messageKeys[type]!
        guard type == .alarm else { return L10n.tr(key) }
        let time = Calendar.current.date(from: alarmComponents) ?? date
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return L10n.tr(key, formatter.string(from: time))
    }

    static func title(for type: HwReminderNotifyType) -> String {
        L10n.tr(messageKeys[type]! + "_type")
    }

    var typeTitle: String { Self.title(for: type) }

    var rawDescription: String {
        let payload = data?.map { String(format: "%02X", $0) }.joined(separator: " ") ?? "nil"
        return String(format: "type=0x%02X  data=%@", type.rawValue, payload)
    }
}

struct JieliReminderHistory {
    private(set) var events: [JieliReminderEvent] = []
    private var last: [HwReminderNotifyType: (data: Data?, uptime: TimeInterval)] = [:]

    mutating func append(_ event: JieliReminderEvent, uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Bool {
        // ponytail: identical payloads within 2 seconds are duplicates; use device event IDs if supplied later.
        if let previous = last[event.type], previous.data == event.data, uptime - previous.uptime < 2 { return false }
        last[event.type] = (event.data, uptime)
        events.insert(event, at: 0)
        if events.count > 200 { events.removeLast(events.count - 200) }
        return true
    }

    mutating func clear() {
        events.removeAll()
        last.removeAll()
    }
}
