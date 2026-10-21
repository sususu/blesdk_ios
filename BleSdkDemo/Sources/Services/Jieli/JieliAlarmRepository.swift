import Foundation

/// Jieli alarm and reminder demo service.
///
/// Alarms and reminders share one identify namespace. To keep this demo predictable:
/// - Alarms use IDs 1...5.
/// - Reminders use IDs 6...10.
///
/// Production apps should adjust both ranges to the target device capabilities.
final class JieliAlarmRepository {
    static let shared = JieliAlarmRepository()

    private enum DemoRule {
        static let alarmIDs = 1...5
        static let reminderIDs = 6...10

        static let alarmHour = 7
        static let alarmMinute = 30
        static let reminderHour = 10
        static let reminderMinute = 0
    }

    private let center: HwBluetoothCenter = HwBluetoothCenter.sharedInstance()

    private init() {}

    private let sdk = HwBluetoothSDK.sharedInstance()
    private let workoutEnabledKey = "blesdkdemo.workout.recognition.enabled"
    private let workoutMutedKey = "blesdkdemo.workout.recognition.mutedDate"

    // As in hawofit, recognition notifications are controlled locally, not on the device.
    var autoDetectWorkouts: Bool {
        get { UserDefaults.standard.object(forKey: workoutEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: workoutEnabledKey) }
    }

    var canPromptWorkout: Bool {
        guard autoDetectWorkouts else { return false }
        guard let muted = UserDefaults.standard.object(forKey: workoutMutedKey) as? Date else { return true }
        return !Calendar.current.isDateInToday(muted)
    }

    func muteWorkoutToday() { UserDefaults.standard.set(Date(), forKey: workoutMutedKey) }

    func resetWorkoutPreferences() {
        UserDefaults.standard.removeObject(forKey: workoutEnabledKey)
        UserDefaults.standard.removeObject(forKey: workoutMutedKey)
    }

    static func workoutTitleKey(_ category: Int) -> String? {
        switch category {
        case 1: return "jieli_detect_walking"
        case 2: return "jieli_detect_running"
        case 3: return "jieli_detect_cycling"
        case 4: return "jieli_detect_elliptical"
        case 5: return "jieli_detect_rowing"
        default: return nil
        }
    }

    func getLowBatteryReminder(completion: @escaping (Result<Bool, Error>) -> Void) {
        sdk.getLowBatteryReminderSwitch { on, error in
            Self.finish(error.map { .failure($0) } ?? .success(on), completion: completion)
        }
    }

    func setLowBatteryReminder(_ on: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setLowBatteryReminderSwitch(on) { success, error in
            Self.finishBoolean(success, error: error, completion: completion)
        }
    }

    func getVibration(completion: @escaping (Result<HwVibrationSettings, Error>) -> Void) {
        sdk.getVibrationSettings { settings, error in
            if let error {
                Self.finish(.failure(error), completion: completion)
            } else if let settings {
                Self.finish(.success(settings), completion: completion)
            } else {
                Self.finish(.failure(SdkError(code: -1, message: L10n.tr("jieli_settings_empty"))), completion: completion)
            }
        }
    }

    func setVibration(on: Bool, intensity: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (0...100).contains(intensity) else {
            Self.finish(.failure(SdkError(code: -1, message: L10n.tr("jieli_vibration_invalid"))), completion: completion)
            return
        }
        let settings = HwVibrationSettings()
        settings.isOn = on
        settings.intensity = intensity
        sdk.setVibrationSettings(settings) { success, error in
            Self.finishBoolean(success, error: error, completion: completion)
        }
    }

    // MARK: - Read

    /// Queries the device count first, then fetches exactly that many alarms.
    func getAlarms(completion: @escaping (Result<[HwReminder], Error>) -> Void) {
        center.getRemindAndAlarmCount { [weak self] _, alarmCount, error in
            guard let self else { return }

            if let error {
                Self.finish(.failure(error), completion: completion)
                return
            }
            guard alarmCount > 0 else {
                Self.finish(.success([]), completion: completion)
                return
            }

            self.center.getAlarmsWithCount(Int(alarmCount)) { list, error in
                Self.finishList(list, error: error, completion: completion)
            }
        }
    }

    /// Queries the device count first, then fetches exactly that many reminders.
    func getReminders(completion: @escaping (Result<[HwReminder], Error>) -> Void) {
        center.getRemindAndAlarmCount { [weak self] reminderCount, _, error in
            guard let self else { return }

            if let error {
                Self.finish(.failure(error), completion: completion)
                return
            }
            guard reminderCount > 0 else {
                Self.finish(.success([]), completion: completion)
                return
            }

            self.center.getRemindersWithCount(Int(reminderCount)) { list, error in
                Self.finishList(list, error: error, completion: completion)
            }
        }
    }

    // MARK: - Add

    func addDemoAlarm(completion: @escaping (Result<Void, Error>) -> Void) {
        addDemoItem(
            allowedIDs: DemoRule.alarmIDs,
            hour: DemoRule.alarmHour,
            minute: DemoRule.alarmMinute,
            content: L10n.tr("jieli_alarm_demo_content"),
            type: .awake,
            noFreeIDMessage: L10n.tr("jieli_alarm_slots_full"),
            completion: completion
        )
    }

