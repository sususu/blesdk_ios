import UIKit

final class JieliManualMeasureViewController: UITableViewController {
    private struct Metric {
        let type: HwMonitorDataType
        let titleKey: String
        let unit: String
        let range: ClosedRange<Double>
    }

    // Same measurement types and valid ranges as hawofit's HealthMeasureVC.
    private let metrics: [Metric] = [
        Metric(type: .heartRate, titleKey: "jieli_measure_hr", unit: "bpm", range: 30...220),
        Metric(type: .HRV, titleKey: "jieli_measure_hrv", unit: "ms", range: 1...250),
        Metric(type: .spO2, titleKey: "jieli_measure_spo2", unit: "%", range: 50...100),
        Metric(type: .stress, titleKey: "jieli_measure_stress", unit: "", range: 1...100),
        Metric(type: .skinTemperature, titleKey: "jieli_measure_skin", unit: "℃", range: 20...45),
        Metric(type: .respiratoryRate, titleKey: "jieli_measure_rpm", unit: "", range: 1...60)
    ]
    private enum State { case idle, starting, measuring, stopping }
    private let sdk = HwBluetoothSDK.sharedInstance()
    private var selected = 0
    private var state: State = .idle
    private var session: UUID?
    private var removals: [() -> Void] = []
    private var timeout: DispatchWorkItem?
    private var valueText = "--"
    private var timeText = ""
    private var statusText = L10n.tr("jieli_measure_ready")
    private var hasValue = false

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("jieli_manual_measure")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup(sendStop: true)
        state = .idle
        statusText = L10n.tr("jieli_measure_stopped")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    deinit {
        cleanup(sendStop: true)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func enterBackground() {
        cleanup(sendStop: true)
        state = .idle
        statusText = L10n.tr("jieli_measure_background")
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? L10n.tr("jieli_measure_type") : nil
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? L10n.tr("jieli_measure_tip") : nil
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        if indexPath.section == 0 {
            cell.selectionStyle = .none
            let buttons = metrics.indices.map { index in
                let button = UIHelpers.makeButton(L10n.tr(metrics[index].titleKey), primary: selected == index)
                button.tag = index
                button.isEnabled = state == .idle
                if selected == index { button.accessibilityTraits.insert(.selected) }
                button.addTarget(self, action: #selector(selectMetric(_:)), for: .touchUpInside)
                return button
            }
            let grid = UIHelpers.makeGrid(buttons)
            grid.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(grid)
            NSLayoutConstraint.activate([
                grid.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                grid.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                grid.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                grid.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
            ])
        } else if indexPath.section == 1 {
            let unit = metrics[selected].type == .respiratoryRate ? L10n.tr("jieli_measure_rpm_unit") : metrics[selected].unit
            cell.textLabel?.text = "\(valueText) \(unit)"
            cell.textLabel?.font = .preferredFont(forTextStyle: .title1)
            cell.detailTextLabel?.text = [statusText, timeText].filter { !$0.isEmpty }.joined(separator: "\n")
            cell.selectionStyle = .none
            cell.accessibilityTraits = .updatesFrequently
        } else {
            let key = state == .idle ? "jieli_measure_start" : (state == .stopping ? "jieli_measure_stopping" : "jieli_measure_stop")
            cell.textLabel?.text = L10n.tr(key)
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = state == .stopping ? .secondaryLabel : .systemBlue
            cell.selectionStyle = state == .stopping ? .none : .default
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            if state == .idle { startMeasure() }
            else if state != .stopping { stopMeasure(message: L10n.tr("jieli_measure_stopped")) }
        }
    }

    @objc private func selectMetric(_ sender: UIButton) {
        guard state == .idle else { return }
        selected = sender.tag
        valueText = "--"
        timeText = ""
        statusText = L10n.tr("jieli_measure_ready")
        tableView.reloadData()
    }

    private func startMeasure() {
        guard state == .idle else { return }
        guard BleRepository.shared.isConnected() else {
            statusText = L10n.tr("status_need_connect")
            tableView.reloadData()
            return
        }
        let token = UUID()
        session = token
        state = .starting
        hasValue = false
        valueText = "--"
        timeText = ""
        statusText = L10n.tr("jieli_measure_starting")
        registerListeners(token)
        tableView.reloadData()
        scheduleTimeout(seconds: 60) { controller in
            controller.stopMeasure(message: L10n.tr(controller.hasValue ? "jieli_measure_timeout" : "jieli_measure_no_result"))
        }
        sdk.startMonitoring(with: metrics[selected].type) { [weak self] success, error in
            self?.deliver(token) { controller in
                guard controller.state == .starting else { return }
                if success && error == nil {
                    controller.state = .measuring
                    controller.statusText = L10n.tr("jieli_measure_running")
                    controller.tableView.reloadData()
                } else {
                    controller.finish(message: error?.localizedDescription ?? L10n.tr("jieli_measure_rejected"))
                }
            }
        }
    }

    private func stopMeasure(message: String) {
        guard let token = session, state != .stopping else { return }
        state = .stopping
        statusText = L10n.tr("jieli_measure_stopping")
        tableView.reloadData()
        // Keep controls locked until stop is acknowledged; allow retry if it fails or stalls.
        scheduleTimeout(seconds: 10) { $0.stopFailed(L10n.tr("jieli_measure_stop_failed")) }
        sdk.stopMonitoring(with: metrics[selected].type) { [weak self] success, error in
            self?.deliver(token) { controller in
                guard controller.state == .stopping else { return }
                if success && error == nil { controller.finish(message: message) }
                else { controller.stopFailed(error?.localizedDescription ?? L10n.tr("jieli_measure_stop_failed")) }
            }
        }
    }

    private func stopFailed(_ message: String) {
        timeout?.cancel()
        timeout = nil
        state = .measuring
        statusText = message
        tableView.reloadData()
    }

    private func finish(message: String) {
        cleanup(sendStop: false)
        state = .idle
        statusText = message
        tableView.reloadData()
    }

    private func cleanup(sendStop: Bool) {
        let active = session != nil
        session = nil
        timeout?.cancel()
        timeout = nil
        removals.forEach { $0() }
        removals.removeAll()
        if sendStop && active { sdk.stopMonitoring(with: metrics[selected].type, callback: nil) }
    }

    private func deliver(_ token: UUID, action: @escaping (JieliManualMeasureViewController) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.session == token else { return }
            action(self)
        }
    }

    private func scheduleTimeout(seconds: TimeInterval, action: @escaping (JieliManualMeasureViewController) -> Void) {
        timeout?.cancel()
        guard let token = session else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.session == token else { return }
            action(self)
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func receive(_ value: Double, time: Date = Date()) {
        guard state == .starting || state == .measuring,
              value.isFinite, metrics[selected].range.contains(value) else { return }
        hasValue = true
        valueText = metrics[selected].type == .skinTemperature ? String(format: "%.1f", value) : String(Int(value))
        timeText = DateFormatter.localizedString(from: time, dateStyle: .short, timeStyle: .medium)
        tableView.reloadData()
    }

    private func registerListeners(_ token: UUID) {
        let integer: HwIntValueChangedCallback = { [weak self] value in
            self?.deliver(token) { $0.receive(Double(value)) }
        }
        switch metrics[selected].type {
        case .heartRate:
            sdk.addHeartrateValueChangedListener(integer)
            removals.append { [sdk] in sdk.removeHeartrateValueChangedListener(integer) }
        case .HRV:
            sdk.addRealtimeHRVUpdateListener(integer)
            removals.append { [sdk] in sdk.removeRealtimeHRVUpdateListener(integer) }
        case .stress:
            sdk.addStressValueChangedListener(integer)
            removals.append { [sdk] in sdk.removeStressValueChangedListener(integer) }
        case .respiratoryRate:
            sdk.addRealtimeRPMUpdateListener(integer)
            removals.append { [sdk] in sdk.removeRealtimeRPMUpdateListener(integer) }
        case .spO2:
            let callback: HwSpo2ValueChangedCallback = { [weak self] value, _ in
                self?.deliver(token) { $0.receive(Double(value)) }
            }
            sdk.addSpo2ValueChangedListener(callback)
            removals.append { [sdk] in sdk.removeSpo2ValueChangedListener(callback) }
        case .skinTemperature:
            let callback: HwFloatValueChangedCallback = { [weak self] value in
                self?.deliver(token) { $0.receive(Double(value)) }
            }
            sdk.addRealtimeSkinTemperatureUpdateListener(callback)
            removals.append { [sdk] in sdk.removeRealtimeSkinTemperatureUpdateListener(callback) }
        default: break
        }
        let timed: HwTimedMeasureCallback = { [weak self] type, value, timeMs in
            self?.deliver(token) { controller in
                guard type == controller.metrics[controller.selected].type, timeMs > 0 else { return }
                controller.receive(value, time: Date(timeIntervalSince1970: Double(timeMs) / 1000))
            }
        }
        sdk.addTimedMeasureListener(timed)
        removals.append { [sdk] in sdk.removeTimedMeasureListener(timed) }
        let notWorn: HwNotProperlyWornCallback = { [weak self] in
            self?.deliver(token) { controller in
                guard controller.state != .stopping else { return }
                controller.statusText = L10n.tr("jieli_measure_not_worn")
                controller.tableView.reloadData()
            }
        }
        sdk.addNotProperlyWornCallback(notWorn)
        removals.append { [sdk] in sdk.removeNotProperlyWornCallback(notWorn) }
        let stopped: HwMonitorStateChangedCallback = { [weak self] type in
            self?.deliver(token) { controller in
                guard type == controller.metrics[controller.selected].type, controller.state != .starting else { return }
                controller.finish(message: L10n.tr(controller.hasValue ? "jieli_measure_finished" : "jieli_measure_no_result"))
            }
        }
        sdk.addMonitorStateChangedCallback(stopped)
        removals.append { [sdk] in sdk.removeMonitorStateChangedCallback(stopped) }
        let connection: HwBluetoothConnectionStateChangedCallback = { [weak self] state in
            self?.deliver(token) { controller in
                if state == .disconnected { controller.finish(message: L10n.tr("status_need_connect")) }
            }
        }
        sdk.addBluetoothConnectionStateChangedCallback(connection)
        removals.append { [sdk] in sdk.removeBluetoothConnectionStateChangedCallback(connection) }
    }
}
