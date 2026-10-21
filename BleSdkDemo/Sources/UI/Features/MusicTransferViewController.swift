import UIKit
import UniformTypeIdentifiers

/// Demo screen for pushing MP3 files to a Sifli (思澈) watch.
///
/// # Flow (aligned with HaWoFit `HwMusicViewController`)
/// 1. Optionally query music storage (`getMusicAvailableStorage`) — SDK returns **KB**.
/// 2. Pick one or more `.mp3` files via `UIDocumentPicker` (`public.mp3` only).
/// 3. Call `BleRepository.pushMusicAuto`, which:
///    - Stages files under a temp `…/selectTemp/music/mp3/` tree
///      (required so `SifliWatchfaceSDK.packageQjsMp3` produces zip entries `music/mp3/*.mp3`;
///      a flat temp folder causes watch error code **22** on single-file start).
///    - Compresses then pushes over BLE via `SifliWatchfaceSDK.setMusicFiles`.
/// 4. Cancel maps to `SifliWatchfaceSDK.stop()` through `BleRepository.cancelTransfer`.
///
/// Classic BT / JL (JieLi) multi-file transfer is **not** used on this screen; iOS demo
/// always takes the Sifli path.
final class MusicTransferViewController: UIViewController, UIDocumentPickerDelegate {
    private let repo = BleRepository.shared
    private let statusLabel = UIHelpers.makeLabel("")
    /// Shows available / total music storage in MB (converted from SDK KB).
    private let storageLabel = UIHelpers.makeLabel("—")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()
    /// Local copies of user-selected MP3 URLs (document picker uses `asCopy: true`).
    private var pickedURLs: [URL] = []
    /// Guards against overlapping push sessions from the UI.
    private var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("music")
        view.backgroundColor = .systemGroupedBackground
        statusLabel.text = L10n.tr("feature_ready")
        let refresh = UIHelpers.makeButton(L10n.tr("music_query_storage"))
        let pick = UIHelpers.makeButton(L10n.tr("music_pick_files"))
        let push = UIHelpers.makeButton(L10n.tr("music_push"), primary: true)
        let cancel = UIHelpers.makeButton(L10n.tr("music_cancel"))
        refresh.addTarget(self, action: #selector(refreshStorage), for: .touchUpInside)
        pick.addTarget(self, action: #selector(pickFiles), for: .touchUpInside)
        push.addTarget(self, action: #selector(pushAuto), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelTransfer), for: .touchUpInside)
        progress.translatesAutoresizingMaskIntoConstraints = false
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        let stack = UIStackView(arrangedSubviews: [
            UIHelpers.makeCard([statusLabel, storageLabel], title: L10n.tr("ui_status")),
            UIHelpers.makeCard([UIHelpers.makeGrid([refresh, pick, push, cancel])], title: L10n.tr("ui_actions")),
            UIHelpers.makeCard([progress], title: L10n.tr("ui_results")),
            UIHelpers.makeLogSection(logView)
        ])
        UIHelpers.installScrollableContent(stack, in: view)
        // Prefetch storage so the user sees capacity before picking files.
        refreshStorage()
    }

    /// Queries device music storage and displays it as `availableMB / totalMB`.
    /// Uses `en_US_POSIX` so the decimal separator is always `.` regardless of locale.
    @objc private func refreshStorage() {
        repo.getMusicStorage { [weak self] result in
            switch result {
            case .success(let s):
                // SDK callback unit is KB; UI shows MB like Android / HaWoFit.
                let availableMb = Double(s.availableKb) / 1024.0
                let totalMb = Double(s.totalKb) / 1024.0
                self?.storageLabel.text = String(
                    format: "%.2fMB / %.2fMB",
                    locale: Locale(identifier: "en_US_POSIX"),
                    availableMb,
                    totalMb
                )
                self?.append(L10n.tr("music_storage_ok_log"))
            case .failure(let e):
                self?.storageLabel.text = L10n.tr("music_storage_fail")
                self?.append(e.localizedDescription)
            }
        }
    }

    /// Opens a document picker restricted to MP3 (`UTType.mp3` / `public.mp3`),
    /// matching HaWoFit which rejects non-MP3 / damaged files before push.
    @objc private func pickFiles() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.mp3], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        pickedURLs = urls
        append(L10n.tr("music_files_selected", urls.count, urls.map { $0.lastPathComponent }.joined(separator: ", ")))
    }

    /// Starts the Sifli music push pipeline (`BleRepository.pushMusicAuto`).
    /// `onReady` fires after zip packaging succeeds; `onProgress` is 0...1.
    @objc private func pushAuto() {
        guard !busy else { return }
        guard !pickedURLs.isEmpty else { append(L10n.tr("music_no_files")); return }
        busy = true
        statusLabel.text = L10n.tr("music_pushing")
        progress.progress = 0
        repo.pushMusicAuto(fileURLs: pickedURLs, onReady: { [weak self] in
            self?.append(L10n.tr("music_ready"))
        }, onProgress: { [weak self] p in
            self?.progress.progress = p
            self?.statusLabel.text = L10n.tr("music_progress", p * 100)
        }, completion: { [weak self] result in
            self?.busy = false
            switch result {
            case .success:
                self?.statusLabel.text = L10n.tr("music_push_ok")
                self?.append(L10n.tr("feature_success"))
                // Capacity changes after a successful push — refresh the storage label.
                self?.refreshStorage()
            case .failure(let e):
                self?.statusLabel.text = L10n.tr("feature_failed")
                self?.append(e.localizedDescription)
            }
        })
    }

    /// Cancels an in-flight Sifli transfer (`stop`) and clears the local busy flag.
    @objc private func cancelTransfer() {
        repo.cancelTransfer()
        busy = false
        statusLabel.text = L10n.tr("music_cancelled")
        append(L10n.tr("music_cancelled"))
    }

    private func append(_ s: String) {
        logView.text = (logView.text ?? "") + s + "\n"
    }
}
