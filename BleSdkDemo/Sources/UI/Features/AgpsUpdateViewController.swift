import UIKit

/// Formats AGPS validity windows for the UI.
/// Input timestamps are **milliseconds** since Unix epoch (see `BleRepository.getDeviceGpsStatus`,
/// which normalizes SDK second-scale values to ms).
enum AgpsTimeFormatter {
    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale.current
        return f
    }()

    /// Builds a localized “start – end” string, or an “expired” variant when `endMs` is in the past.
    static func formatRange(startMs: Int64, endMs: Int64) -> String {
        if startMs <= 0 && endMs <= 0 { return L10n.tr("agps_valid_unknown") }
        let start = startMs > 0 ? dateFmt.string(from: Date(timeIntervalSince1970: TimeInterval(startMs) / 1000.0)) : "-"
        let end = endMs > 0 ? dateFmt.string(from: Date(timeIntervalSince1970: TimeInterval(endMs) / 1000.0)) : "-"
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        if endMs > 0 && endMs < nowMs {
            return L10n.tr("agps_valid_expired", start, end)
        }
        return L10n.tr("agps_valid_range", start, end)
    }
}

/// Demo screen for downloading, packaging, and pushing AGPS assistance data to a Sifli watch.
///
/// # End-to-end flow (aligned with Android `AgpsXywBuilder` + HaWoFit AGPS update)
/// 1. **Refresh status** — `getDeviceGpsStatus` shows clip type, firmware, and AGPS validity.
/// 2. **Start update**:
///    - `AgpsXywBuilder.buildSevenDayZip` downloads 5 constellation `.pgl` files,
///      appends a 16-byte `AGPS` trailer (valid start/end UTC seconds), and zips them
///      under the entry prefix `music/gps/agps/` (required by the watch).
///    - Progress for the build phase is mapped roughly to the first half of the bar (0...0.5).
///    - `BleRepository.pushAgpsZip` sends the zip via `SifliWatchfaceSDK.syncZipFile`
///      (`type: 3`, `byteAlign: true`). Push progress fills the second half of the bar.
/// 3. **Cancel** — `BleRepository.cancelTransfer` → `SifliWatchfaceSDK.stop()`.
///
/// Requires a live BLE connection; ATS / cleartext HTTP for the AGPS host must be allowed
/// in Info.plist for the download step.
final class AgpsUpdateViewController: UIViewController {
    private let repo = BleRepository.shared
    private let statusLabel = UIHelpers.makeLabel("")
    private let clipLabel = UIHelpers.makeLabel("")
    private let fwLabel = UIHelpers.makeLabel("")
    private let validLabel = UIHelpers.makeLabel("")
    private let progress = UIProgressView(progressViewStyle: .default)
    /// High-level phase text: downloading / packaging / pushing / done.
    private let phaseLabel = UIHelpers.makeLabel("")
    private let logView = UITextView()
    /// Guards against overlapping download+push sessions.
    private var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("agps")
        view.backgroundColor = .systemGroupedBackground
        statusLabel.text = L10n.tr("feature_ready")
        clipLabel.text = L10n.tr("agps_gps_clip", "-")
        fwLabel.text = L10n.tr("agps_gps_fw", "-", 0)
        validLabel.text = L10n.tr("agps_valid_dash")
        let refresh = UIHelpers.makeButton(L10n.tr("agps_refresh_status"))
        let start = UIHelpers.makeButton(L10n.tr("agps_start"), primary: true)
        let cancel = UIHelpers.makeButton(L10n.tr("agps_cancel"))
        refresh.addTarget(self, action: #selector(refreshStatus), for: .touchUpInside)
        start.addTarget(self, action: #selector(startUpdate), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelUpdate), for: .touchUpInside)
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        let stack = UIStackView(arrangedSubviews: [
            UIHelpers.makeCard([statusLabel, clipLabel, fwLabel, validLabel], title: L10n.tr("ui_status")),
            UIHelpers.makeCard([UIHelpers.makeGrid([refresh, start, cancel])], title: L10n.tr("ui_actions")),
            UIHelpers.makeCard([phaseLabel, progress], title: L10n.tr("ui_results")),
            UIHelpers.makeLogSection(logView)
        ])
        UIHelpers.installScrollableContent(stack, in: view)
        refreshStatus()
    }

    /// Reads GPS / AGPS status from the connected watch and updates the status labels.
    @objc private func refreshStatus() {
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        repo.getDeviceGpsStatus { [weak self] result in
            switch result {
            case .success(let gps):
                self?.clipLabel.text = L10n.tr("agps_gps_clip", gps.gpsClipType ?? "-")
                self?.fwLabel.text = L10n.tr("agps_gps_fw", gps.gpsFirmwareVersion ?? "-", gps.gpsFirmwareBuild)
                self?.validLabel.text = AgpsTimeFormatter.formatRange(
                    startMs: gps.agpsValidStartTimeMs,
                    endMs: gps.agpsValidEndTimeMs
                )
                self?.append(L10n.tr("agps_status_ok_log"))
                self?.statusLabel.text = L10n.tr("agps_status_ok")
            case .failure(let e):
                self?.append(e.localizedDescription)
                self?.statusLabel.text = L10n.tr("agps_status_fail")
            }
        }
    }

    /// Downloads + packages AGPS files, then pushes the resulting zip over BLE.
    ///
    /// Progress bar mapping:
    /// - `0.0 ... 0.5` — `AgpsXywBuilder` download / trailer / zip
    /// - `0.5 ... 1.0` — Sifli `syncZipFile` push (`p` is typically 0...100)
    @objc private func startUpdate() {
        guard !busy else { return }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        busy = true
        progress.progress = 0
        phaseLabel.text = L10n.tr("agps_phase_download")
        statusLabel.text = L10n.tr("agps_preparing")
        // Unique temp directory per run so parallel / retry runs do not clash.
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("agps_\(UUID().uuidString)", isDirectory: true)
        AgpsXywBuilder.buildSevenDayZip(into: dir, onProgress: { [weak self] p in
            DispatchQueue.main.async {
                self?.progress.progress = p.fraction
                self?.phaseLabel.text = p.message
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e):
                self.busy = false
                self.statusLabel.text = L10n.tr("agps_build_fail")
                self.append(e.localizedDescription)
            case .success(let built):
                self.append(L10n.tr(
                    "agps_zip_ready",
                    built.zipURL.lastPathComponent,
                    built.validStartTimeMs,
                    built.validEndTimeMs
                ))
                self.phaseLabel.text = L10n.tr("agps_phase_push")
                self.statusLabel.text = L10n.tr("agps_pushing")
                self.repo.pushAgpsZip(zipURL: built.zipURL, onProgress: { [weak self] p in
                    // Map SDK 0...100 onto the second half of the progress bar.
                    self?.progress.progress = 0.5 + Float(p) / 200.0
                    self?.statusLabel.text = L10n.tr("agps_push_progress", p)
                }, completion: { [weak self] pushResult in
                    self?.busy = false
                    switch pushResult {
                    case .success:
                        self?.statusLabel.text = L10n.tr("agps_push_ok")
                        self?.phaseLabel.text = L10n.tr("agps_phase_done")
                        self?.progress.progress = 1
                        self?.append(L10n.tr("agps_push_ok"))
                        // Validity window should update after a successful push.
                        self?.refreshStatus()
                    case .failure(let e):
                        self?.statusLabel.text = L10n.tr("agps_push_fail")
                        self?.append(e.localizedDescription)
                    }
                })
            }
        })
    }

    /// Aborts an in-flight Sifli AGPS push (does not cancel an already-finished download).
    @objc private func cancelUpdate() {
        repo.cancelTransfer()
        busy = false
        statusLabel.text = L10n.tr("agps_cancelled")
        append(L10n.tr("agps_cancelled"))
    }

    private func append(_ s: String) {
        logView.text = (logView.text ?? "") + s + "\n"
    }
}