    func addDemoReminder(completion: @escaping (Result<Void, Error>) -> Void) {
        addDemoItem(
            allowedIDs: DemoRule.reminderIDs,
            hour: DemoRule.reminderHour,
            minute: DemoRule.reminderMinute,
            content: L10n.tr("jieli_reminder_demo_content"),
            type: .custom,
            noFreeIDMessage: L10n.tr("jieli_reminder_slots_full"),
            completion: completion
        )
    }

    /// Reads all occupied IDs and selects the first free ID in the requested range.
    private func addDemoItem(
        allowedIDs: ClosedRange<Int>,
        hour: Int,
        minute: Int,
        content: String,
        type: HwReminderType,
        noFreeIDMessage: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        getAllItems { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let items):
                let usedIDs = Set(items.map(\.id))
                guard let identify = allowedIDs.first(where: { !usedIDs.contains($0) }) else {
                    completion(.failure(SdkError(code: -1, message: noFreeIDMessage)))
                    return
                }

                let model = self.makeReminder(
                    id: identify,
                    hour: hour,
                    minute: minute,
                    content: content,
                    type: type
                )
                self.center.add(model, identify: UInt(identify)) { success, error in
                    Self.finishBoolean(success, error: error, completion: completion)
                }
            }
        }
    }

    // MARK: - Delete

    func deleteAllAlarms(completion: @escaping (Result<Void, Error>) -> Void) {
        getAlarms { [weak self] result in
            guard let self else { return }
            self.deleteItems(from: result, completion: completion)
        }
    }

    func deleteAllReminders(completion: @escaping (Result<Void, Error>) -> Void) {
        getReminders { [weak self] result in
            guard let self else { return }
            self.deleteItems(from: result, completion: completion)
        }
    }

    func delete(identify: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        center.deleteReminderOrAlarm(byID: UInt(identify)) { success, error in
            Self.finishBoolean(success, error: error, completion: completion)
        }
    }

    private func deleteItems(
        from result: Result<[HwReminder], Error>,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        switch result {
        case .failure(let error):
            completion(.failure(error))
        case .success(let items):
            deleteOneByOne(ids: items.map(\.id), completion: completion)
        }
    }

    /// Deletes records sequentially because the reliable Jieli API deletes one ID at a time.
    private func deleteOneByOne(
        ids: [Int],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let validIDs = ids.filter { $0 > 0 }

        func delete(at index: Int) {
            guard index < validIDs.count else {
                Self.finish(.success(()), completion: completion)
                return
            }

            let id = validIDs[index]
            center.deleteReminderOrAlarm(byID: UInt(id)) { success, error in
                if let error {
                    Self.finish(.failure(error), completion: completion)
                } else if !success {
                    let message = L10n.tr("jieli_delete_id_rejected", id)
                    Self.finish(.failure(SdkError(code: -1, message: message)), completion: completion)
                } else {
                    delete(at: index + 1)
                }
            }
        }

        delete(at: 0)
    }

    // MARK: - Model

    /// Builds the SDK model using the same fields as hawofit's `toBleModel` implementation.
    private func makeReminder(
        id: Int,
        hour: Int,
        minute: Int,
        content: String,
        type: HwReminderType
    ) -> HwReminder {
        let model = HwReminder()
        model.id = id
        model.s = true
        model.hour = hour
        model.min = minute
        model.custom = content
        model.type = type
        model.repeatType = .none
        model.repeatValue = 0
        model.vib = .stateShortAlways
        model.times = [HwTimePoint(hour: hour, minute: minute)]

        // The current Swift overlay cannot assign a combined HwWeek directly, so use KVC.
        let weekdays = Int(HwWeek.monday.rawValue)
            | Int(HwWeek.tuesday.rawValue)
            | Int(HwWeek.wednesday.rawValue)
            | Int(HwWeek.thursday.rawValue)
            | Int(HwWeek.friday.rawValue)
        model.setValue(weekdays, forKey: "week")
        return model
    }

    // MARK: - Helpers

    private func getAllItems(completion: @escaping (Result<[HwReminder], Error>) -> Void) {
        getAlarms { [weak self] alarmResult in
            guard let self else { return }

            switch alarmResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let alarms):
                self.getReminders { reminderResult in
                    completion(reminderResult.map { alarms + $0 })
                }
            }
        }
    }

    private static func finishList(
        _ list: [Any]?,
        error: Error?,
        completion: @escaping (Result<[HwReminder], Error>) -> Void
    ) {
        if let error {
            finish(.failure(error), completion: completion)
        } else {
            finish(.success((list as? [HwReminder]) ?? []), completion: completion)
        }
    }

    private static func finishBoolean(
        _ success: Bool,
        error: Error?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        if let error {
            finish(.failure(error), completion: completion)
        } else if success {
            finish(.success(()), completion: completion)
        } else {
            let error = SdkError(code: -1, message: L10n.tr("jieli_alarm_rejected"))
            finish(.failure(error), completion: completion)
        }
    }

    private static func finish<T>(
        _ result: Result<T, Error>,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        DispatchQueue.main.async { completion(result) }
    }
}
