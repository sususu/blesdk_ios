import UIKit

/// Step-by-step **device unbind** demo screen.
///
/// # Difference vs Android
/// Android can call `removeBond` / clear the system pairing programmatically.
/// **iOS cannot** remove a system Bluetooth pairing from the app. After SDK unbind +
/// disconnect + local cleanup, the user **must** open **Settings → Bluetooth** and tap
/// **Forget This Device** (忽略此设备). This VC shows that prompt (aligned with HaWoFit
/// `PhoneUnpairInfoView`) before reporting success to `HomeViewController`.
///
/// # Pipeline
/// 0. `unbindDevice` — notify watch firmware (soft: continue even if watch already gone)
/// 1. `disconnect` — drop the BLE link (soft)
/// 2. `removeConnectionCache` — clear SDK connection cache (hard)
/// 3. `BoundDeviceStore.clear` — wipe local bind record (hard)
/// 4. UI alert — instruct user to forget the device in system Bluetooth settings
///
/// Home should disable auto-reconnect before presenting this flow.
final class UnbindFlowViewController: UIViewController {
    private let repo = BleRepository.shared
    /// Invoked after dismiss. `true` only when cleanup finished (alert may still have been shown).
    var onFinished: ((Bool) -> Void)?

    private var steps: [FlowStep] = []
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let startButton = UIHelpers.makeButton("", primary: true)
    private let closeButton = UIHelpers.makeButton("")
    /// Banner explaining the iOS-only “forget device” requirement (shown above the table).
    private let iosNoteLabel = UIHelpers.makeLabel("")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("unbind_title")
        view.backgroundColor = .systemGroupedBackground
        startButton.setTitle(L10n.tr("unbind_start"), for: .normal)
        closeButton.setTitle(L10n.tr("close"), for: .normal)
        iosNoteLabel.text = L10n.tr("unbind_ios_banner")
        iosNoteLabel.font = .preferredFont(forTextStyle: .footnote)
        iosNoteLabel.textColor = .secondaryLabel
        iosNoteLabel.numberOfLines = 0
        steps = [
            FlowStep(api: "unbindDevice", description: L10n.tr("unbind_step_unbind"), platformNote: L10n.tr("unbind_note_ios")),
            FlowStep(api: "disconnect", description: L10n.tr("unbind_step_disconnect"), platformNote: nil),
            FlowStep(api: "removeConnectionCache", description: L10n.tr("unbind_step_cache"), platformNote: nil),
            FlowStep(api: "BoundDeviceStore.clear", description: L10n.tr("unbind_step_local"), platformNote: nil),
            FlowStep(api: "system BT forget", description: L10n.tr("unbind_step_forget"), platformNote: L10n.tr("unbind_note_forget"))
        ]
        table.dataSource = self
        table.register(FlowStepCell.self, forCellReuseIdentifier: FlowStepCell.reuseId)
        table.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        iosNoteLabel.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(iosNoteLabel)
        view.addSubview(table)
        let controls = UIHelpers.makeCard([UIHelpers.makeGrid([startButton, closeButton])])
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        NSLayoutConstraint.activate([
            iosNoteLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            iosNoteLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            iosNoteLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            table.topAnchor.constraint(equalTo: iosNoteLabel.bottomAnchor, constant: 8),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: controls.topAnchor, constant: -12),
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    @objc private func close() {
        dismiss(animated: true) { self.onFinished?(false) }
    }

    /// Runs SDK cleanup steps, then presents the iOS “forget device” alert.
    @objc private func start() {
        startButton.isEnabled = false
        soft(0) { done in
            self.repo.unbindDevice(completion: done)
        } then: {
            self.soft(1) { done in
                self.repo.disconnect { err in
                    if let err = err { done(.failure(err)) } else { done(.success(())) }
                }
            } then: {
                self.hard(2) { done in
                    self.repo.removeConnectionCache()
                    done(.success(()))
                } then: {
                    self.hard(3) { done in
                        self.repo.clearBoundDevice()
                        done(.success(()))
                    } then: {
                        // iOS-only UX: Android removeBond has no equivalent here.
                        self.promptForgetDeviceInSystemSettings()
                    }
                }
            }
        }
    }

    /// Shows HaWoFit-style guidance: Settings → Bluetooth → Forget This Device.
    /// “Settings” tries `App-Prefs:Bluetooth` (same as HaWoFit `jumpToBleSetting`);
    /// “Done” finishes the unbind flow.
    private func promptForgetDeviceInSystemSettings() {
        mark(4, .running)
        let alert = UIAlertController(
            title: L10n.tr("unbind_forget_title"),
            message: L10n.tr("unbind_forget_message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("unbind_forget_settings"), style: .default, handler: { [weak self] _ in
            self?.openSystemBluetoothSettings()
            // Keep the alert path: user may return later; still complete unbind after a short delay
            // so Home can reset UI. They can open Settings again from the system if needed.
            self?.mark(4, .done, L10n.tr("unbind_forget_opened_settings"))
            self?.finishSuccessfully()
        }))
        alert.addAction(UIAlertAction(title: L10n.tr("unbind_forget_done"), style: .cancel, handler: { [weak self] _ in
            self?.mark(4, .done, L10n.tr("unbind_forget_user_acked"))
            self?.finishSuccessfully()
        }))
        present(alert, animated: true)
    }

    /// Opens system Bluetooth settings when possible (demo parity with HaWoFit `jumpToBleSetting`).
    /// Falls back to the app’s Settings page if needed.
    private func openSystemBluetoothSettings() {
        // HaWoFit uses `App-Prefs:Bluetooth` directly (canOpenURL is unreliable for this scheme).
        if let bleURL = URL(string: "App-Prefs:Bluetooth") {
            UIApplication.shared.open(bleURL, options: [:]) { opened in
                if !opened, let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }
            return
        }
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }

    private func finishSuccessfully() {
        dismiss(animated: true) { self.onFinished?(true) }
    }

    /// Soft step: failure is marked skipped; chain always continues.
    private func soft(_ index: Int,
                      action: (@escaping (Result<Void, Error>) -> Void) -> Void,
                      then: @escaping () -> Void) {
        mark(index, .running)
        action { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success: self.mark(index, .done)
            case .failure(let e): self.mark(index, .skipped, e.localizedDescription)
            }
            then()
        }
    }

    /// Hard step: failure stops the chain and re-enables Start.
    private func hard(_ index: Int,
                      action: (@escaping (Result<Void, Error>) -> Void) -> Void,
                      then: @escaping () -> Void) {
        mark(index, .running)
        action { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.mark(index, .done)
                then()
            case .failure(let e):
                self.mark(index, .failed, e.localizedDescription)
                self.startButton.isEnabled = true
            }
        }
    }

    private func mark(_ index: Int, _ status: FlowStepStatus, _ detail: String? = nil) {
        steps[index].status = status
        steps[index].detail = detail
        table.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
}

extension UnbindFlowViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { steps.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FlowStepCell.reuseId, for: indexPath) as! FlowStepCell
        cell.configure(steps[indexPath.row])
        return cell
    }
}
