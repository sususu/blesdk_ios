import UIKit
import PhotosUI

private final class JieliPointerPreviewView: UIView {
    var style: JieliWatchfacePointerStyle = .none { didSet { setNeedsDisplay() } }
    var tint: UIColor = .white { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard style != .none, let context = UIGraphicsGetCurrentContext() else { return }
        let scale = min(bounds.width, bounds.height) / 466
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let lineWidth: CGFloat
        switch style {
        case .style1: lineWidth = 5 * scale
        case .style2: lineWidth = 8 * scale
        case .style3: lineWidth = 3 * scale
        case .none: return
        }

        context.setStrokeColor(tint.cgColor)
        context.setFillColor(tint.cgColor)
        context.setLineCap(.round)
        context.setLineWidth(max(1, lineWidth))
        context.move(to: center)
        context.addLine(to: CGPoint(x: center.x - 52 * scale, y: center.y - 72 * scale))
        context.strokePath()
        context.move(to: center)
        context.addLine(to: CGPoint(x: center.x + 18 * scale, y: center.y - 132 * scale))
        context.strokePath()
        context.fillEllipse(in: CGRect(
            x: center.x - 8 * scale,
            y: center.y - 8 * scale,
            width: 16 * scale,
            height: 16 * scale
        ))
    }
}

private final class JieliBackgroundCell: UICollectionViewCell {
    static let reuseIdentifier = "JieliBackgroundCell"

