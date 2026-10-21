import UIKit

final class ScanConnectViewController: UIViewController {
    private let repo = BleRepository.shared
    var onConnected: ((BleDeviceItem) -> Void)?

    private var devices: [BleDeviceItem] = []
    private var filteredDevices: [BleDeviceItem] = []
    private var rawDevices: [String: HwBluetoothDevice] = [:]
    private let searchBar = UISearchBar()
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let scanButton = UIHelpers.makeButton("", primary: true)
    private var scanning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("scan_title")
        view.backgroundColor = .systemGroupedBackground
        searchBar.placeholder = L10n.tr("scan_name_placeholder")
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        scanButton.setTitle(L10n.tr("start_scan"), for: .normal)
        scanButton.addTarget(self, action: #selector(toggleScan), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.keyboardDismissMode = .onDrag
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(searchBar)
        let controls = UIHelpers.makeCard([UIHelpers.makeGrid([scanButton])])
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        view.addSubview(table)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            controls.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            table.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 12),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        startScan()
    }

    private func updateFilteredDevices() {
        let query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        filteredDevices = query.isEmpty ? devices : devices.filter {
            $0.name?.localizedCaseInsensitiveContains(query) == true
        }
        table.reloadData()
    }

    @objc private func toggleScan() {
        if scanning {
            repo.stopScan()
            scanning = false
            scanButton.setTitle(L10n.tr("start_scan"), for: .normal)
        } else {
            startScan()
        }
    }

    private func startScan() {
        scanning = true
        devices.removeAll()
        rawDevices.removeAll()
        updateFilteredDevices()
        scanButton.setTitle(L10n.tr("stop_scan"), for: .normal)
        repo.scan(timeout: 12, onUpdate: { [weak self] list in
            self?.devices = list
            self?.updateFilteredDevices()
        }, onFinish: { [weak self] in
            self?.scanning = false
            self?.scanButton.setTitle(L10n.tr("start_scan"), for: .normal)
        })
        HwBluetoothSDK.sharedInstance().scan(callback: { [weak self] list, _ in
            guard let list = list else { return }
            for d in list {
                let key = (d.macAddress?.isEmpty == false ? d.macAddress! : (d.uuid ?? UUID().uuidString))
                self?.rawDevices[key] = d
            }
        }, stopAfter: 12, stopCallback: {})
    }

    private func connect(_ item: BleDeviceItem) {
        let key = item.macAddress.isEmpty ? (item.uuid ?? "") : item.macAddress
        guard let device = rawDevices[key] ?? rawDevices.values.first(where: {
            ($0.macAddress == item.macAddress && !item.macAddress.isEmpty) || $0.uuid == item.uuid
        }) else {
            guard !item.macAddress.isEmpty else {
                showAlert(L10n.tr("connect_missing_id"))
                return
            }
            let hud = UIAlertController(title: L10n.tr("connecting"), message: item.macAddress, preferredStyle: .alert)
            present(hud, animated: true)
            repo.connect(mac: item.macAddress) { [weak self] result in
                hud.dismiss(animated: true) {
                    switch result {
                    case .success:
                        self?.onConnected?(item)
                        self?.navigationController?.popViewController(animated: true)
                    case .failure(let e):
                        self?.showAlert(e.localizedDescription)
                    }
                }
            }
            return
        }
        repo.stopScan()
        let hud = UIAlertController(title: L10n.tr("connecting"), message: item.name ?? item.macAddress, preferredStyle: .alert)
        present(hud, animated: true)
        repo.connect(device: device) { [weak self] result in
            hud.dismiss(animated: true) {
                switch result {
                case .success(let connected):
                    self?.onConnected?(connected)
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let e):
                    self?.showAlert(e.localizedDescription)
                }
            }
        }
    }

    private func showAlert(_ msg: String) {
        let a = UIAlertController(title: L10n.tr("tips"), message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
        present(a, animated: true)
    }
}

extension ScanConnectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredDevices.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let d = filteredDevices[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(d.name ?? L10n.tr("unknown"))\n\(d.macAddress.isEmpty ? (d.uuid ?? "-") : d.macAddress)  RSSI=\(d.rssi ?? 0)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        connect(filteredDevices[indexPath.row])
    }
}

extension ScanConnectViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredDevices()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
