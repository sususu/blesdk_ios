import UIKit

final class JieliAutoMonitorViewController: UITableViewController {
    private enum Kind: Int, CaseIterable {
        case heartRate, hrv, bloodOxygen, stress, skinTemperature, respiratoryRate

        var titleKey: String {
            ["jieli_measure_hr", "jieli_measure_hrv", "jieli_measure_spo2", "jieli_measure_stress",
             "jieli_measure_skin", "jieli_measure_rpm"][rawValue]
        }

        // Skin/RPM follow hawofit's AutoTrackFeaturesVC; HR uses its first supported interval.
        var enabledInterval: Int32 { self == .heartRate ? 5 : 60 }

        func read(completion: @escaping (Result<(Bool, Int?), Error>) -> Void) {
            let sdk = HwBluetoothSDK.sharedInstance()
            let boolean: HwBoolCallback = { on, error in
                completion(error.map { .failure($0) } ?? .success((on, nil)))
            }
            let interval: HwBCIntegerCallback = { minutes, error in
                if let error { completion(.failure(error)) }
                else if minutes < 0 {
                    completion(.failure(SdkError(code: -1, message: L10n.tr("jieli_monitor_invalid_interval"))))
                } else { completion(.success((minutes > 0, minutes))) }
            }
            switch self {
            case .heartRate: sdk.getHeartrateMonitoringInterval(callback: interval)
            case .hrv: HwBluetoothCenter.sharedInstance().getAutoTrackHRV(callback: boolean)
            case .bloodOxygen: sdk.getSpO2MonitorEnable(callback: boolean)
            case .stress: sdk.getStressMonitorEnable(callback: boolean)
            case .skinTemperature: sdk.getSkinTemperatureMonitorInterval(callback: interval)
            case .respiratoryRate: sdk.getRespiratoryRateMonitorInterval(callback: interval)
            }
        }

        func write(_ on: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
            let sdk = HwBluetoothSDK.sharedInstance()
            let callback: HwBoolCallback = { success, error in
                if let error { completion(.failure(error)) }
                else if success { completion(.success(())) }
                else { completion(.failure(SdkError(code: -1, message: L10n.tr("jieli_alarm_rejected")))) }
            }
            let interval: Int32 = on ? enabledInterval : 0
            switch self {
            case .heartRate: sdk.setHeartrateMonitoringInterval(interval, callback: callback)
            case .hrv: HwBluetoothCenter.sharedInstance().setAutoHRVWithStatus(on ? 1 : 0, callback: callback)
            case .bloodOxygen: sdk.setSpO2MonitorEnable(on, callback: callback)
            case .stress: sdk.setStressMonitorEnable(on, callback: callback)
            case .skinTemperature: sdk.setSkinTemperatureMonitorInterval(interval, callback: callback)
            case .respiratoryRate: sdk.setRespiratoryRateMonitorInterval(interval, callback: callback)
            }
        }
    }

    private var values: [Kind: Bool] = [:]
    private var details: [Kind: String] = [:]
    private var busy = false
    private var request: UUID?
    private var deviceID: String?
    private let repo = BleRepository.shared

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("jieli_auto_monitor")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadSettings))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSettings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        request = nil
    }

    private var currentDeviceID: String? { repo.connectedUUID() ?? repo.connectedMac() }

    @objc private func reloadSettings() {
        values.removeAll()
        details.removeAll()
        deviceID = currentDeviceID
        request = UUID()
        setBusy(true)
        readNext(0)
    }

    private func setBusy(_ value: Bool) {
        busy = value
        navigationItem.rightBarButtonItem?.isEnabled = !value
        tableView.reloadData()
    }

    private func checkConnection() -> Bool {
        guard repo.isConnected(), currentDeviceID == deviceID else {
            request = nil
            values.removeAll()
            for kind in Kind.allCases { details[kind] = L10n.tr("status_need_connect") }
            setBusy(false)
            return false
        }
        return true
    }

    private func readNext(_ index: Int) {
        guard checkConnection() else { return }
        guard index < Kind.allCases.count else { setBusy(false); return }
        let kind = Kind.allCases[index]
        let token = request
        kind.read { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.request == token, self.checkConnection() else { return }
                switch result {
                case .success(let (on, interval)):
                    self.values[kind] = on
                    self.details[kind] = self.settingText(on: on, interval: interval)
                case .failure(let error): self.details[kind] = error.localizedDescription
                }
                self.tableView.reloadData()
                self.readNext(index + 1)
            }
        }
    }

    private func settingText(on: Bool, interval: Int?) -> String {
        if on, let interval { return L10n.tr("jieli_monitor_every", interval) }
        return L10n.tr(on ? "alarms_on" : "alarms_off")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Kind.allCases.count }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        L10n.tr("jieli_monitor_note")
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kind = Kind.allCases[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = L10n.tr(kind.titleKey)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = details[kind] ?? L10n.tr("jieli_settings_reading")
        let toggle = UISwitch()
        toggle.tag = kind.rawValue
        toggle.isOn = values[kind] ?? false
        toggle.isEnabled = !busy && values[kind] != nil
        toggle.accessibilityLabel = L10n.tr(kind.titleKey)
        toggle.addTarget(self, action: #selector(changed(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    @objc private func changed(_ sender: UISwitch) {
        guard let kind = Kind(rawValue: sender.tag), let previous = values[kind] else { return }
        guard !busy else { sender.isOn = previous; return }
        guard checkConnection() else { return }
        let on = sender.isOn
        let token = UUID()
        request = token
        values[kind] = on
        details[kind] = L10n.tr("jieli_settings_saving")
        setBusy(true)
        kind.write(on) { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.request == token, self.checkConnection() else { return }
                switch result {
                case .success:
                    self.values[kind] = on
                    let interval = (kind == .heartRate || kind == .skinTemperature || kind == .respiratoryRate)
                        ? Int(on ? kind.enabledInterval : 0) : nil
                    self.details[kind] = self.settingText(on: on, interval: interval)
                case .failure(let error):
                    self.values[kind] = previous
                    self.details[kind] = error.localizedDescription
                }
                self.setBusy(false)
            }
        }
    }
}
