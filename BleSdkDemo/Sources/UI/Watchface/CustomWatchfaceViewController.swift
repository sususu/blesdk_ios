import UIKit
import WatchfaceSDK
import PhotosUI

/// Custom Sifli watchface editor → `SlifiCustomWatchface` + `setCustomWatchface`.
///
/// # Business
/// Builds a QJS custom dial in-app: panel size, optional background, toggled widgets,
/// then asks the SDK to zip and push (dial type **5**, byte-align **true** inside SDK).
///
/// # Flow
/// 1. Pick a size preset (must match the physical panel).
/// 2. Optionally pick a photo background (PHPicker / legacy picker).
/// 3. Toggle widgets (date / week / step / weather / analog pointers).
/// 4. Push → `BleRepository.pushCustomWatchface`.
///
/// # Caveats
/// - `thumbnailImage` is **required** by the SDK; we snapshot the preview, else
///   scale the background, else a solid gray placeholder.
/// - Widget tint must be RGB with alpha = 1 (`WatchfaceImageUtils.rgbTint`).
/// - `Size` has no public memberwise init in this WatchfaceSDK build — use
///   `Size.zero` then set `width` / `height`.
/// - `QjsDotWidget.setCenter` is not publicly patchable here; Dot is added without
///   an explicit center pin when pointers are enabled.
/// - Locks host navigation via `host.setInstalling` for the duration of the push.
final class CustomWatchfaceViewController: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var host: WatchfaceHostViewController?

    private let repo = BleRepository.shared
    private let presets = WatchfaceSizePreset.customDefaults
    private var presetIndex = 0
    private var backgroundImage: UIImage?
    private var busy = false

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let preview = UIView()
    private let previewImage = UIImageView()
    private let statusLabel = UIHelpers.makeLabel("")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let logView = UITextView()

    private let widthField = UITextField()
    private let heightField = UITextField()
    private let cornerField = UITextField()
    private let thumbWField = UITextField()
    private let thumbHField = UITextField()
    private let thumbCornerField = UITextField()
    private let nameField = UITextField()

    private let dateSwitch = UISwitch()
    private let weekSwitch = UISwitch()
    private let stepSwitch = UISwitch()
    private let weatherSwitch = UISwitch()
    private let pointerSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        statusLabel.text = L10n.tr("feature_ready")
        progress.isHidden = true

        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        preview.backgroundColor = .secondarySystemBackground
        preview.layer.masksToBounds = true
        previewImage.contentMode = .scaleAspectFill
        previewImage.clipsToBounds = true
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        preview.addSubview(previewImage)
        NSLayoutConstraint.activate([
            previewImage.topAnchor.constraint(equalTo: preview.topAnchor),
            previewImage.leadingAnchor.constraint(equalTo: preview.leadingAnchor),
            previewImage.trailingAnchor.constraint(equalTo: preview.trailingAnchor),
            previewImage.bottomAnchor.constraint(equalTo: preview.bottomAnchor),
            preview.heightAnchor.constraint(equalToConstant: 220)
        ])

        let preset = UIHelpers.makeButton(L10n.tr("wf_size_preset"))
        preset.addTarget(self, action: #selector(pickPreset), for: .touchUpInside)
        let pick = UIHelpers.makeButton(L10n.tr("wf_pick_bg"))
        pick.addTarget(self, action: #selector(pickBackground), for: .touchUpInside)
        let clear = UIHelpers.makeButton(L10n.tr("wf_clear_bg"))
        clear.addTarget(self, action: #selector(clearBackground), for: .touchUpInside)
        let sync = UIHelpers.makeButton(L10n.tr("wf_push_custom"), primary: true)
        sync.addTarget(self, action: #selector(pushCustom), for: .touchUpInside)

        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemGroupedBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        applyPreset(presets[0])
        nameField.placeholder = L10n.tr("wf_name")
        nameField.text = "custom"
        nameField.borderStyle = .roundedRect
        configureNumericFields()

        content.addArrangedSubview(UIHelpers.makeCard([statusLabel], title: L10n.tr("ui_status")))
        content.addArrangedSubview(UIHelpers.makeCard([preview], title: L10n.tr("ui_preview")))
        content.addArrangedSubview(UIHelpers.makeCard([
            makeFieldRow("W", widthField, "H", heightField),
            makeFieldRow("Corner", cornerField, "Name", nameField),
            makeFieldRow("ThumbW", thumbWField, "ThumbH", thumbHField),
            makeFieldRow("ThumbR", thumbCornerField, "", UIView()),
            makeSwitchRow(L10n.tr("wf_widget_date"), dateSwitch),
            makeSwitchRow(L10n.tr("wf_widget_week"), weekSwitch),
            makeSwitchRow(L10n.tr("wf_widget_step"), stepSwitch),
            makeSwitchRow(L10n.tr("wf_widget_weather"), weatherSwitch),
            makeSwitchRow(L10n.tr("wf_widget_pointer"), pointerSwitch)
        ], title: L10n.tr("ui_parameters")))
        dateSwitch.isOn = true
        weekSwitch.isOn = true
        content.addArrangedSubview(UIHelpers.makeCard([UIHelpers.makeGrid([preset, pick, clear, sync])], title: L10n.tr("ui_actions")))
        content.addArrangedSubview(UIHelpers.makeCard([progress], title: L10n.tr("ui_results")))
        content.addArrangedSubview(UIHelpers.makeLogSection(logView))
        refreshPreviewChrome()
    }

    private func configureNumericFields() {
        [widthField, heightField, cornerField, thumbWField, thumbHField, thumbCornerField].forEach {
            $0.borderStyle = .roundedRect
            $0.keyboardType = .numberPad
            $0.addTarget(self, action: #selector(refreshPreviewChrome), for: .editingChanged)
        }
    }

    private func makeFieldRow(_ a: String, _ fa: UIView, _ b: String, _ fb: UIView) -> UIStackView {
        let la = UILabel(); la.text = a; la.font = .systemFont(ofSize: 12)
        let lb = UILabel(); lb.text = b; lb.font = .systemFont(ofSize: 12)
        let row = UIStackView(arrangedSubviews: [la, fa, lb, fb])
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        return row
    }

    private func makeSwitchRow(_ title: String, _ sw: UISwitch) -> UIStackView {
        let label = UILabel(); label.text = title
        let row = UIStackView(arrangedSubviews: [label, sw])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        return row
    }

    @objc private func pickPreset() {
        let sheet = UIAlertController(title: L10n.tr("wf_size_preset"), message: nil, preferredStyle: .actionSheet)
        for (i, p) in presets.enumerated() {
            sheet.addAction(UIAlertAction(title: p.label, style: .default) { [weak self] _ in
                self?.presetIndex = i
                self?.applyPreset(p)
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        present(sheet, animated: true)
    }

    private func applyPreset(_ p: WatchfaceSizePreset) {
        widthField.text = "\(p.width)"
        heightField.text = "\(p.height)"
        cornerField.text = "\(p.corner)"
        thumbWField.text = "\(p.thumbW)"
        thumbHField.text = "\(p.thumbH)"
        thumbCornerField.text = "\(p.thumbCorner)"
        refreshPreviewChrome()
    }

    /// Scales preview chrome to mimic panel aspect / corner radius.
    @objc private func refreshPreviewChrome() {
        let w = CGFloat(Int(widthField.text ?? "") ?? 466)
        let h = CGFloat(Int(heightField.text ?? "") ?? 466)
        let c = CGFloat(Int(cornerField.text ?? "") ?? 233)
        let ratio = h / max(w, 1)
        preview.constraints.first { $0.firstAttribute == .height }?.constant = min(260, 220 * ratio)
        preview.layer.cornerRadius = c * (220 / max(w, 1))
        previewImage.layer.cornerRadius = preview.layer.cornerRadius
        if let bg = backgroundImage {
            previewImage.image = WatchfaceImageUtils.scaledRoundedBitmap(bg, size: CGSize(width: w, height: h), cornerRadius: c)
        } else {
            previewImage.image = nil
        }
    }

    @objc private func pickBackground() {
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        }
    }

    @objc private func clearBackground() {
        backgroundImage = nil
        refreshPreviewChrome()
    }

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            DispatchQueue.main.async {
                self?.backgroundImage = obj as? UIImage
                self?.refreshPreviewChrome()
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true)
        backgroundImage = info[.originalImage] as? UIImage
        refreshPreviewChrome()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    /// Assembles widgets, ensures thumbnail, then pushes via the repository.
    @objc private func pushCustom() {
        guard !busy else { return }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        let w = Int(widthField.text ?? "") ?? 0
        let h = Int(heightField.text ?? "") ?? 0
        let corner = CGFloat(Int(cornerField.text ?? "") ?? 0)
        let tw = Int(thumbWField.text ?? "") ?? 264
        let th = Int(thumbHField.text ?? "") ?? 264
        let tc = CGFloat(Int(thumbCornerField.text ?? "") ?? 132)
        guard w > 0, h > 0 else {
            append(L10n.tr("wf_err_size"))
            return
        }

        let tint = WatchfaceImageUtils.rgbTint(.white)
        let face = SlifiCustomWatchface(width: w, height: h)
        face.name = (nameField.text?.isEmpty == false) ? nameField.text! : "custom"
        if let bg = backgroundImage {
            face.backgroundImage = WatchfaceImageUtils.scaledRoundedBitmap(bg, size: CGSize(width: w, height: h), cornerRadius: corner)
        }
        // Thumbnail is required: preview snapshot → scaled bg → solid gray.
        if let thumb = WatchfaceImageUtils.snapshot(preview, size: CGSize(width: tw, height: th), cornerRadius: tc) {
            face.thumbnailImage = thumb
        } else if let bg = backgroundImage {
            face.thumbnailImage = WatchfaceImageUtils.scaledRoundedBitmap(bg, size: CGSize(width: tw, height: th), cornerRadius: tc)
        } else {
            let solid = UIGraphicsImageRenderer(size: CGSize(width: tw, height: th)).image { ctx in
                UIColor.darkGray.setFill()
                ctx.fill(CGRect(origin: .zero, size: CGSize(width: tw, height: th)))
            }
            face.thumbnailImage = solid
        }

        // Digital time is always present as the layout anchor for other widgets.
        let time = QjsTimeWidget(tintColor: tint)
        time.x = max(0, (w - time.width) / 2)
        time.y = max(0, h / 2 - time.height / 2 - 20)
        face.addWidget(time)

        if dateSwitch.isOn {
            let date = QjsDateWidget(tintColor: tint)
            date.x = max(0, (w - date.width) / 2)
            date.y = time.y + time.height + 8
            face.addWidget(date)
        }
        if weekSwitch.isOn {
            let week = QjsWeekWidget(tintColor: tint)
            week.x = max(0, (w - week.width) / 2)
            week.y = time.y - week.height - 8
            face.addWidget(week)
        }
        if stepSwitch.isOn {
            let step = QjsStepWidget(tintColor: tint)
            step.x = max(0, (w - step.width) / 2)
            step.y = h - step.height - 24
            face.addWidget(step)
        }
        if weatherSwitch.isOn {
            let weather = QjsWeatherTAWidget(tintColor: tint)
            weather.x = 24
            weather.y = 24
            face.addWidget(weather)
        }
        if pointerSwitch.isOn {
            // Size memberwise init is internal — mutate Size.zero instead.
            var size = Size.zero
            size.width = w
            size.height = h
            let hour = QjsHourPointerWidget(size, tintColor: tint)
            let minute = QjsMinutePointerWidget(size, tintColor: tint)
            let second = QjsSecondPointerWidget(size, tintColor: tint)
            face.addWidget(hour)
            face.addWidget(minute)
            face.addWidget(second)
            // Dot center setter is internal in this WatchfaceSDK build — skip center pin.
            face.addWidget(QjsDotWidget(tintColor: tint))
        }

        busy = true
        host?.setInstalling(true)
        progress.isHidden = false
        progress.progress = 0
        statusLabel.text = L10n.tr("wf_pushing")
        append(L10n.tr("wf_push_custom_start", face.name, w, h))

        repo.pushCustomWatchface(face, onCompress: { [weak self] ok in
            self?.append(ok ? L10n.tr("wf_zip_ok") : L10n.tr("wf_zip_fail"))
        }, onProgress: { [weak self] p in
            self?.progress.progress = p
            self?.statusLabel.text = L10n.tr("wf_progress", Int(p * 100))
        }, completion: { [weak self] result in
            guard let self = self else { return }
            self.busy = false
            self.host?.setInstalling(false)
            switch result {
            case .success:
                self.statusLabel.text = L10n.tr("wf_install_ok")
                self.append(L10n.tr("wf_install_ok"))
                self.progress.progress = 1
            case .failure(let e):
                self.statusLabel.text = L10n.tr("wf_install_fail")
                self.append(e.localizedDescription)
            }
        })
    }

    private func append(_ s: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logView.text = (logView.text ?? "") + "\(ts)  \(s)\n"
    }
}
