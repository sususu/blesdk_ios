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
