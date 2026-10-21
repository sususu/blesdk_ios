import UIKit

/// Raise-to-wake switch. Matches HaWoFit `LightupVC`:
/// read feature switches, then set `HwFeatureSwitchTypeHandUpActive`.
final class RaiseHandLightViewController: UITableViewController {
    private let repo = BleRepository.shared
    private var isOn: Bool?
    private var detail = ""
    private var busy = false
    private var request: UUID?

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("raise_hand_light")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh, target: self, action: #selector(reloadSetting)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSetting()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        request = nil
    }

    @objc private func reloadSetting() {
        title = L10n.tr("raise_hand_light")
        isOn = nil
        detail = L10n.tr("jieli_settings_reading")
        let token = UUID()
        request = token
        setBusy(true)
        guard repo.isConnected() else {
            detail = L10n.tr("status_need_connect")
            request = nil
            setBusy(false)
            return
        }
        HwBluetoothCenter.sharedInstance().getFeatureSwitches { [weak self] models, error in
            DispatchQueue.main.async {
                guard let self, self.request == token else { return }
                self.applyReadResult(models: models, error: error)
            }
        }
    }

    private func applyReadResult(models: [HwFeatureSwitch]?, error: Error?) {
        guard repo.isConnected() else {
            detail = L10n.tr("status_need_connect")
            request = nil
            setBusy(false)
            return
        }
        if let error {
            detail = error.localizedDescription
        } else if let item = models?.first(where: { $0.type == .handUpActive }) {
            isOn = item.s
            detail = L10n.tr(item.s ? "alarms_on" : "alarms_off")
        } else {
            detail = L10n.tr("raise_hand_missing")
        }
        setBusy(false)
    }

    private func setBusy(_ value: Bool) {
        busy = value
        navigationItem.rightBarButtonItem?.isEnabled = !value
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        L10n.tr("raise_hand_note")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = L10n.tr("raise_hand_light")
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = detail
        cell.detailTextLabel?.numberOfLines = 0
        let toggle = UISwitch()
        toggle.isOn = isOn ?? false
        toggle.isEnabled = !busy && isOn != nil
        toggle.accessibilityLabel = L10n.tr("raise_hand_light")
        toggle.addTarget(self, action: #selector(changed(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    @objc private func changed(_ sender: UISwitch) {
        guard let previous = isOn, !busy, repo.isConnected() else {
            sender.isOn = isOn ?? false
            if !repo.isConnected() {
                detail = L10n.tr("status_need_connect")
                tableView.reloadData()
            }
            return
        }
        let on = sender.isOn
        let token = UUID()
        request = token
        isOn = on
        detail = L10n.tr("jieli_settings_saving")
        setBusy(true)
        HwBluetoothCenter.sharedInstance().setFeatureSwitchWith(.handUpActive, s: on) { [weak self] ok, error in
            DispatchQueue.main.async {
                guard let self, self.request == token else { return }
                if let error {
                    self.isOn = previous
                    self.detail = error.localizedDescription
                } else if !ok {
                    self.isOn = previous
                    self.detail = L10n.tr("jieli_alarm_rejected")
                } else {
                    self.isOn = on
                    self.detail = L10n.tr(on ? "alarms_on" : "alarms_off")
                }
                self.setBusy(false)
            }
        }
    }
}
