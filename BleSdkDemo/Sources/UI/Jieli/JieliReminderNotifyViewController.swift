import UIKit

final class JieliReminderNotifyViewController: UIViewController {
    private let manager = JieliReminderNotifyManager.shared
    private let statusLabel = UIHelpers.makeLabel("", style: .subheadline)
    private let permissionLabel = UIHelpers.makeLabel("", style: .footnote)
    private let goalLabel = UIHelpers.makeLabel("", style: .footnote)
    private let eventsView = UITextView()
    private let startButton = UIHelpers.makeButton(L10n.tr("jl_notify_start"), primary: true)
    private let stopButton = UIHelpers.makeButton(L10n.tr("jl_notify_stop"))
    private let clearButton = UIHelpers.makeButton(L10n.tr("jl_notify_clear"))

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("jieli_reminder_notify")
        view.backgroundColor = .systemGroupedBackground
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        let permissionButton = UIHelpers.makeButton(L10n.tr("jl_notify_permission"))
        permissionButton.addTarget(self, action: #selector(requestPermission), for: .touchUpInside)
        let settingsButton = UIHelpers.makeButton(L10n.tr("jl_notify_settings"))
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        eventsView.isEditable = false
        eventsView.isSelectable = true
        eventsView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventsView.textColor = .label
        eventsView.backgroundColor = .clear
        eventsView.heightAnchor.constraint(equalToConstant: 280).isActive = true
        let note = UIHelpers.makeLabel(L10n.tr("jl_notify_note"), style: .footnote)
        note.textColor = .secondaryLabel
        let types = UIStackView(arrangedSubviews: JieliReminderEvent.typeGroups.map { group in
            let names = group.types.map { JieliReminderEvent.title(for: $0) }.joined(separator: " / ")
            let text = group.types.count == 1 ? names : L10n.tr(group.titleKey) + ": " + names
            return UIHelpers.makeLabel(text, style: .footnote)
        })
        types.axis = .vertical
        types.spacing = 8
        types.isHidden = true
        let typesButton = UIHelpers.makeButton(L10n.tr("jl_notify_types", JieliReminderEvent.messageKeys.count))
        typesButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        typesButton.accessibilityValue = L10n.tr("jl_notify_collapsed")
        typesButton.addAction(UIAction { [weak types, weak typesButton] _ in
            guard let types else { return }
            types.isHidden.toggle()
            typesButton?.setImage(UIImage(systemName: types.isHidden ? "chevron.down" : "chevron.up"), for: .normal)
            typesButton?.accessibilityValue = L10n.tr(types.isHidden ? "jl_notify_collapsed" : "jl_notify_expanded")
        }, for: .touchUpInside)
        let content = UIStackView(arrangedSubviews: [
            UIHelpers.makeCard([statusLabel, permissionLabel], title: L10n.tr("ui_status")),
            UIHelpers.makeCard([UIHelpers.makeGrid([startButton, stopButton, clearButton])], title: L10n.tr("ui_actions")),
            UIHelpers.makeCard([typesButton, types]),
            UIHelpers.makeCard([UIHelpers.makeGrid([permissionButton, settingsButton]), note], title: L10n.tr("jl_notify_permission")),
            UIHelpers.makeCard([goalLabel], title: L10n.tr("jl_notify_goal_title")),
            UIHelpers.makeCard([eventsView], title: L10n.tr("jl_notify_events"))
        ])
        UIHelpers.installScrollableContent(content, in: view)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .jieliRemindersChanged, object: manager)
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager.syncWithBindState()
        manager.refreshNotificationStatus()
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func start() { manager.start() }
    @objc private func stop() { manager.stop() }
    @objc private func clear() { manager.clearHistory() }
    @objc private func requestPermission() { manager.requestNotificationPermission() }
    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func refresh() {
        statusLabel.text = manager.status + (manager.isListening && !BleRepository.shared.isConnected() ? "\n" + L10n.tr("status_need_connect") : "")
        permissionLabel.text = manager.notificationStatus
        goalLabel.text = manager.goalSummary.isEmpty ? L10n.tr("jl_notify_goal_idle") : manager.goalSummary
        startButton.isEnabled = !manager.isListening && BleRepository.shared.isConnected() && BleRepository.shared.loadBoundDevice() != nil
        stopButton.isEnabled = manager.isListening
        clearButton.isEnabled = !manager.history.events.isEmpty || !manager.goalSummary.isEmpty
        let text = manager.history.events.map { event in
            let time = DateFormatter.localizedString(from: event.date, dateStyle: .short, timeStyle: .medium)
            return "\(time) · \(event.typeTitle)\n\(event.message)"
        }.joined(separator: "\n\n")
        let display = text.isEmpty ? L10n.tr("jl_notify_empty") : text
        if eventsView.text != display {
            eventsView.text = display
            eventsView.setContentOffset(.zero, animated: false)
        }
    }
}