    private let imageView = UIImageView()
    private let coverLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 2

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        coverLabel.font = .systemFont(ofSize: 10, weight: .bold)
        coverLabel.textColor = .white
        coverLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
        coverLabel.textAlignment = .center
        coverLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(coverLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            coverLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            coverLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(image: UIImage, isCover: Bool) {
        imageView.image = image
        coverLabel.text = L10n.tr("wf_jl_cover")
        coverLabel.isHidden = !isCover
        contentView.layer.borderColor = (isCover ? UIColor.systemBlue : UIColor.clear).cgColor
        accessibilityLabel = isCover ? L10n.tr("wf_jl_cover") : L10n.tr("wf_pick_bg")
        accessibilityTraits = isCover ? [.image, .selected] : .image
    }
}

/// Native JL custom watchface editor. Images and configuration are both sent by
/// `BleRepository.pushJieliCustomWatchface`; no Sifli/QJS packaging is involved.
final class JieliCustomWatchfaceViewController: UIViewController,
    PHPickerViewControllerDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegate {

    weak var host: JieliWatchfaceHostViewController?

    private let repo = BleRepository.shared
    private let presets = WatchfaceSizePreset.customDefaults
    private var draft = JieliCustomWatchfaceDraft(geometry: .init(
        width: 466,
        height: 466,
        cornerRadius: 233,
        thumbnailWidth: 264,
        thumbnailHeight: 264,
        thumbnailCornerRadius: 132
    ))
    private var backgroundImages: [UIImage] = []
    private var maxBackgroundCount = 1
    private var busy = false
    private var selectedBackgroundIndex = 0

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let statusLabel = UIHelpers.makeLabel("")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let previewPanel = UIView()
    private let previewImage = UIImageView()
    private var componentPreviewLabels: [UILabel] = []
    private let pointerPreview = JieliPointerPreviewView()
    private var previewHeightConstraint: NSLayoutConstraint!

    private let widthField = UITextField()
    private let heightField = UITextField()
    private let cornerField = UITextField()
    private let thumbWField = UITextField()
    private let thumbHField = UITextField()
    private let thumbCornerField = UITextField()

    private let backgroundCountLabel = UIHelpers.makeLabel("")
    private let thumbnailCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 74, height: 74)
        layout.minimumLineSpacing = 8
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.heightAnchor.constraint(equalToConstant: 78).isActive = true
        return collection
    }()
    private let addPhotosButton = UIHelpers.makeButton(L10n.tr("wf_jl_add_photos"))
    private let deletePhotoButton = UIHelpers.makeButton(L10n.tr("wf_jl_delete_photo"))
    private let displayModeControl = UISegmentedControl(items: JieliWatchfaceDisplayMode.allCases.map {
        L10n.tr($0.localizationKey)
    })
    private let pointerStyleControl = UISegmentedControl(items: JieliWatchfacePointerStyle.allCases.map {
        L10n.tr($0.localizationKey)
    })
    private let componentButtons = (0..<4).map { _ in UIHelpers.makeButton("") }
    private let installButton = UIHelpers.makeButton(L10n.tr("wf_push_custom"), primary: true)
    private let logView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureLayout()
        configurePreview()
        configureEditorControls()
        applyPreset(presets[0])
        refreshEditor()
        loadDeviceCapacity()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPreviewElements()
    }

    private func configureLayout() {
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

        progress.isHidden = true
        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(progress)
        content.addArrangedSubview(previewPanel)

        let presetButton = UIHelpers.makeButton(L10n.tr("wf_size_preset"))
        presetButton.addTarget(self, action: #selector(pickPreset(_:)), for: .touchUpInside)
        content.addArrangedSubview(presetButton)
        content.addArrangedSubview(makeFieldRow("W", widthField, "H", heightField))
        content.addArrangedSubview(makeFieldRow("Corner", cornerField, "ThumbW", thumbWField))
        content.addArrangedSubview(makeFieldRow("ThumbH", thumbHField, "ThumbR", thumbCornerField))

        content.addArrangedSubview(backgroundCountLabel)
        content.addArrangedSubview(thumbnailCollection)
        let photoButtons = UIStackView(arrangedSubviews: [addPhotosButton, deletePhotoButton])
        photoButtons.axis = .horizontal
        photoButtons.spacing = 8
        photoButtons.distribution = .fillEqually
        content.addArrangedSubview(photoButtons)

        content.addArrangedSubview(makeSectionLabel(L10n.tr("wf_jl_display_mode")))
        content.addArrangedSubview(displayModeControl)
        content.addArrangedSubview(makeSectionLabel(L10n.tr("wf_jl_pointer_style")))
        content.addArrangedSubview(pointerStyleControl)

        for button in componentButtons {
            content.addArrangedSubview(button)
        }

        content.addArrangedSubview(makeSectionLabel(L10n.tr("wf_jl_text_color")))
        content.addArrangedSubview(makeColorRow())
        content.addArrangedSubview(installButton)

        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        content.addArrangedSubview(logView)
    }

    private func configurePreview() {
        previewPanel.backgroundColor = .black
        previewPanel.layer.masksToBounds = true
        previewHeightConstraint = previewPanel.heightAnchor.constraint(equalToConstant: 260)
        previewHeightConstraint.isActive = true

        previewImage.contentMode = .scaleToFill
        previewImage.translatesAutoresizingMaskIntoConstraints = false
        previewPanel.addSubview(previewImage)

        for _ in 0..<4 {
            let label = UILabel()
            label.textAlignment = .left
            label.adjustsFontSizeToFitWidth = false
            label.numberOfLines = 1
            previewPanel.addSubview(label)
            componentPreviewLabels.append(label)
        }

        pointerPreview.translatesAutoresizingMaskIntoConstraints = false
        previewPanel.addSubview(pointerPreview)

        NSLayoutConstraint.activate([
            previewImage.topAnchor.constraint(equalTo: previewPanel.topAnchor),
            previewImage.leadingAnchor.constraint(equalTo: previewPanel.leadingAnchor),
            previewImage.trailingAnchor.constraint(equalTo: previewPanel.trailingAnchor),
            previewImage.bottomAnchor.constraint(equalTo: previewPanel.bottomAnchor),
            pointerPreview.topAnchor.constraint(equalTo: previewPanel.topAnchor),
            pointerPreview.leadingAnchor.constraint(equalTo: previewPanel.leadingAnchor),
            pointerPreview.trailingAnchor.constraint(equalTo: previewPanel.trailingAnchor),
            pointerPreview.bottomAnchor.constraint(equalTo: previewPanel.bottomAnchor)
        ])
    }

    private func configureEditorControls() {
        configureNumericFields()
        thumbnailCollection.register(JieliBackgroundCell.self, forCellWithReuseIdentifier: JieliBackgroundCell.reuseIdentifier)
        thumbnailCollection.dataSource = self
        thumbnailCollection.delegate = self

        addPhotosButton.addTarget(self, action: #selector(pickBackgrounds), for: .touchUpInside)
        deletePhotoButton.addTarget(self, action: #selector(deleteSelectedBackground), for: .touchUpInside)
        displayModeControl.selectedSegmentIndex = draft.displayMode.rawValue
        displayModeControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
        pointerStyleControl.selectedSegmentIndex = Int(draft.pointerStyle.rawValue)
        pointerStyleControl.addTarget(self, action: #selector(pointerStyleChanged), for: .valueChanged)
        for (index, button) in componentButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector(pickComponent(_:)), for: .touchUpInside)
        }
        installButton.addTarget(self, action: #selector(pushCustom), for: .touchUpInside)
    }

    private func configureNumericFields() {
        [widthField, heightField, cornerField, thumbWField, thumbHField, thumbCornerField].forEach {
            $0.borderStyle = .roundedRect
            $0.keyboardType = .numberPad
            $0.addTarget(self, action: #selector(geometryChanged), for: .editingChanged)
        }
    }

    private func makeFieldRow(_ firstTitle: String, _ firstView: UIView, _ secondTitle: String, _ secondView: UIView) -> UIStackView {
        let firstLabel = UILabel()
        firstLabel.text = firstTitle
        firstLabel.font = .systemFont(ofSize: 12)
        let secondLabel = UILabel()
        secondLabel.text = secondTitle
        secondLabel.font = .systemFont(ofSize: 12)
        let row = UIStackView(arrangedSubviews: [firstLabel, firstView, secondLabel, secondView])
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        return row
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UIHelpers.makeLabel(text, style: .subheadline)
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func makeColorRow() -> UIStackView {
        let values = ["FFFFFF", "000000", "FF3B30", "34C759", "007AFF", "FFD60A"]
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for value in values {
            let button = UIButton(type: .system)
            button.backgroundColor = color(from: value)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.separator.cgColor
            button.accessibilityLabel = "#\(value)"
            button.accessibilityIdentifier = value
            button.heightAnchor.constraint(equalToConstant: 42).isActive = true
            button.addTarget(self, action: #selector(colorChanged(_:)), for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    @objc private func pickPreset(_ sender: UIButton) {
        let sheet = UIAlertController(title: L10n.tr("wf_size_preset"), message: nil, preferredStyle: .actionSheet)
        for preset in presets {
            sheet.addAction(UIAlertAction(title: preset.label, style: .default) { [weak self] _ in
                self?.applyPreset(preset)
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        configurePopover(sheet, sourceView: sender)
        present(sheet, animated: true)
    }

    private func applyPreset(_ preset: WatchfaceSizePreset) {
        draft.geometry = .init(
            width: preset.width,
            height: preset.height,
            cornerRadius: preset.corner,
            thumbnailWidth: preset.thumbW,
            thumbnailHeight: preset.thumbH,
            thumbnailCornerRadius: preset.thumbCorner
        )
        widthField.text = "\(preset.width)"
        heightField.text = "\(preset.height)"
        cornerField.text = "\(preset.corner)"
        thumbWField.text = "\(preset.thumbW)"
        thumbHField.text = "\(preset.thumbH)"
        thumbCornerField.text = "\(preset.thumbCorner)"
        refreshPreview()
    }

    @objc private func geometryChanged() {
        updateDraftGeometry(requireComplete: false)
        refreshPreview()
    }

    @discardableResult
    private func updateDraftGeometry(requireComplete: Bool) -> Bool {
        let values = [widthField, heightField, cornerField, thumbWField, thumbHField, thumbCornerField].map {
            Int($0.text ?? "")
        }
        if requireComplete && values.contains(where: { $0 == nil }) { return false }

        let geometry = JieliCustomWatchfaceGeometry(
            width: values[0] ?? draft.geometry.width,
            height: values[1] ?? draft.geometry.height,
            cornerRadius: values[2] ?? draft.geometry.cornerRadius,
            thumbnailWidth: values[3] ?? draft.geometry.thumbnailWidth,
            thumbnailHeight: values[4] ?? draft.geometry.thumbnailHeight,
            thumbnailCornerRadius: values[5] ?? draft.geometry.thumbnailCornerRadius
        )
        guard geometry.width > 0,
              geometry.height > 0,
              geometry.cornerRadius >= 0,
              geometry.thumbnailWidth > 0,
              geometry.thumbnailHeight > 0,
              geometry.thumbnailCornerRadius >= 0 else { return false }
        draft.geometry = geometry
        return true
    }

    private func loadDeviceCapacity() {
        statusLabel.text = L10n.tr("wf_jl_storage_loading")
        repo.getJieliCustomWatchfaceCapacity { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let count):
                self.maxBackgroundCount = max(1, min(8, count))
                self.statusLabel.text = L10n.tr("feature_ready")
            case .failure(let error):
                self.maxBackgroundCount = 1
                self.statusLabel.text = L10n.tr("wf_jl_storage_fail")
                self.append(error.localizedDescription)
            }
            self.refreshBackgroundState()
        }
    }

    private func refreshEditor() {
        refreshBackgroundState()
        refreshComponentButtons()
        refreshPreview()
    }

    private func refreshBackgroundState() {
        draft.coverImageIndex = JieliCustomWatchfaceRules.normalizedCoverIndex(
            draft.coverImageIndex,
            imageCount: backgroundImages.count
        )
        selectedBackgroundIndex = draft.coverImageIndex
        backgroundCountLabel.text = L10n.tr("wf_jl_bg_count", backgroundImages.count, maxBackgroundCount)
        addPhotosButton.isEnabled = !busy && backgroundImages.count < maxBackgroundCount
        deletePhotoButton.isEnabled = !busy && !backgroundImages.isEmpty
        thumbnailCollection.reloadData()
    }

    @objc private func pickBackgrounds() {
        guard !busy else { return }
        let remaining = maxBackgroundCount - backgroundImages.count
        guard remaining > 0 else { return }
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images
            configuration.selectionLimit = remaining
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        }
    }

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        let lock = NSLock()
        var loaded = Array<UIImage?>(repeating: nil, count: results.count)
        for (index, result) in results.enumerated() {
            let provider = result.itemProvider
            guard provider.canLoadObject(ofClass: UIImage.self) else { continue }
            group.enter()
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                lock.lock()
                loaded[index] = object as? UIImage
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let firstNewIndex = self.backgroundImages.count
            let available = max(0, self.maxBackgroundCount - firstNewIndex)
            self.backgroundImages.append(contentsOf: loaded.compactMap { $0 }.prefix(available))
            if self.backgroundImages.count > firstNewIndex {
                self.selectedBackgroundIndex = firstNewIndex
                self.draft.coverImageIndex = firstNewIndex
            }
            self.refreshBackgroundState()
            self.refreshPreview()
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true)
        guard backgroundImages.count < maxBackgroundCount,
              let image = info[.originalImage] as? UIImage else { return }
        backgroundImages.append(image)
        selectedBackgroundIndex = backgroundImages.count - 1
        draft.coverImageIndex = selectedBackgroundIndex
        refreshBackgroundState()
        refreshPreview()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    @objc private func deleteSelectedBackground() {
        guard !busy, backgroundImages.indices.contains(selectedBackgroundIndex) else { return }
        backgroundImages.remove(at: selectedBackgroundIndex)
        selectedBackgroundIndex = JieliCustomWatchfaceRules.normalizedCoverIndex(
            selectedBackgroundIndex,
            imageCount: backgroundImages.count
        )
        draft.coverImageIndex = selectedBackgroundIndex
        refreshBackgroundState()
        refreshPreview()
    }

    @objc private func displayModeChanged() {
        guard let mode = JieliWatchfaceDisplayMode(rawValue: displayModeControl.selectedSegmentIndex) else { return }
        draft.displayMode = mode
        refreshPreview()
    }

    @objc private func pointerStyleChanged() {
        guard let style = JieliWatchfacePointerStyle(rawValue: Int32(pointerStyleControl.selectedSegmentIndex)) else { return }
        draft.pointerStyle = style
        refreshPreview()
    }

    @objc private func pickComponent(_ sender: UIButton) {
        let slot = sender.tag
        guard draft.components.indices.contains(slot) else { return }
        let sheet = UIAlertController(
            title: L10n.tr("wf_jl_component_slot", slot + 1, L10n.tr(draft.components[slot].localizationKey)),
            message: nil,
            preferredStyle: .actionSheet
        )
        let selectedElsewhere = Set(draft.components.enumerated().compactMap { index, type in
            index == slot || type == .off ? nil : type
        })
        for type in JieliWatchfaceComponentType.allCases {
            let action = UIAlertAction(title: L10n.tr(type.localizationKey), style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.draft.components[slot] = type
                self.refreshComponentButtons()
                self.refreshPreview()
            }
            action.isEnabled = type == .off || !selectedElsewhere.contains(type)
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        configurePopover(sheet, sourceView: sender)
        present(sheet, animated: true)
    }

    private func refreshComponentButtons() {
        for (index, button) in componentButtons.enumerated() where draft.components.indices.contains(index) {
            let type = draft.components[index]
            button.setTitle(
                L10n.tr("wf_jl_component_slot", index + 1, L10n.tr(type.localizationKey)),
                for: .normal
            )
        }
    }

    @objc private func colorChanged(_ sender: UIButton) {
        guard let value = sender.accessibilityIdentifier else { return }
        draft.rgbHex = value
        refreshPreview()
    }

    private func refreshPreview() {
        let geometry = draft.geometry
        let availableWidth = max(previewPanel.bounds.width, view.bounds.width - 24)
        previewHeightConstraint.constant = availableWidth
            * CGFloat(geometry.height)
            / CGFloat(max(geometry.width, 1))
        view.layoutIfNeeded()
        layoutPreviewElements()

        if backgroundImages.indices.contains(selectedBackgroundIndex) {
            previewImage.image = try? JieliWatchfaceImageEncoder.renderedImage(
                backgroundImages[selectedBackgroundIndex],
                size: CGSize(width: CGFloat(geometry.width), height: CGFloat(geometry.height)),
                cornerRadius: CGFloat(geometry.cornerRadius)
            )
        } else {
            previewImage.image = nil
        }
        previewPanel.backgroundColor = .black

        let tint = color(from: draft.rgbHex)
        for (index, label) in componentPreviewLabels.enumerated() {
            let type = draft.components.indices.contains(index) ? draft.components[index] : .off
            label.text = previewText(for: type)
            label.textColor = tint
            label.isHidden = type == .off
        }
        pointerPreview.style = draft.pointerStyle
        pointerPreview.tint = tint
        layoutPreviewElements()
    }

    private func layoutPreviewElements() {
        let geometry = draft.geometry
        guard geometry.width > 0, geometry.height > 0, previewPanel.bounds.width > 0 else { return }

        let expectedHeight = previewPanel.bounds.width
            * CGFloat(geometry.height)
            / CGFloat(geometry.width)
        if abs(previewHeightConstraint.constant - expectedHeight) > 0.5 {
            previewHeightConstraint.constant = expectedHeight
        }

        let scale = previewPanel.bounds.width / CGFloat(geometry.width)
        previewPanel.layer.cornerRadius = min(
            CGFloat(geometry.cornerRadius) * scale,
            min(previewPanel.bounds.width, expectedHeight) / 2
        )

        let placements = JieliCustomWatchfaceRules.componentPlacements(
            draft.components,
            isRound: geometry.isRound
        )
        var placementIndex = 0
        for (slot, label) in componentPreviewLabels.enumerated() {
            let type = draft.components.indices.contains(slot) ? draft.components[slot] : .off
            guard type != .off, placements.indices.contains(placementIndex) else {
                label.frame = .zero
                continue
            }
            let placement = placements[placementIndex]
            placementIndex += 1
            label.frame = CGRect(
                x: placement.position.x * scale,
                y: placement.position.y * scale,
                width: JieliCustomWatchfaceRules.componentWidth * scale,
                height: type.rowHeight * scale
            )
            label.font = type == .time
                ? .monospacedDigitSystemFont(ofSize: 72 * scale, weight: .semibold)
                : .systemFont(ofSize: 20 * scale, weight: .semibold)
        }
    }

    private func previewText(for type: JieliWatchfaceComponentType) -> String {
        switch type {
        case .off: return ""
        case .time: return "10:08"
        case .date: return "08/21"
        case .heartRate: return "♥ 72"
        case .steps: return "● 8000"
        case .calories: return "● 320 kcal"
        case .battery: return "▰ 80%"
        case .weather: return "☀ 26°"
        case .distance: return "● 5.2 km"
        }
    }

    @objc private func pushCustom() {
        guard !busy else { return }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            return
        }
        guard updateDraftGeometry(requireComplete: true), let thumbnail = makePreviewThumbnail() else {
            statusLabel.text = L10n.tr("wf_err_size")
            append(L10n.tr("wf_err_size"))
            return
        }

        busy = true
        host?.setInstalling(true)
        progress.isHidden = false
        progress.progress = 0
        installButton.isEnabled = false
        refreshBackgroundState()
        statusLabel.text = L10n.tr("wf_jl_converting")

        repo.pushJieliCustomWatchface(
            backgroundImages: backgroundImages,
            thumbnailImage: thumbnail,
            draft: draft,
            onReady: { [weak self] in
                self?.statusLabel.text = L10n.tr("wf_pushing")
            },
            onProgress: { [weak self] value in
                self?.progress.progress = value
                self?.statusLabel.text = L10n.tr("wf_progress", Int(value * 100))
            },
            completion: { [weak self] result in
                guard let self = self else { return }
                self.busy = false
                self.host?.setInstalling(false)
                self.installButton.isEnabled = true
                self.refreshBackgroundState()
                switch result {
                case .success:
                    self.progress.progress = 1
                    self.statusLabel.text = L10n.tr("wf_install_ok")
                    self.append(L10n.tr("wf_install_ok"))
                case .failure(let error):
                    self.statusLabel.text = L10n.tr("wf_install_fail")
                    self.append(error.localizedDescription)
                }
            }
        )
    }

    private func makePreviewThumbnail() -> UIImage? {
        view.layoutIfNeeded()
        let sourceSize = previewPanel.bounds.size
        let targetSize = CGSize(
            width: CGFloat(draft.geometry.thumbnailWidth),
            height: CGFloat(draft.geometry.thumbnailHeight)
        )
        guard sourceSize.width > 0, sourceSize.height > 0, targetSize.width > 0, targetSize.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            let path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: targetSize),
                cornerRadius: CGFloat(draft.geometry.thumbnailCornerRadius)
            )
            path.addClip()
            let scale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
            let x = (targetSize.width - sourceSize.width * scale) / 2
            let y = (targetSize.height - sourceSize.height * scale) / 2
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: x, y: y)
            context.cgContext.scaleBy(x: scale, y: scale)
            previewPanel.drawHierarchy(in: CGRect(origin: .zero, size: sourceSize), afterScreenUpdates: true)
            context.cgContext.restoreGState()
        }
    }

    private func configurePopover(_ controller: UIAlertController, sourceView: UIView) {
        controller.popoverPresentationController?.sourceView = sourceView
        controller.popoverPresentationController?.sourceRect = sourceView.bounds
    }

    private func color(from hex: String) -> UIColor {
        let value = UInt32(hex, radix: 16) ?? 0xFFFFFF
        return UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private func append(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logView.text = (logView.text ?? "") + "\(timestamp)  \(text)\n"
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        backgroundImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: JieliBackgroundCell.reuseIdentifier,
            for: indexPath
        ) as? JieliBackgroundCell else {
            return UICollectionViewCell()
        }
        cell.configure(image: backgroundImages[indexPath.item], isCover: indexPath.item == draft.coverImageIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard backgroundImages.indices.contains(indexPath.item) else { return }
        selectedBackgroundIndex = indexPath.item
        draft.coverImageIndex = indexPath.item
        refreshBackgroundState()
        refreshPreview()
    }
}
