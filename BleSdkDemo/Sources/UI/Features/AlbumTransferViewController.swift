import UIKit
import PhotosUI

/// Demo screen for pushing album photos to a Sifli (思澈) watch.
///
/// # Flow (aligned with HaWoFit `HwAlbumViewController` / `HwAlbumService`)
/// 1. Optionally query occupied album slot IDs (`getAlbumFilesIdList`).
/// 2. Edit **target width × height** (default **466×466**). Production apps should use
///    the product’s real display size; this demo exposes the fields for experimentation.
/// 3. Pick up to 10 photos via `PHPickerViewController`.
/// 4. Call `BleRepository.pushAlbumAuto`, which:
///    - Aspect-fill + center-crops each image to the target size (APP does this before push;
///      Sifli SDK’s own `resizeImage` only **fits** and may not fill the screen).
///    - Allocates free slot indices in `1...50` that are not already on the watch.
///    - Sets `SifliWatchfaceSDK.width/height` and pushes via `setPictures`.
/// 5. Cancel maps to `SifliWatchfaceSDK.stop()` through `BleRepository.cancelTransfer`.
///
/// JL (JieLi) multi-file album transfer exists in the repository for parity but is not
/// invoked from this screen.
final class AlbumTransferViewController: UIViewController, PHPickerViewControllerDelegate, UITextFieldDelegate {
    private let repo = BleRepository.shared
    private let statusLabel = UIHelpers.makeLabel("")
    private let infoLabel = UIHelpers.makeLabel("")
    /// Editable target width in pixels (default 466).
    private let widthField = UITextField()
    /// Editable target height in pixels (default 466).
    private let heightField = UITextField()
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()
    /// Photos loaded from the picker (original orientation / size before crop).
    private var images: [UIImage] = []
    /// Guards against overlapping push sessions from the UI.
    private var busy = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("album")
        view.backgroundColor = .systemGroupedBackground
        statusLabel.text = L10n.tr("feature_ready")
        infoLabel.text = L10n.tr("album_none_selected")

        // Target size row — values are passed into pushAlbumAuto / SifliWatchfaceSDK.
        let sizeTitle = UIHelpers.makeLabel(L10n.tr("album_target_size_title"))
        sizeTitle.font = .preferredFont(forTextStyle: .subheadline)
        sizeTitle.textColor = .secondaryLabel
        configureSizeField(widthField, placeholder: L10n.tr("album_width"), defaultValue: 466)
        configureSizeField(heightField, placeholder: L10n.tr("album_height"), defaultValue: 466)
        let xLabel = UIHelpers.makeLabel("×")
        xLabel.textAlignment = .center
        xLabel.setContentHuggingPriority(.required, for: .horizontal)
        let sizeRow = UIStackView(arrangedSubviews: [widthField, xLabel, heightField])
        sizeRow.axis = .horizontal
        sizeRow.spacing = 8
        sizeRow.alignment = .center
        widthField.widthAnchor.constraint(equalTo: heightField.widthAnchor).isActive = true

        let ids = UIHelpers.makeButton(L10n.tr("album_query_ids"))
        let pick = UIHelpers.makeButton(L10n.tr("album_pick_files"))
        let push = UIHelpers.makeButton(L10n.tr("album_push"), primary: true)
        let cancel = UIHelpers.makeButton(L10n.tr("album_cancel"))
        ids.addTarget(self, action: #selector(queryIds), for: .touchUpInside)
        pick.addTarget(self, action: #selector(pickImages), for: .touchUpInside)
        push.addTarget(self, action: #selector(pushAuto), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelTransfer), for: .touchUpInside)
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        let stack = UIStackView(arrangedSubviews: [
            UIHelpers.makeCard([statusLabel, infoLabel], title: L10n.tr("ui_status")),
            UIHelpers.makeCard([sizeTitle, sizeRow], title: L10n.tr("ui_parameters")),
            UIHelpers.makeCard([UIHelpers.makeGrid([ids, pick, push, cancel])], title: L10n.tr("ui_actions")),
            UIHelpers.makeCard([progress], title: L10n.tr("ui_results")),
            UIHelpers.makeLogSection(logView)
        ])
        UIHelpers.installScrollableContent(stack, in: view)
        widthField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        heightField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // Dismiss the number pad when tapping outside the size fields.
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    /// Configures a numeric text field used for target width or height.
    private func configureSizeField(_ field: UITextField, placeholder: String, defaultValue: Int) {
        field.placeholder = placeholder
        field.text = "\(defaultValue)"
        field.keyboardType = .numberPad
        field.borderStyle = .roundedRect
        field.textAlignment = .center
        field.delegate = self
        field.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        field.accessibilityLabel = placeholder
    }

    @objc private func endEditingTap() {
        view.endEditing(true)
    }

    /// Parses and validates the width/height fields.
    /// - Returns: A positive size with each side in `1...4096`, or `nil` if invalid.
    private func resolvedTargetSize() -> CGSize? {
        let w = Int(widthField.text?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
        let h = Int(heightField.text?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
        guard w > 0, h > 0, w <= 4096, h <= 4096 else { return nil }
        return CGSize(width: w, height: h)
    }

    /// Lists album file / slot IDs currently stored on the watch (used to avoid collisions).
    @objc private func queryIds() {
        repo.getAlbumFileIds { [weak self] result in
            switch result {
            case .success(let ids):
                self?.append(L10n.tr("album_ids_log", "\(ids)"))
            case .failure(let e):
                self?.append(e.localizedDescription)
            }
        }
    }

    /// Presents the system photo picker (images only, max 10).
    @objc private func pickImages() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 10
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Loads `UIImage`s from picker results asynchronously, then updates the selection label.
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        images.removeAll()
        let group = DispatchGroup()
        for r in results {
            group.enter()
            r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                if let img = obj as? UIImage { self.images.append(img) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.infoLabel.text = L10n.tr("album_selected_count", self.images.count)
            self.append(L10n.tr("album_files_selected", self.images.count))
        }
    }

    /// Validates size + selection, then starts `pushAlbumAuto` with the user-chosen resolution.
    @objc private func pushAuto() {
        guard !busy else { return }
        guard !images.isEmpty else { append(L10n.tr("album_no_files")); return }
        guard let size = resolvedTargetSize() else {
            append(L10n.tr("album_invalid_size"))
            return
        }
        view.endEditing(true)
        busy = true
        statusLabel.text = L10n.tr("album_pushing")
        progress.progress = 0
        append(L10n.tr("album_resize_log", Int(size.width), Int(size.height)))
        repo.pushAlbumAuto(images: images, size: size, onReady: { [weak self] in
            self?.append(L10n.tr("album_ready"))
        }, onProgress: { [weak self] p in
            self?.progress.progress = p
            self?.statusLabel.text = L10n.tr("album_progress", p * 100)
        }, completion: { [weak self] result in
            self?.busy = false
            switch result {
            case .success:
                self?.statusLabel.text = L10n.tr("feature_success")
                self?.append(L10n.tr("album_push_ok"))
                // Slot list changes after a successful push.
                self?.queryIds()
            case .failure(let e):
                self?.statusLabel.text = L10n.tr("feature_failed")
                self?.append(e.localizedDescription)
            }
        })
    }

    /// Cancels an in-flight Sifli transfer and clears the local busy flag.
    @objc private func cancelTransfer() {
        repo.cancelTransfer()
        busy = false
        statusLabel.text = L10n.tr("album_cancelled")
        append(L10n.tr("album_cancelled"))
    }

    private func append(_ s: String) {
        logView.text = (logView.text ?? "") + s + "\n"
    }

    /// Restricts size fields to decimal digits only.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
