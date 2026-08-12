import UIKit

/// Dedicated Jieli health BigData demo. Each button invokes one explicit Jieli API;
/// returned model descriptions are displayed in the list below.
final class JieliHealthSyncViewController: UIViewController {
    private struct ActionItem {
        let titleKey: String
        let action: () -> Void
    }

    private struct ResultRow {
        let index: Int
        let title: String
        let detail: String
    }

    private let repo = JieliHealthRepository.shared
    private lazy var actions: [ActionItem] = [
        ActionItem(titleKey: "jieli_get_sleep", action: { [weak self] in self?.getSleep() }),
        ActionItem(titleKey: "jieli_get_heart_rate", action: { [weak self] in self?.getHeartRate() }),
        ActionItem(titleKey: "jieli_get_stress", action: { [weak self] in self?.getStress() }),
        ActionItem(titleKey: "jieli_get_blood_oxygen", action: { [weak self] in self?.getBloodOxygen() }),
        ActionItem(titleKey: "jieli_get_sport_detail", action: { [weak self] in self?.getSportDetail() }),
        ActionItem(titleKey: "jieli_get_workouts", action: { [weak self] in self?.getWorkouts() }),
        ActionItem(titleKey: "jieli_delete_sleep", action: { [weak self] in self?.confirmDelete(titleKey: "jieli_delete_sleep", operation: self?.repo.deleteSleep) }),
        ActionItem(titleKey: "jieli_delete_heart_rate", action: { [weak self] in self?.confirmDelete(titleKey: "jieli_delete_heart_rate", operation: self?.repo.deleteHeartRate) }),
        ActionItem(titleKey: "jieli_delete_stress", action: { [weak self] in self?.confirmDelete(titleKey: "jieli_delete_stress", operation: self?.repo.deleteStress) }),
        ActionItem(titleKey: "jieli_delete_blood_oxygen", action: { [weak self] in self?.confirmDelete(titleKey: "jieli_delete_blood_oxygen", operation: self?.repo.deleteBloodOxygen) }),
        ActionItem(titleKey: "jieli_delete_sport_detail", action: { [weak self] in self?.confirmDelete(titleKey: "jieli_delete_sport_detail", operation: self?.repo.deleteSportDetail) }),
        ActionItem(titleKey: "jieli_delete_workouts", action: { [weak self] in self?.confirmDelete(titleKey: "jieli_delete_workouts", operation: self?.repo.deleteWorkouts) })
    ]
    private lazy var actionCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(JieliHealthActionCell.self, forCellWithReuseIdentifier: JieliHealthActionCell.reuseIdentifier)
        return view
    }()
    private let statusLabel = UIHelpers.makeLabel("", style: .footnote)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var rows: [ResultRow] = []
    private var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        applyLocalizedChrome()
    }

    private func setupUI() {
        actionCollectionView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(actionCollectionView)
        view.addSubview(statusLabel)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            actionCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            actionCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionCollectionView.heightAnchor.constraint(equalToConstant: 304),
            statusLabel.topAnchor.constraint(equalTo: actionCollectionView.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func applyLocalizedChrome() {
        title = L10n.tr("jieli_sync_data")
        statusLabel.text = L10n.tr("jieli_select_data")
    }

    private func getSleep() {
        request(
            title: L10n.tr("jieli_get_sleep"),
            operation: repo.getSleep,
            map: { [weak self] list in
                guard let self = self else { return [] }
                return list.compactMap { $0 as? HwSleepPoint }
                    .sorted { $0.time > $1.time }
                    .enumerated().map { offset, item in
                        ResultRow(
                            index: offset + 1,
                            title: L10n.tr("jieli_sleep_status", self.sleepStatusText(item.status)),
                            detail: L10n.tr("jieli_data_time", self.formatTime(item.time))
                        )
                    }
            }
        )
    }

    private func getHeartRate() {
        let title = L10n.tr("jieli_get_heart_rate")
        guard BleRepository.shared.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        setLoading(true)
        statusLabel.text = L10n.tr("jieli_loading_data", title)
        repo.getHeartRate { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .success(let list):
                let heartRates = list.compactMap { $0 as? HwHeartRate }.sorted { $0.time > $1.time }
                self.rows = heartRates.enumerated().map { offset, item in
                    ResultRow(
                        index: offset + 1,
                        title: L10n.tr("jieli_heart_rate_value", Int(item.bmp)),
                        detail: L10n.tr("jieli_heart_rate_time", self.formatTime(item.time))
                    )
                }
                self.statusLabel.text = L10n.tr("jieli_data_count", title, heartRates.count)
                self.tableView.reloadData()
            case .failure(let error):
                self.rows = []
                self.statusLabel.text = L10n.tr("jieli_data_failed", title, error.localizedDescription)
                self.tableView.reloadData()
            }
        }
    }

    private func getStress() {
        request(
            title: L10n.tr("jieli_get_stress"),
            operation: repo.getStress,
            map: { [weak self] list in
                guard let self = self else { return [] }
                return list.compactMap { $0 as? HwStress }
                    .sorted { $0.time > $1.time }
                    .enumerated().map { offset, item in
                        ResultRow(
                            index: offset + 1,
                            title: L10n.tr("jieli_stress_value", Int(item.stress)),
                            detail: L10n.tr("jieli_data_time", self.formatTime(item.time))
                        )
                    }
            }
        )
    }

    private func getBloodOxygen() {
        request(
            title: L10n.tr("jieli_get_blood_oxygen"),
            operation: repo.getBloodOxygen,
            map: { [weak self] list in
                guard let self = self else { return [] }
                return list.compactMap { $0 as? HwSpo2 }
                    .sorted { $0.time > $1.time }
                    .enumerated().map { offset, item in
                        ResultRow(
                            index: offset + 1,
                            title: L10n.tr("jieli_spo2_value", Int(item.spo2)),
                            detail: L10n.tr("jieli_data_time", self.formatTime(item.time))
                        )
                    }
            }
        )
    }

    private func getSportDetail() {
        request(
            title: L10n.tr("jieli_get_sport_detail"),
            operation: repo.getSportDetail,
            map: { [weak self] list in
                guard let self = self else { return [] }
                return list.compactMap { $0 as? HwActivity }
                    .sorted { $0.time > $1.time }
                    .enumerated().map { offset, item in
                        ResultRow(
                            index: offset + 1,
                            title: L10n.tr("jieli_sport_value", Int(item.step), Int(item.distance)),
                            detail: L10n.tr(
                                "jieli_sport_detail_value",
                                Int(item.calorie), Int(item.duration), Int(item.avgBpm), self.formatTime(item.time/1000.0)
                            )
                        )
                    }
            }
        )
    }

    private func getWorkouts() {
        request(
            title: L10n.tr("jieli_get_workouts"),
            operation: repo.getWorkouts,
            map: { [weak self] list in
                guard let self = self else { return [] }
                var workouts: [HwWorkout] = list.compactMap { value in
                    value as? HwWorkout
                }
                workouts.sort { first, second in
                    first.startTime > second.startTime
                }

                var result: [ResultRow] = []
                for (offset, item) in workouts.enumerated() {
                    let type = Int(item.type.rawValue)
                    let step = Int(item.step)
                    let distance = Int(item.distance)
                    let calorie = Int(item.calorie)
                    let duration = Int(item.duration)
                    let bpm = Int(item.bpm)
                    let startTime = self.formatWorkoutTime(TimeInterval(item.startTime))
                    let endTime = self.formatWorkoutTime(TimeInterval(item.endTime))
                    let rowTitle = L10n.tr("jieli_workout_value", type, step, distance)
                    let rowDetail = L10n.tr(
                        "jieli_workout_detail_value",
                        calorie,
                        duration,
                        bpm,
                        startTime,
                        endTime
                    )
                    result.append(ResultRow(index: offset + 1, title: rowTitle, detail: rowDetail))
                }
                return result
            }
        )
    }

    private func request(title: String,
                         operation: (@escaping (Result<[Any], Error>) -> Void) -> Void,
                         map: (([Any]) -> [ResultRow])? = nil) {
        guard BleRepository.shared.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        setLoading(true)
        statusLabel.text = L10n.tr("jieli_loading_data", title)
        operation { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .success(let list):
                self.rows = map?(list) ?? []
                self.statusLabel.text = L10n.tr("jieli_data_count", title, self.rows.count)
                self.tableView.reloadData()
            case .failure(let error):
                self.rows = []
                self.statusLabel.text = L10n.tr("jieli_data_failed", title, error.localizedDescription)
                self.tableView.reloadData()
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        self.loading = loading
        actionCollectionView.isUserInteractionEnabled = !loading
        actionCollectionView.alpha = loading ? 0.55 : 1
    }

    private func confirmDelete(
        titleKey: String,
        operation: ((@escaping (Result<Void, Error>) -> Void) -> Void)?
    ) {
        guard let operation = operation else { return }
        let title = L10n.tr(titleKey)
        let alert = UIAlertController(
            title: title,
            message: L10n.tr("jieli_delete_confirm"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("confirm"), style: .destructive) { [weak self] _ in
            self?.deleteData(title: title, operation: operation)
        })
        present(alert, animated: true)
    }

    private func deleteData(
        title: String,
        operation: (@escaping (Result<Void, Error>) -> Void) -> Void
    ) {
        guard BleRepository.shared.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        setLoading(true)
        statusLabel.text = L10n.tr("jieli_deleting_data", title)
        operation { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .success:
                self.rows = []
                self.tableView.reloadData()
                self.statusLabel.text = L10n.tr("jieli_delete_success", title)
            case .failure(let error):
                self.statusLabel.text = L10n.tr("jieli_data_failed", title, error.localizedDescription)
            }
        }
    }

    private func formatTime(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    private func formatWorkoutTime(_ timestamp: TimeInterval) -> String {
        // HwWorkout start/end timestamps are milliseconds.
        formatTime(timestamp / 1000)
    }

    private func sleepStatusText(_ status: HwSleepStatus) -> String {
        switch status.rawValue {
        case 0: return L10n.tr("jieli_sleep_deep")
        case 1: return L10n.tr("jieli_sleep_light")
        case 2: return L10n.tr("jieli_sleep_awake")
        case 3: return L10n.tr("jieli_sleep_prepare")
        case 5: return L10n.tr("jieli_sleep_rem")
        case 0x10: return L10n.tr("jieli_sleep_enter")
        case 0x11, 0x12: return L10n.tr("jieli_sleep_exit")
        default: return L10n.tr("jieli_sleep_unknown", Int(status.rawValue))
        }
    }
}

extension JieliHealthSyncViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        actions.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: JieliHealthActionCell.reuseIdentifier,
            for: indexPath
        ) as! JieliHealthActionCell
        cell.configure(title: L10n.tr(actions[indexPath.item].titleKey))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !loading else { return }
        actions[indexPath.item].action()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 8) / 2)
        return CGSize(width: width, height: 44)
    }
}

private final class JieliHealthActionCell: UICollectionViewCell {
    static let reuseIdentifier = "JieliHealthActionCell"
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBlue
        contentView.layer.cornerRadius = 8
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String) { titleLabel.text = title }
}

extension JieliHealthSyncViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "JieliHealthDataCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let row = rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.detail
        cell.detailTextLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
}
