import UIKit

/// Step-by-step **device bind** demo screen, aligned with Android bind + HaWoFit post-bind setup.
///
/// # Pipeline (`runStep`)
/// 0. `startBindDevice` — watch-side confirmation (hard fail stops the flow)
/// 1. `setDeviceTime` — sync phone wall clock (24h)
/// 2. `setUserInfo` — demo profile (gender / age / height / weight)
/// 3. `setUnit` — metric
/// 4. `setLanguage` — demo language
/// 5. `getDeviceInfo` — firmware / MAC / battery; used later for local persistence
/// 6. `endBindDevice` — close the bind session on the firmware
/// 7. `getPairState` — check classic / system pairing
/// 8. `requestDeviceToPair` — soft step; skipped if already paired (iOS has no `createBond`)
/// 9. Local “save bind” marker — actual `BoundDeviceStore` write happens in `HomeViewController`
///    when `onFinished(true, deviceInfo)` returns
///
/// Hard steps (`finishHard`) abort on failure and re-enable **Start**.
/// Soft steps (`finishSoft`) mark failure as skipped and continue.
final class BindFlowViewController: UIViewController {
    private let repo = BleRepository.shared
    /// Called after dismiss. `success` is true only when every hard step completed;
    /// `deviceInfo` is the payload from step 5 (may be nil if that step failed earlier).
    var onFinished: ((Bool, BleDeviceInfoModel?) -> Void)?

    private var steps: [FlowStep] = []
    private var deviceInfo: BleDeviceInfoModel?
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let startButton = UIHelpers.makeButton("", primary: true)
    private let closeButton = UIHelpers.makeButton("")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("bind_title")
        view.backgroundColor = .systemGroupedBackground
        startButton.setTitle(L10n.tr("bind_start"), for: .normal)
        closeButton.setTitle(L10n.tr("close"), for: .normal)
        steps = [
            FlowStep(api: "startBindDevice", description: L10n.tr("bind_step_start"), platformNote: "iOS"),
            FlowStep(api: "setDeviceTime", description: L10n.tr("bind_step_time"), platformNote: nil),
            FlowStep(api: "setUserInfo", description: L10n.tr("bind_step_user"), platformNote: nil),
            FlowStep(api: "setUnit", description: L10n.tr("bind_step_unit"), platformNote: nil),
            FlowStep(api: "setLanguage", description: L10n.tr("bind_step_language"), platformNote: nil),
            FlowStep(api: "getDeviceInfo", description: L10n.tr("bind_step_device_info"), platformNote: L10n.tr("bind_note_local")),
            FlowStep(api: "endBindDevice", description: L10n.tr("bind_step_end"), platformNote: nil),
            FlowStep(api: "getPairState", description: L10n.tr("bind_step_is_bonded"), platformNote: L10n.tr("bind_note_no_create_bond")),
            FlowStep(api: "requestDeviceToPair", description: L10n.tr("bind_step_create_bond"), platformNote: L10n.tr("bind_note_skippable")),
            FlowStep(api: "saveBoundDevice", description: L10n.tr("bind_step_set_bind"), platformNote: nil)
        ]
        table.dataSource = self
        table.register(FlowStepCell.self, forCellReuseIdentifier: FlowStepCell.reuseId)
        table.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(table)
        let controls = UIHelpers.makeCard([UIHelpers.makeGrid([startButton, closeButton])])
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: controls.topAnchor, constant: -12),
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    /// User cancelled before completion — report `success == false`.
    @objc private func close() {
        dismiss(animated: true) { self.onFinished?(false, nil) }
    }

    @objc private func start() {
        startButton.isEnabled = false
        runStep(0)
    }

    /// Executes bind steps sequentially. When `index == steps.count`, dismisses and reports success.
    private func runStep(_ index: Int) {
        guard index < steps.count else {
            dismiss(animated: true) { self.onFinished?(true, self.deviceInfo) }
            return
        }
        mark(index, .running)
        // Hard failure: stop the chain and allow retry.
        let finishHard: (Result<Void, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.mark(index, .done)
                self.runStep(index + 1)
            case .failure(let e):
                self.mark(index, .failed, e.localizedDescription)
                self.startButton.isEnabled = true
            }
        }
        // Soft failure: mark skipped and continue (used for optional pairing).
        let finishSoft: (Result<Void, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success: self.mark(index, .done)
            case .failure(let e): self.mark(index, .skipped, e.localizedDescription)
            }
            self.runStep(index + 1)
        }

        switch index {
        case 0: repo.startBind(completion: finishHard)
        case 1: repo.setDeviceTime(completion: finishHard)
        case 2: repo.setUserInfo(completion: finishHard)
        case 3: repo.setUnitMetric(completion: finishHard)
        case 4: repo.setLanguage(completion: finishHard)
        case 5:
            // Capture device info for Home to persist MAC / firmware after this VC dismisses.
            repo.getDeviceInfo { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let info):
                    self.deviceInfo = info
                    let detail = "type=\(info.type ?? "-") fw=\(info.firmwareVersion ?? "-") bat=\(info.battery ?? -1)"
                    self.mark(index, .done, detail)
                    self.runStep(index + 1)
                case .failure(let e):
                    self.mark(index, .failed, e.localizedDescription)
                    self.startButton.isEnabled = true
                }
            }
        case 6: repo.endBind(completion: finishHard)
        case 7:
            // If already paired, skip `requestDeviceToPair` (step 8).
            repo.getPairState { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let paired):
                    self.mark(index, .done, paired ? L10n.tr("detail_paired") : L10n.tr("detail_not_paired"))
                    if paired {
                        self.mark(8, .skipped, L10n.tr("detail_skip_pair"))
                        self.runStep(9)
                    } else {
                        self.runStep(8)
                    }
                case .failure(let e):
                    self.mark(index, .skipped, e.localizedDescription)
                    self.runStep(8)
                }
            }
        case 8: repo.requestDeviceToPair(completion: finishSoft)
        case 9:
            // UI-only marker; `HomeViewController` writes BoundDeviceStore on success callback.
            mark(index, .done, L10n.tr("detail_save_local"))
            runStep(index + 1)
        default:
            runStep(index + 1)
        }
    }

    private func mark(_ index: Int, _ status: FlowStepStatus, _ detail: String? = nil) {
        steps[index].status = status
        steps[index].detail = detail
        table.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
}

extension BindFlowViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { steps.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FlowStepCell.reuseId, for: indexPath) as! FlowStepCell
        cell.configure(steps[indexPath.row])
        return cell
    }
}
