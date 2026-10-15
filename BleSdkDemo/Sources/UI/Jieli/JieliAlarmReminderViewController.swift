import UIKit

final class JieliAlarmReminderViewController: FeatureBaseViewController {
    private let jieliRepo = JieliAlarmRepository.shared

    override func viewDidLoad() {
        title = L10n.tr("jieli_alarms")
        super.viewDidLoad()
        let noteLabel = UIHelpers.makeLabel(L10n.tr("jieli_alarm_id_rule_note"), style: .footnote)
        noteLabel.textColor = .systemOrange
        noteLabel.backgroundColor = .secondarySystemBackground
        noteLabel.layer.cornerRadius = 8
        noteLabel.layer.masksToBounds = true
        actionsStack.insertArrangedSubview(noteLabel, at: 0)
    }

    override func buildActions() {
        addAction(L10n.tr("jieli_low_battery")) { self.configureLowBattery() }
        addAction(L10n.tr("jieli_vibration")) { self.configureVibration() }
        addAction(L10n.tr("jieli_auto_workout")) { self.configureAutoWorkout() }

        addAction(L10n.tr("jieli_get_alarms")) {
            self.run(L10n.tr("alarms_getting")) { done in
                self.jieliRepo.getAlarms { result in
                    done(result.map { self.formatList($0) })
                }
            }
        }
        addAction(L10n.tr("jieli_add_alarm")) {
            self.run(L10n.tr("alarms_adding")) { done in
                self.jieliRepo.addDemoAlarm { result in
                    done(result.map { L10n.tr("jieli_alarm_added") })
                }
            }
        }
        addAction(L10n.tr("jieli_delete_alarms")) {
            self.confirmDelete(title: L10n.tr("jieli_delete_alarms")) {
                self.run(L10n.tr("alarms_deleting")) { done in
                    self.jieliRepo.deleteAllAlarms { result in
                        done(result.map { L10n.tr("jieli_alarms_deleted") })
                    }
                }
            }
        }
        addAction(L10n.tr("jieli_get_reminders")) {
            self.run(L10n.tr("reminders_getting")) { done in
                self.jieliRepo.getReminders { result in
                    done(result.map { self.formatList($0) })
                }
            }
        }
        addAction(L10n.tr("jieli_add_reminder")) {
            self.run(L10n.tr("reminders_setting")) { done in
                self.jieliRepo.addDemoReminder { result in
                    done(result.map { L10n.tr("jieli_reminder_added") })
                }
            }
        }
        addAction(L10n.tr("jieli_delete_reminders")) {
            self.confirmDelete(title: L10n.tr("jieli_delete_reminders")) {
                self.run(L10n.tr("alarms_deleting")) { done in
                    self.jieliRepo.deleteAllReminders { result in
                        done(result.map { L10n.tr("jieli_reminders_deleted") })
                    }
                }
            }
        }
    }

    private func switchTitle(_ on: Bool) -> String {
        L10n.tr(on ? "alarms_on" : "alarms_off")
    }

    private func configureLowBattery() {
        run(L10n.tr("jieli_settings_reading")) { done in
            self.jieliRepo.getLowBatteryReminder { result in
                done(result.map { L10n.tr("jieli_current_setting", self.switchTitle($0)) })
                guard case .success(let on) = result, self.view.window != nil, self.presentedViewController == nil else { return }
                let alert = UIAlertController(title: L10n.tr("jieli_low_battery"),
                    message: L10n.tr("jieli_current_setting", self.switchTitle(on)), preferredStyle: .alert)
                for enabled in [true, false] {
                    alert.addAction(UIAlertAction(title: self.switchTitle(enabled) + (enabled == on ? " ✓" : ""), style: .default) { _ in
                        self.run(L10n.tr("jieli_settings_saving")) { saved in
                            self.jieliRepo.setLowBatteryReminder(enabled) { result in
                                saved(result.map { L10n.tr("jieli_current_setting", self.switchTitle(enabled)) })
                            }
                        }
                    })
                }
                alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }

    private func configureVibration() {
        run(L10n.tr("jieli_settings_reading")) { done in
            self.jieliRepo.getVibration { result in
                let describe: (HwVibrationSettings) -> String = { settings in
                    L10n.tr("jieli_vibration_current", self.switchTitle(settings.isOn), settings.intensity)
                }
                done(result.map(describe))
                guard case .success(let settings) = result, self.view.window != nil, self.presentedViewController == nil else { return }
                let alert = UIAlertController(title: L10n.tr("jieli_vibration"), message: describe(settings), preferredStyle: .alert)
                let options: [(String, Bool, Int)] = [
                    ("alarms_off", false, settings.intensity),
                    ("jieli_vibration_weak", true, 33),
                    ("jieli_vibration_medium", true, 66),
                    ("jieli_vibration_strong", true, 99)
                ]
                for (key, on, intensity) in options {
                    let selected = on == settings.isOn && (!on || intensity == settings.intensity)
                    alert.addAction(UIAlertAction(title: L10n.tr(key) + (selected ? " ✓" : ""), style: .default) { _ in
                        self.run(L10n.tr("jieli_settings_saving")) { saved in
                            self.jieliRepo.setVibration(on: on, intensity: intensity) { result in
                                saved(result.map { L10n.tr("jieli_vibration_current", self.switchTitle(on), intensity) })
                            }
                        }
                    })
                }
                alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }

    private func configureAutoWorkout() {
        let on = jieliRepo.autoDetectWorkouts
        let alert = UIAlertController(title: L10n.tr("jieli_auto_workout"),
            message: L10n.tr("jieli_auto_workout_note") + "\n" + L10n.tr("jieli_current_setting", switchTitle(on)), preferredStyle: .alert)
        for enabled in [true, false] {
            alert.addAction(UIAlertAction(title: switchTitle(enabled) + (enabled == on ? " ✓" : ""), style: .default) { _ in
                self.jieliRepo.autoDetectWorkouts = enabled
                self.statusLabel.text = L10n.tr("feature_success")
                self.resultLabel.text = L10n.tr("jieli_current_setting", self.switchTitle(enabled))
            })
        }
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func formatList(_ list: [HwReminder]) -> String {
        guard !list.isEmpty else { return L10n.tr("alarms_empty") }
        return list.map { item in
            let id = item.id
            let enabled = item.s
            let time: String
            if let first = (item.times as? [HwTimePoint])?.first {
                time = String(format: "%02d:%02d", first.hour, first.minute)
            } else {
                time = String(format: "%02d:%02d", item.hour, item.min)
            }
            return L10n.tr(
                "jieli_alarm_line",
                id,
                time,
                enabled ? L10n.tr("alarms_on") : L10n.tr("alarms_off"),
                item.custom
            )
        }.joined(separator: "\n")
    }

    private func confirmDelete(title: String, action: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: L10n.tr("jieli_delete_confirm"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("confirm"), style: .destructive) { _ in action() })
        present(alert, animated: true)
    }
}
