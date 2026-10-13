import AVFoundation
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import WatchfaceSDK
import CoreText

/// Watch Face Studio — Sifli QJS dial demo (aligned with Android `WatchFaceStudioFragment`).
///
/// Push path: `SlifiCustomWatchface` → `BleRepository.pushCustomWatchface`
/// (dial type **5**, byte-align **true**). Background: Album / Camera / Video→GIF
/// (HaWoFit-aligned params via `StudioVideoToGif`).
final class WatchFaceStudioViewController: UIViewController,
    PHPickerViewControllerDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    private enum PickMode { case image, video }

    private let repo = BleRepository.shared
    private let presets = WatchfaceSizePreset.customDefaults
    private var presetIndex = 0
    private var backgroundImage: UIImage?
    private var backgroundGifURL: URL?
    private var busy = false
    private var pickMode: PickMode = .image
    private var fontIndex = 1 // default Roboto

    private let fontSizeChoices = [16, 18, 20, 22, 24, 26, 28, 30, 32, 36, 40, 44, 48, 56]

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let previewHost = UIView()
    private let preview = UIView()
    private let previewImage = UIImageView()
    private let previewOverlay = UIView()
    private let statusLabel = UIHelpers.makeLabel("")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let sizeButton = UIHelpers.makeButton("")
    private let nameField = UITextField()
    private let syncButton = UIHelpers.makeButton("", primary: true)
    private let fontButton = UIHelpers.makeButton("")

    private let pointerSwitch = UISwitch()
    private let hourWell = UIColorWell()
    private let minuteWell = UIColorWell()
    private let secondWell = UIColorWell()
    private let dotWell = UIColorWell()

    private let linkPhoneSwitch = UISwitch()
    private let linkNotifySwitch = UISwitch()
    private let linkActivitySwitch = UISwitch()
    private let linkWeatherSwitch = UISwitch()

    private var widgetRows: [WidgetStyleRow] = []
    private var previewWidthConstraint: NSLayoutConstraint?
    private var previewHeightConstraint: NSLayoutConstraint?

    private final class WidgetStyleRow {
        let key: String
        let titleKey: String
        let defaultColor: UIColor
        let sample: String
        let sw: UISwitch
        let well: UIColorWell
        let sizeButton: UIButton
        let preview: UILabel
        var fontSizePx: Int

        init(key: String, titleKey: String, defaultColor: UIColor, sample: String, fontSizePx: Int, previewHost: UIView) {
            self.key = key
            self.titleKey = titleKey
            self.defaultColor = defaultColor
            self.sample = sample
            self.fontSizePx = fontSizePx
            sw = UISwitch()
            sw.isOn = true
            well = UIColorWell()
            well.selectedColor = defaultColor
            sizeButton = UIButton(type: .system)
            sizeButton.setTitle("\(fontSizePx) ▾", for: .normal)
            sizeButton.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            sizeButton.backgroundColor = .tertiarySystemFill
            sizeButton.layer.cornerRadius = 8
            sizeButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            sizeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
            preview = UILabel()
            preview.text = sample
            preview.textAlignment = .center
            preview.font = .systemFont(ofSize: 11, weight: .semibold)
            preview.textColor = defaultColor
            preview.adjustsFontSizeToFitWidth = true
            preview.isHidden = true
            previewHost.addSubview(preview)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        StudioFontRegistry.registerBundledFonts()
        statusLabel.text = L10n.tr("wfs_ready")
        progress.isHidden = true

        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -12),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -12),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -24)
        ])

        setupPreview()
        setupWidgetRows()
        buildForm()
        applyLocalizedChrome()
        refreshPreview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLocalizedChrome()
    }

    private func setupPreview() {
        // Fixed-aspect dial centered in host (Android uses ~300dp box). Full-width
        // stretch made sx ≠ sy and warped all overlay widgets.
        previewHost.translatesAutoresizingMaskIntoConstraints = false
        previewHost.heightAnchor.constraint(equalToConstant: 300).isActive = true

        preview.backgroundColor = .black
        preview.layer.masksToBounds = true
        preview.translatesAutoresizingMaskIntoConstraints = false
        previewImage.contentMode = .scaleAspectFill
        previewImage.clipsToBounds = true
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewOverlay.translatesAutoresizingMaskIntoConstraints = false
        previewOverlay.isUserInteractionEnabled = false
        previewHost.addSubview(preview)
        preview.addSubview(previewImage)
        preview.addSubview(previewOverlay)
        let w = preview.widthAnchor.constraint(equalToConstant: 300)
        let h = preview.heightAnchor.constraint(equalToConstant: 300)
        previewWidthConstraint = w
        previewHeightConstraint = h
        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: previewHost.centerXAnchor),
            preview.centerYAnchor.constraint(equalTo: previewHost.centerYAnchor),
            w, h,
            previewImage.topAnchor.constraint(equalTo: preview.topAnchor),
            previewImage.leadingAnchor.constraint(equalTo: preview.leadingAnchor),
            previewImage.trailingAnchor.constraint(equalTo: preview.trailingAnchor),
            previewImage.bottomAnchor.constraint(equalTo: preview.bottomAnchor),
            previewOverlay.topAnchor.constraint(equalTo: preview.topAnchor),
            previewOverlay.leadingAnchor.constraint(equalTo: preview.leadingAnchor),
            previewOverlay.trailingAnchor.constraint(equalTo: preview.trailingAnchor),
            previewOverlay.bottomAnchor.constraint(equalTo: preview.bottomAnchor),
        ])
    }

    private func setupWidgetRows() {
        let defs: [(String, String, UIColor, String, Int)] = [
            ("date", "wfs_enable_date", .white, "03/15", 40),
            ("week", "wfs_enable_week", .white, "MON", 40),
            ("step", "wfs_enable_step", UIColor(red: 1, green: 0, blue: 0, alpha: 1), "12345", 26),
            ("distance", "wfs_enable_distance", UIColor(red: 0.33, green: 0.67, blue: 1, alpha: 1), "3.2", 26),
            ("calorie", "wfs_enable_calorie", UIColor(red: 1, green: 0.67, blue: 0, alpha: 1), "256", 26),
            ("battery", "wfs_enable_battery", UIColor(red: 0.33, green: 1, blue: 0.33, alpha: 1), "86%", 26),
            ("hr", "wfs_enable_hr", UIColor(red: 1, green: 0.4, blue: 0.67, alpha: 1), "72", 26),
            ("weather", "wfs_enable_weather", .white, "22°", 26),
        ]
        widgetRows = defs.map { key, titleKey, color, sample, size in
            let row = WidgetStyleRow(
                key: key, titleKey: titleKey, defaultColor: color,
                sample: sample, fontSizePx: size, previewHost: previewOverlay
            )
            row.sw.addTarget(self, action: #selector(schedulePreviewRefresh), for: .valueChanged)
            row.well.addTarget(self, action: #selector(schedulePreviewRefresh), for: .valueChanged)
            row.sizeButton.addTarget(self, action: #selector(cycleFontSize(_:)), for: .touchUpInside)
            row.sizeButton.tag = widgetRows.count // fixed below
            return row
        }
        for (i, row) in widgetRows.enumerated() { row.sizeButton.tag = i }
    }

    private func buildForm() {
        sizeButton.addTarget(self, action: #selector(pickPreset), for: .touchUpInside)
        sizeButton.setTitle(currentPreset.label, for: .normal)

        nameField.borderStyle = .roundedRect
        nameField.text = "studio"
        nameField.placeholder = L10n.tr("wfs_name")
        nameField.font = .systemFont(ofSize: 14)
        nameField.clearButtonMode = .whileEditing

        fontButton.addTarget(self, action: #selector(pickFont), for: .touchUpInside)

        let album = UIHelpers.makeButton(L10n.tr("wfs_album"))
        album.addTarget(self, action: #selector(pickAlbum), for: .touchUpInside)
        let camera = UIHelpers.makeButton(L10n.tr("wfs_camera"))
        camera.addTarget(self, action: #selector(pickCamera), for: .touchUpInside)
        let video = UIHelpers.makeButton(L10n.tr("wfs_video"))
        video.addTarget(self, action: #selector(pickVideo), for: .touchUpInside)
        let clear = UIHelpers.makeButton(L10n.tr("wfs_clear_bg"))
        clear.addTarget(self, action: #selector(clearBackground), for: .touchUpInside)
        syncButton.addTarget(self, action: #selector(syncToWatch), for: .touchUpInside)

        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(sectionLabel(L10n.tr("wfs_preview")))
        content.addArrangedSubview(previewHost)

        // Size + Name on one row (Android spinner + TextInputLayout)
        let sizeNameRow = UIStackView(arrangedSubviews: [sizeButton, nameField])
        sizeNameRow.axis = .horizontal
        sizeNameRow.spacing = 8
        sizeNameRow.distribution = .fillEqually
        sizeNameRow.alignment = .center
        content.addArrangedSubview(sizeNameRow)

        content.addArrangedSubview(sectionLabel(L10n.tr("wfs_font_label")))
        content.addArrangedSubview(fontButton)
        content.addArrangedSubview(sectionLabel(L10n.tr("wfs_section_bg")))
        // Android/HaWoFit: Album / Camera / Video (+ Clear)
        content.addArrangedSubview(makeRow([album, camera, video]))
        content.addArrangedSubview(clear)
        content.addArrangedSubview(sectionLabel(L10n.tr("wfs_section_widgets")))
        for row in widgetRows {
            content.addArrangedSubview(makeWidgetRow(row))
        }

        // Pointers: switch + title + 4 color wells always visible (Android layout)
        pointerSwitch.isOn = false
        pointerSwitch.addTarget(self, action: #selector(schedulePreviewRefresh), for: .valueChanged)
        hourWell.selectedColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        minuteWell.selectedColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        secondWell.selectedColor = UIColor(red: 0.63, green: 1, blue: 0.33, alpha: 1)
        dotWell.selectedColor = .white
        [hourWell, minuteWell, secondWell, dotWell].forEach {
            $0.supportsAlpha = false
            $0.addTarget(self, action: #selector(schedulePreviewRefresh), for: .valueChanged)
        }
        content.addArrangedSubview(makePointerRow())

        content.addArrangedSubview(sectionLabel(L10n.tr("wfs_section_links")))
        for (titleKey, sw) in [
            ("wfs_link_phone", linkPhoneSwitch),
            ("wfs_link_notify", linkNotifySwitch),
            ("wfs_link_activity", linkActivitySwitch),
            ("wfs_link_weather", linkWeatherSwitch),
        ] as [(String, UISwitch)] {
            sw.isOn = false
            sw.addTarget(self, action: #selector(schedulePreviewRefresh), for: .valueChanged)
            content.addArrangedSubview(makeSwitchRow(L10n.tr(titleKey), sw))
        }

        content.addArrangedSubview(syncButton)
        content.addArrangedSubview(progress)
    }

    private func applyLocalizedChrome() {
        title = L10n.tr("feature_watchface_studio")
        nameField.placeholder = L10n.tr("wfs_name")
        sizeButton.setTitle(currentPreset.label, for: .normal)
        syncButton.setTitle(L10n.tr("wfs_sync"), for: .normal)
        fontButton.setTitle(fontTitle(fontIndex), for: .normal)
        for row in widgetRows {
            if let stack = row.sw.superview as? UIStackView {
                for v in stack.arrangedSubviews {
                    if let label = v as? UILabel { label.text = L10n.tr(row.titleKey); break }
                }
            }
            row.sizeButton.setTitle("\(row.fontSizePx) ▾", for: .normal)
        }
    }

    private func fontTitle(_ index: Int) -> String {
        switch index {
        case 1: return L10n.tr("wfs_font_roboto")
        case 2: return L10n.tr("wfs_font_montserrat")
        default: return L10n.tr("wfs_font_default")
        }
    }

    private func currentGlyphFont() -> UIFont {
        switch fontIndex {
        case 1:
            return StudioFontRegistry.font(file: "roboto_bold", size: 26)
                ?? .systemFont(ofSize: 26, weight: .bold)
        case 2:
            return StudioFontRegistry.font(file: "montserrat_bold", size: 26)
                ?? .systemFont(ofSize: 26, weight: .bold)
        default:
            return .systemFont(ofSize: 26, weight: .bold)
        }
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeRow(_ buttons: [UIButton]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: buttons)
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        return row
    }

    private func makeSwitchRow(_ title: String, _ sw: UISwitch) -> UIStackView {
        // Switch immediately left of title (Android checkbox+text).
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sw.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [sw, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    private func makeWidgetRow(_ row: WidgetStyleRow) -> UIStackView {
        // [switch][name] ........ [color][font size ▾]
        let label = UILabel()
        label.text = L10n.tr(row.titleKey)
        label.font = .systemFont(ofSize: 14)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.sw.setContentHuggingPriority(.required, for: .horizontal)
        row.well.supportsAlpha = false
        row.well.setContentHuggingPriority(.required, for: .horizontal)
        row.sizeButton.setContentHuggingPriority(.required, for: .horizontal)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [row.sw, label, spacer, row.well, row.sizeButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }

    private func makePointerRow() -> UIStackView {
        let label = UILabel()
        label.text = L10n.tr("wfs_enable_pointers")
        label.font = .systemFont(ofSize: 14)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pointerSwitch.setContentHuggingPriority(.required, for: .horizontal)
        let spacer = UIView()
        let wells = UIStackView(arrangedSubviews: [hourWell, minuteWell, secondWell, dotWell])
        wells.axis = .horizontal
        wells.spacing = 6
        wells.alignment = .center
        wells.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [pointerSwitch, label, spacer, wells])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    private var currentPreset: WatchfaceSizePreset { presets[presetIndex] }

    private struct LayoutInsets {
        let side: Int; let top: Int; let bottom: Int; let link: Int; let timeY: Int
    }

    private func layoutInsets(width: Int, height: Int, corner: Int) -> LayoutInsets {
        let round = width == height && corner >= width / 2 - 2
        if round {
            let m = Int(CGFloat(width) * 0.17).clamped(to: 64...120)
            return LayoutInsets(
                side: m, top: m, bottom: m,
                link: Int(CGFloat(width) * 0.12).clamped(to: 40...80),
                timeY: Int(CGFloat(width) * 0.15).clamped(to: 56...100)
            )
        }
        return LayoutInsets(side: 40, top: 20, bottom: 40, link: 16, timeY: 60)
    }

    @objc private func pickPreset() {
        let sheet = UIAlertController(title: L10n.tr("wf_size_preset"), message: nil, preferredStyle: .actionSheet)
        for (i, p) in presets.enumerated() {
            let mark = i == presetIndex ? " ✓" : ""
            sheet.addAction(UIAlertAction(title: p.label + mark, style: .default) { [weak self] _ in
                guard let self else { return }
                self.presetIndex = i
                self.sizeButton.setTitle(p.label, for: .normal)
                self.refreshPreview()
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sizeButton
            pop.sourceRect = sizeButton.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func pickFont() {
        let sheet = UIAlertController(title: L10n.tr("wfs_font_label"), message: nil, preferredStyle: .actionSheet)
        for i in 0..<3 {
            sheet.addAction(UIAlertAction(title: fontTitle(i), style: .default) { [weak self] _ in
                self?.fontIndex = i
                self?.fontButton.setTitle(self?.fontTitle(i), for: .normal)
                self?.refreshPreview()
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        present(sheet, animated: true)
    }

    @objc private func cycleFontSize(_ sender: UIButton) {
        guard widgetRows.indices.contains(sender.tag) else { return }
        let row = widgetRows[sender.tag]
        let sheet = UIAlertController(title: L10n.tr("wfs_font_label"), message: nil, preferredStyle: .actionSheet)
        for px in fontSizeChoices {
            let mark = px == row.fontSizePx ? " ✓" : ""
            sheet.addAction(UIAlertAction(title: "\(px) px\(mark)", style: .default) { [weak self] _ in
                row.fontSizePx = px
                row.sizeButton.setTitle("\(px) ▾", for: .normal)
                self?.refreshPreview()
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func pickAlbum() { presentPicker(mode: .image) }

    @objc private func pickCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            statusLabel.text = L10n.tr("wfs_camera_unavailable")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image"]
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    /// HaWoFit: photo library movie → Video→GIF (min 2s).
    @objc private func pickVideo() {
        // Prefer UIImagePickerController like HaWoFit `openImagePickerController`.
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.delegate = self
            picker.modalPresentationStyle = .fullScreen
            present(picker, animated: true)
            return
        }
        presentPicker(mode: .video)
    }

    private func presentPicker(mode: PickMode) {
        pickMode = mode
        var config = PHPickerConfiguration(photoLibrary: .shared())
        switch mode {
        case .image: config.filter = .images
        case .video: config.filter = .videos
        }
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func clearBackground() {
        backgroundImage = nil
        backgroundGifURL = nil
        refreshPreview()
    }

    @objc private func schedulePreviewRefresh() { refreshPreview() }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let mode = pickMode
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        switch mode {
        case .video:
            loadVideo(provider)
        case .image:
            loadImage(provider)
        }
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        // Copy movie out of the picker's temp sandbox BEFORE dismiss — otherwise
        // the mediaURL can vanish and conversion looks like "nothing happened".
        let image = info[.originalImage] as? UIImage
        var copiedVideo: URL?
        if let videoURL = info[.mediaURL] as? URL {
            copiedVideo = Self.persistPickerVideo(videoURL)
        }
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            if let image {
                self.backgroundGifURL = nil
                self.backgroundImage = image
                self.refreshPreview()
                return
            }
            if let copiedVideo {
                self.openVideoClip(copiedVideo)
            } else if info[.mediaURL] != nil {
                self.statusLabel.text = L10n.tr("wfs_gif_fail")
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    /// Persist UIImagePicker movie into tmp so it survives dismiss.
    private static func persistPickerVideo(_ src: URL) -> URL? {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("wfs_src_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: src, to: dest)
            return dest
        } catch {
            // Fallback: hard-link / data rewrite if copy fails (iCloud placeholders).
            guard let data = try? Data(contentsOf: src) else { return nil }
            do {
                try data.write(to: dest)
                return dest
            } catch {
                return nil
            }
        }
    }

    /// HaWoFit HR04 flow: validate ≥2s → JPImageresizer + SAVideoRangeSlider → GIF preview → Use.
    private func openVideoClip(_ videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        // HaWoFit validateVideoDuration: duration + 0.5 >= 2
        guard duration.isFinite, duration + 0.5 >= 2 else {
            statusLabel.text = L10n.tr("wfs_video_too_short")
            return
        }

        let p = currentPreset
        let isRound = p.width == p.height && p.corner >= p.width / 2 - 2

        let configure = JPImageresizerConfigure.darkBlurMaskType()
        configure.videoURL = videoURL
        configure.maximumZoomScale = 3
        configure.isArbitrarily = false
        if isRound {
            configure.isRoundResize = true
        } else {
            configure.isRoundResize = false
            configure.resizeWHScale = CGFloat(p.width) / CGFloat(max(p.height, 1))
        }

        let vc = HWImageresizerViewController()
        vc.videoURL = videoURL
        vc.configure = configure
        vc.dialWidth = CGFloat(p.width)
        vc.dialHeight = CGFloat(p.height)
        vc.isRoundDial = isRound
        vc.maxClipSeconds = 5
        vc.backBlock = { [weak self] gifURL in
            guard let self else { return }
            self.backgroundGifURL = gifURL
            // Keep animated frames — UIImage(data:) / scaledRoundedBitmap would freeze to frame 0.
            self.backgroundImage = AnimatedGIF.image(contentsOf: gifURL)
            self.statusLabel.text = L10n.tr("wfs_gif_ready")
            self.refreshPreview()
        }
        // HaWoFit pushes with animated: false
        navigationController?.pushViewController(vc, animated: false)
            ?? present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func loadImage(_ provider: NSItemProvider) {
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            statusLabel.text = L10n.tr("wfs_bg_load_fail"); return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            DispatchQueue.main.async {
                guard let image = obj as? UIImage else {
                    self?.statusLabel.text = L10n.tr("wfs_bg_load_fail"); return
                }
                self?.backgroundGifURL = nil
                self?.backgroundImage = image
                self?.refreshPreview()
            }
        }
    }

    private func loadVideo(_ provider: NSItemProvider) {
        let type = UTType.movie.identifier
        guard provider.hasItemConformingToTypeIdentifier(type) else {
            statusLabel.text = L10n.tr("wfs_gif_fail"); return
        }
        statusLabel.text = L10n.tr("wfs_making")
        provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, _ in
            guard let self, let url else {
                DispatchQueue.main.async { self?.statusLabel.text = L10n.tr("wfs_gif_fail") }
                return
            }
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("wfs_src_\(UUID().uuidString).mp4")
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: url, to: dest)
                DispatchQueue.main.async {
                    self.statusLabel.text = L10n.tr("wfs_ready")
                    self.openVideoClip(dest)
                }
            } catch {
                DispatchQueue.main.async { self.statusLabel.text = L10n.tr("wfs_gif_fail") }
            }
        }
    }

    private func refreshPreview() {
        let p = currentPreset
        let w = CGFloat(p.width)
        let h = CGFloat(p.height)
        let maxSide: CGFloat = 300
        let scale = maxSide / max(max(w, h), 1)
        let previewW = (w * scale).rounded()
        let previewH = (h * scale).rounded()
        previewWidthConstraint?.constant = previewW
        previewHeightConstraint?.constant = previewH
        let cornerScale = previewW / max(w, 1)
        preview.layer.cornerRadius = CGFloat(p.corner) * cornerScale
        previewImage.layer.cornerRadius = preview.layer.cornerRadius
        previewImage.clipsToBounds = true
        if let gifURL = backgroundGifURL,
           let anim = AnimatedGIF.image(contentsOf: gifURL) {
            // HaWoFit: SDWebImage plays GIF; round via layer.cornerRadius (don't rasterize).
            previewImage.image = anim
            previewImage.startAnimating()
        } else if let bg = backgroundImage {
            // Still photos: bake rounded bitmap for crisp dial preview.
            if bg.images != nil {
                previewImage.image = bg
                previewImage.startAnimating()
            } else {
                previewImage.image = WatchfaceImageUtils.scaledRoundedBitmap(
                    bg, size: CGSize(width: w, height: h), cornerRadius: CGFloat(p.corner)
                )
            }
        } else {
            // Dark dial placeholder so white glyphs stay readable without a photo.
            let size = CGSize(width: w, height: h)
            previewImage.image = UIGraphicsImageRenderer(size: size).image { _ in
                UIColor.black.setFill()
                UIBezierPath(
                    roundedRect: CGRect(origin: .zero, size: size),
                    cornerRadius: CGFloat(p.corner)
                ).fill()
            }
        }
        previewHost.layoutIfNeeded()
        preview.layoutIfNeeded()
        layoutPreviewWidgets(watchW: p.width, watchH: p.height, corner: p.corner)
    }

    private func layoutPreviewWidgets(watchW: Int, watchH: Int, corner: Int) {
        let bounds = previewOverlay.bounds
        guard bounds.width > 1, bounds.height > 1 else {
            DispatchQueue.main.async { [weak self] in self?.refreshPreview() }
            return
        }
        let sx = bounds.width / CGFloat(watchW)
        let sy = bounds.height / CGFloat(watchH)
        let inset = layoutInsets(width: watchW, height: watchH, corner: corner)
        let timeW = 124 + 40 + 124
        let timeH = 96
        let timeX = (watchW - timeW) / 2
        let timeY = inset.timeY

        let timeLabel = previewLabel(tag: 9001, text: "10:08", bold: true)
        place(timeLabel, x: timeX, y: timeY, w: timeW, h: timeH, sx: sx, sy: sy)

        let dateRow = widgetRows[0]
        let weekRow = widgetRows[1]
        let dateW = QjsFontGlyphRenderer.dateWidgetWidth(fontSizePx: dateRow.fontSizePx)
        let weekW = QjsFontGlyphRenderer.weekCell(fontSizePx: weekRow.fontSizePx).0
        let rowY = timeY + timeH + 10
        var rowX = (watchW - (dateRow.sw.isOn ? dateW : 0) - (weekRow.sw.isOn ? weekW : 0)) / 2
        placeStyled(dateRow, x: &rowX, y: rowY, w: dateW, h: dateRow.fontSizePx, sx: sx, sy: sy, advance: true)
        placeStyled(weekRow, x: &rowX, y: rowY, w: weekW, h: weekRow.fontSizePx, sx: sx, sy: sy, advance: true)

        let stepH = widgetRows[2].fontSizePx
        let stepY = watchH - stepH - inset.bottom
        placeFixed(widgetRows[2], x: inset.side, y: stepY, w: 140, h: stepH, sx: sx, sy: sy)
        placeFixed(widgetRows[3], x: inset.side, y: stepY - widgetRows[3].fontSizePx - 8, w: 100, h: widgetRows[3].fontSizePx, sx: sx, sy: sy)
        placeFixed(widgetRows[4], x: watchW - 120 - inset.side, y: stepY - widgetRows[4].fontSizePx - 8, w: 120, h: widgetRows[4].fontSizePx, sx: sx, sy: sy)
        placeFixed(widgetRows[5], x: inset.side, y: inset.top, w: 100, h: widgetRows[5].fontSizePx, sx: sx, sy: sy)
        placeFixed(widgetRows[6], x: watchW - 100 - inset.side, y: inset.top, w: 100, h: widgetRows[6].fontSizePx, sx: sx, sy: sy)
        placeFixed(widgetRows[7], x: watchW - 100 - inset.side, y: watchH - widgetRows[7].fontSizePx - inset.bottom, w: 100, h: widgetRows[7].fontSizePx, sx: sx, sy: sy)

        layoutPointerPreview(watchW: watchW, watchH: watchH, sx: sx, sy: sy)

        let link = 72
        placeLinkHint(tag: 9010, on: linkPhoneSwitch.isOn, title: "Phone",
                      x: inset.link, y: watchH / 2 - link / 2, w: link, h: link, sx: sx, sy: sy)
        placeLinkHint(tag: 9011, on: linkNotifySwitch.isOn, title: "Notify",
                      x: watchW - link - inset.link, y: watchH / 2 - link / 2, w: link, h: link, sx: sx, sy: sy)
        placeLinkHint(tag: 9012, on: linkActivitySwitch.isOn, title: "Act",
                      x: watchW / 2 - link / 2, y: watchH - link - inset.link, w: link, h: link, sx: sx, sy: sy)
        placeLinkHint(tag: 9013, on: linkWeatherSwitch.isOn, title: "Wx",
                      x: watchW / 2 - link / 2, y: inset.link, w: link, h: link, sx: sx, sy: sy)
    }

    private func layoutPointerPreview(watchW: Int, watchH: Int, sx: CGFloat, sy: CGFloat) {
        let cx = CGFloat(watchW) * sx / 2
        let cy = CGFloat(watchH) * sy / 2
        let on = pointerSwitch.isOn
        func hand(tag: Int, length: CGFloat, width: CGFloat, angleDeg: CGFloat, color: UIColor?) {
            let v = previewChip(tag: tag)
            v.isHidden = !on
            guard on else { return }
            v.transform = .identity
            v.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
            v.bounds = CGRect(x: 0, y: 0, width: width, height: length)
            v.center = CGPoint(x: cx, y: cy)
            v.backgroundColor = WatchfaceImageUtils.rgbTint(color ?? .white)
            v.layer.cornerRadius = width / 2
            v.transform = CGAffineTransform(rotationAngle: angleDeg * .pi / 180)
        }
        hand(tag: 9101, length: min(cx, cy) * 0.45, width: 4, angleDeg: -60,
             color: hourWell.selectedColor)
        hand(tag: 9102, length: min(cx, cy) * 0.62, width: 3, angleDeg: 30,
             color: minuteWell.selectedColor)
        hand(tag: 9103, length: min(cx, cy) * 0.72, width: 2, angleDeg: 150,
             color: secondWell.selectedColor)
        let dot = previewChip(tag: 9104)
        dot.isHidden = !on
        if on {
            let size: CGFloat = 10
            dot.transform = .identity
            dot.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            dot.bounds = CGRect(x: 0, y: 0, width: size, height: size)
            dot.center = CGPoint(x: cx, y: cy)
            dot.backgroundColor = WatchfaceImageUtils.rgbTint(dotWell.selectedColor ?? .white)
            dot.layer.cornerRadius = size / 2
        }
    }

    private func previewChip(tag: Int) -> UIView {
        if let v = previewOverlay.viewWithTag(tag) { return v }
        let v = UIView(); v.tag = tag; previewOverlay.addSubview(v); return v
    }

    private func previewLabel(tag: Int, text: String, bold: Bool = false) -> UILabel {
        if let l = previewOverlay.viewWithTag(tag) as? UILabel { return l }
        let l = UILabel()
        l.tag = tag
        l.text = text
        l.textAlignment = .center
        l.textColor = .white
        l.font = bold
            ? .monospacedDigitSystemFont(ofSize: 22, weight: .bold)
            : .systemFont(ofSize: 12, weight: .semibold)
        previewOverlay.addSubview(l)
        return l
    }

    private func placeLinkHint(tag: Int, on: Bool, title: String, x: Int, y: Int, w: Int, h: Int, sx: CGFloat, sy: CGFloat) {
        let label = previewLabel(tag: tag, text: title)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = !on
        if on { place(label, x: x, y: y, w: w, h: h, sx: sx, sy: sy) }
    }

    private func placeStyled(_ row: WidgetStyleRow, x: inout Int, y: Int, w: Int, h: Int, sx: CGFloat, sy: CGFloat, advance: Bool) {
        row.preview.isHidden = !row.sw.isOn
        row.preview.textColor = WatchfaceImageUtils.rgbTint(row.well.selectedColor ?? row.defaultColor)
        row.preview.font = currentGlyphFont().withSize(CGFloat(max(10, h)) * sy * 0.7)
        if row.sw.isOn {
            place(row.preview, x: x, y: y, w: w, h: h, sx: sx, sy: sy)
            if advance { x += w }
        }
    }

    private func placeFixed(_ row: WidgetStyleRow, x: Int, y: Int, w: Int, h: Int, sx: CGFloat, sy: CGFloat) {
        row.preview.isHidden = !row.sw.isOn
        row.preview.textColor = WatchfaceImageUtils.rgbTint(row.well.selectedColor ?? row.defaultColor)
        row.preview.font = currentGlyphFont().withSize(CGFloat(max(10, h)) * sy * 0.7)
        if row.sw.isOn { place(row.preview, x: x, y: y, w: w, h: h, sx: sx, sy: sy) }
    }

    private func place(_ view: UIView, x: Int, y: Int, w: Int, h: Int, sx: CGFloat, sy: CGFloat) {
        view.frame = CGRect(
            x: CGFloat(x) * sx, y: CGFloat(y) * sy,
            width: max(1, CGFloat(w) * sx), height: max(1, CGFloat(h) * sy)
        )
    }

    @objc private func syncToWatch() {
        guard !busy else { return }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect"); return
        }
        let p = currentPreset
        let w = p.width, h = p.height
        let corner = CGFloat(p.corner)
        let name = (nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines) : "studio"

        refreshPreview()
        setBusy(true, L10n.tr("wfs_making"))
        preview.layoutIfNeeded()

        let face = SlifiCustomWatchface(width: w, height: h)
        face.name = name
        if let gif = backgroundGifURL, FileManager.default.fileExists(atPath: gif.path) {
            face.backgroundGif = gif
            if let bg = backgroundImage {
                face.backgroundImage = WatchfaceImageUtils.scaledRoundedBitmap(
                    bg, size: CGSize(width: w, height: h), cornerRadius: corner
                )
            }
        } else if let bg = backgroundImage {
            face.backgroundImage = WatchfaceImageUtils.scaledRoundedBitmap(
                bg, size: CGSize(width: w, height: h), cornerRadius: corner
            )
        }

        if let thumb = WatchfaceImageUtils.snapshot(
            preview, size: CGSize(width: p.thumbW, height: p.thumbH),
            cornerRadius: CGFloat(p.thumbCorner)
        ) {
            face.thumbnailImage = thumb
        } else if let bg = face.backgroundImage {
            face.thumbnailImage = WatchfaceImageUtils.scaledRoundedBitmap(
                bg, size: CGSize(width: p.thumbW, height: p.thumbH),
                cornerRadius: CGFloat(p.thumbCorner)
            )
        } else {
            let size = CGSize(width: p.thumbW, height: p.thumbH)
            face.thumbnailImage = UIGraphicsImageRenderer(size: size).image { ctx in
                UIColor.darkGray.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            }
        }

        for widget in buildWidgets(width: w, height: h, corner: p.corner) {
            face.addWidget(widget)
        }

        statusLabel.text = L10n.tr("wfs_syncing")
        repo.pushCustomWatchface(face, onCompress: { [weak self] ok in
            if ok { self?.statusLabel.text = L10n.tr("wfs_syncing") }
        }, onProgress: { [weak self] prog in
            self?.progress.progress = prog
            self?.statusLabel.text = L10n.tr("wfs_syncing_pct", Int(prog * 100))
        }, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.setBusy(false, L10n.tr("wfs_sync_ok"))
                self.progress.progress = 1
            case .failure(let e):
                self.setBusy(false, L10n.tr("wfs_sync_fail", e.localizedDescription))
            }
        })
    }

    private func buildWidgets(width: Int, height: Int, corner: Int) -> [QjsWidget] {
        var list: [QjsWidget] = []
        let inset = layoutInsets(width: width, height: height, corner: corner)
        let font = currentGlyphFont()
        let tintWhite = WatchfaceImageUtils.rgbTint(.white)

        let time = QjsTimeWidget(tintColor: tintWhite)
        time.x = max(0, (width - time.width) / 2)
        time.y = inset.timeY
        list.append(time)

        let dateOn = widgetRows[0].sw.isOn
        let weekOn = widgetRows[1].sw.isOn
        let date = StudioDateWidget(
            tintColor: tint(for: widgetRows[0]), font: font, fontSizePx: widgetRows[0].fontSizePx
        )
        let week = StudioWeekWidget(
            tintColor: tint(for: widgetRows[1]), font: font, fontSizePx: widgetRows[1].fontSizePx
        )
        let rowY = time.y + time.height + 10
        var rowX = (width - (dateOn ? date.width : 0) - (weekOn ? week.width : 0)) / 2
        if dateOn {
            date.x = max(0, rowX); date.y = rowY; list.append(date); rowX += date.width
        }
        if weekOn {
            week.x = max(0, rowX); week.y = rowY; list.append(week)
        }

        func placeIcon(_ kind: StudioIconDataWidget.Kind, row: WidgetStyleRow, x: Int, y: Int) {
            guard row.sw.isOn else { return }
            let w = StudioIconDataWidget(
                kind: kind, tintColor: tint(for: row), font: font, fontSizePx: row.fontSizePx
            )
            w.x = x; w.y = y
            list.append(w)
        }

        let stepRow = widgetRows[2]
        if stepRow.sw.isOn {
            let step = StudioIconDataWidget(
                kind: .step, tintColor: tint(for: stepRow), font: font, fontSizePx: stepRow.fontSizePx
            )
            step.x = inset.side
            step.y = height - step.height - inset.bottom
            list.append(step)
            placeIcon(.distance, row: widgetRows[3], x: inset.side, y: step.y - widgetRows[3].fontSizePx - 8)
            let cal = StudioIconDataWidget(
                kind: .calorie, tintColor: tint(for: widgetRows[4]),
                font: font, fontSizePx: widgetRows[4].fontSizePx
            )
            if widgetRows[4].sw.isOn {
                cal.x = max(0, width - cal.width - inset.side)
                cal.y = step.y - cal.height - 8
                list.append(cal)
            }
        } else {
            placeIcon(.distance, row: widgetRows[3], x: inset.side, y: height - inset.bottom - 40)
            placeIcon(.calorie, row: widgetRows[4], x: width - 140 - inset.side, y: height - inset.bottom - 40)
        }
        placeIcon(.battery, row: widgetRows[5], x: inset.side, y: inset.top)
        placeIcon(.heartrate, row: widgetRows[6], x: width - 120 - inset.side, y: inset.top)

        if widgetRows[7].sw.isOn {
            let weather = QjsWeatherTAWidget(tintColor: tint(for: widgetRows[7]))
            weather.x = max(0, width - weather.width - inset.side)
            weather.y = height - weather.height - inset.bottom
            list.append(weather)
        }

        if pointerSwitch.isOn {
            let size = Size(width: width, height: height)
            list.append(QjsHourPointerWidget(size, tintColor: WatchfaceImageUtils.rgbTint(hourWell.selectedColor ?? .green)))
            list.append(QjsMinutePointerWidget(size, tintColor: WatchfaceImageUtils.rgbTint(minuteWell.selectedColor ?? .blue)))
            list.append(QjsSecondPointerWidget(size, tintColor: WatchfaceImageUtils.rgbTint(secondWell.selectedColor ?? .green)))
            let dot = QjsDotWidget(tintColor: WatchfaceImageUtils.rgbTint(dotWell.selectedColor ?? .white))
            dot.setCenter(CGPoint(x: width / 2, y: height / 2))
            list.append(dot)
        }

        let link = 72
        if linkPhoneSwitch.isOn {
            list.append(QjsAppLinkWidget(x: inset.link, y: height / 2 - link / 2, width: link, height: link, launcherType: StudioLauncherType.phone))
        }
        if linkNotifySwitch.isOn {
            list.append(QjsAppLinkWidget(x: width - link - inset.link, y: height / 2 - link / 2, width: link, height: link, launcherType: StudioLauncherType.notifications))
        }
        if linkActivitySwitch.isOn {
            list.append(QjsAppLinkWidget(x: width / 2 - link / 2, y: height - link - inset.link, width: link, height: link, launcherType: StudioLauncherType.activity))
        }
        if linkWeatherSwitch.isOn {
            list.append(QjsAppLinkWidget(x: width / 2 - link / 2, y: inset.link, width: link, height: link, launcherType: StudioLauncherType.weather))
        }
        return list
    }

    private func tint(for row: WidgetStyleRow) -> UIColor {
        WatchfaceImageUtils.rgbTint(row.well.selectedColor ?? row.defaultColor)
    }

    private func setBusy(_ value: Bool, _ status: String) {
        busy = value
        syncButton.isEnabled = !value
        progress.isHidden = !value
        if !value { progress.progress = 0 }
        statusLabel.text = status
        navigationItem.hidesBackButton = value
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !value
    }
}

/// Registers bundled Studio TTFs once.
enum StudioFontRegistry {
    private static var didRegister = false

    static func registerBundledFonts() {
        guard !didRegister else { return }
        didRegister = true
        for name in ["roboto_bold", "montserrat_bold"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func font(file: String, size: CGFloat) -> UIFont? {
        registerBundledFonts()
        let candidates = [
            "Roboto-Bold", "Roboto Bold", "roboto_bold",
            "Montserrat-Bold", "Montserrat Bold", "montserrat_bold",
        ]
        for name in candidates where name.lowercased().contains(file.split(separator: "_").first.map(String.init)?.lowercased() ?? "") {
            if let f = UIFont(name: name, size: size) { return f }
        }
        // Fallback: create from file data
        guard let url = Bundle.main.url(forResource: file, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: file, withExtension: "ttf"),
              let data = try? Data(contentsOf: url) as CFData,
              let provider = CGDataProvider(data: data),
              let cgFont = CGFont(provider),
              let name = cgFont.postScriptName as String?
        else { return nil }
        CTFontManagerRegisterGraphicsFont(cgFont, nil)
        return UIFont(name: name, size: size)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
