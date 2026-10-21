import AudioToolbox
import AVFoundation
import PhotosUI
import UIKit
import Vision

// MARK: - List

/// E-card list. Aligns with HaWoFit `QrCardVC`: load from the watch, at most 3 cards, tap to edit.
final class ElectronicCardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let repo = BleRepository.shared
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UIHelpers.makeLabel("", style: .body)
    private let addItem = UIBarButtonItem()
    private var cards: [ElectronicCard] = []
    private var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        addItem.target = self
        addItem.action = #selector(tapAdd)
        navigationItem.rightBarButtonItem = addItem

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "card")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyChrome()
        reloadCards()
    }

    private func applyChrome() {
        title = L10n.tr("e_card")
        addItem.title = L10n.tr("ecard_add")
        showEmpty(loading && cards.isEmpty ? L10n.tr("ecard_loading") : L10n.tr("ecard_empty"))
        updateAddButton()
        tableView.reloadData()
    }

    private func updateAddButton() {
        let hasSlot = cards.count < ElectronicCardRules.maxCount
            && ElectronicCardRules.nextId(used: Set(cards.map(\.id))) != nil
        addItem.isEnabled = hasSlot && !loading
    }

    @objc private func pullToRefresh() {
        reloadCards()
    }

    private func reloadCards() {
        guard repo.isConnected() else {
            tableView.refreshControl?.endRefreshing()
            loading = false
            showEmpty(L10n.tr("status_need_connect"))
            updateAddButton()
            return
        }
        guard !loading else { return }
        loading = true
        updateAddButton()
        if cards.isEmpty { showEmpty(L10n.tr("ecard_loading")) }
        repo.getElectronicCards { [weak self] result in
            guard let self = self else { return }
            self.loading = false
            self.tableView.refreshControl?.endRefreshing()
            switch result {
            case .success(let list):
                self.cards = list
            case .failure(let error):
                self.presentNotice(error.localizedDescription)
            }
            self.showEmpty(L10n.tr("ecard_empty"))
            self.updateAddButton()
            self.tableView.reloadData()
        }
    }

    private func showEmpty(_ text: String) {
        emptyLabel.text = text
        tableView.backgroundView = cards.isEmpty ? emptyLabel : nil
    }

    @objc private func tapAdd() {
        guard let id = ElectronicCardRules.nextId(used: Set(cards.map(\.id))),
              cards.count < ElectronicCardRules.maxCount else {
            presentNotice(cards.count >= ElectronicCardRules.maxCount
                ? L10n.tr("ecard_limit")
                : L10n.tr("ecard_slots_full"))
            return
        }
        let editor = ElectronicCardEditViewController(card: nil, assignedId: id)
        navigationController?.pushViewController(editor, animated: true)
    }

    private func confirmDelete(_ card: ElectronicCard) {
        let alert = UIAlertController(
            title: L10n.tr("ecard_delete"),
            message: L10n.tr("ecard_delete_confirm"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("ecard_delete"), style: .destructive) { [weak self] _ in
            self?.delete(card)
        })
        present(alert, animated: true)
    }

    private func delete(_ card: ElectronicCard) {
        guard repo.isConnected() else {
            presentNotice(L10n.tr("status_need_connect"))
            return
        }
        loading = true
        updateAddButton()
        repo.deleteElectronicCard(id: card.id) { [weak self] result in
            guard let self = self else { return }
            self.loading = false
            switch result {
            case .success:
                self.cards.removeAll { $0.id == card.id }
                self.updateAddButton()
                self.tableView.reloadData()
            case .failure(let error):
                self.updateAddButton()
                self.presentNotice(error.localizedDescription)
            }
        }
    }

    private func presentNotice(_ message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: L10n.tr("e_card"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "card", for: indexPath)
        let card = cards[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = card.name.isEmpty ? L10n.tr("ecard_my_card") : card.name
        content.secondaryText = L10n.tr("ecard_id", card.id)
        content.image = UIImage(systemName: "qrcode")
        content.imageProperties.tintColor = .label
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let editor = ElectronicCardEditViewController(card: cards[indexPath.row], assignedId: cards[indexPath.row].id)
        navigationController?.pushViewController(editor, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let card = cards[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: L10n.tr("ecard_delete")) { [weak self] _, _, done in
            done(true)
            self?.confirmDelete(card)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if cards.count >= ElectronicCardRules.maxCount {
            return L10n.tr("ecard_hint") + "\n\n" + L10n.tr("ecard_limit")
        }
        return L10n.tr("ecard_hint")
    }
}

// MARK: - Edit

/// Add or edit one e-card. Aligns with HaWoFit `EditQrCardVC`.
final class ElectronicCardEditViewController: UIViewController, UITextFieldDelegate, PHPickerViewControllerDelegate {
    private let repo = BleRepository.shared
    private let existing: ElectronicCard?
    private let assignedId: Int
    private var qrContent = ""
    private var contentReady = false
    private var saving = false

    private let scroll = UIScrollView()
    private let contentStack = UIStackView()
    private let nameField = UITextField()
    private let nameLimitLabel = UIHelpers.makeLabel("", style: .footnote)
    private let qrButton = UIButton(type: .system)
    private let qrImageView = UIImageView()
    private let stepsTitle = UIHelpers.makeLabel("", style: .headline)
    private let step1 = UIHelpers.makeLabel("", style: .body)
    private let step2 = UIHelpers.makeLabel("", style: .body)
    private let statusLabel = UIHelpers.makeLabel("", style: .footnote)
    private let saveButton = UIHelpers.makeButton("", primary: true)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(card: ElectronicCard?, assignedId: Int) {
        self.existing = card
        self.assignedId = assignedId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        if existing != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(tapDelete)
            )
            navigationItem.rightBarButtonItem?.tintColor = .systemRed
        }
        setupLayout()
        nameField.text = existing?.name ?? L10n.tr("ecard_my_card")
        applyChrome()
        if let existing {
            loadContent(existing.id)
        } else {
            contentReady = true
            renderQR()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyChrome()
    }

    private func applyChrome() {
        title = L10n.tr("ecard_my_card")
        nameField.placeholder = L10n.tr("ecard_name")
        nameLimitLabel.text = L10n.tr("ecard_name_limit")
        stepsTitle.text = L10n.tr("ecard_steps")
        step1.text = L10n.tr("ecard_step_1")
        step2.text = L10n.tr("ecard_step_2")
        saveButton.setTitle(L10n.tr("ecard_save"), for: .normal)
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.tr("ecard_delete")
    }

    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag
        scroll.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(contentStack)

        nameField.borderStyle = .none
        nameField.backgroundColor = .tertiarySystemGroupedBackground
        nameField.layer.cornerRadius = 10
        nameField.font = .preferredFont(forTextStyle: .body)
        nameField.clearButtonMode = .whileEditing
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        nameField.leftViewMode = .always
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        nameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        nameLimitLabel.textColor = .secondaryLabel

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.tintColor = .tertiaryLabel
        qrImageView.isUserInteractionEnabled = false
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        qrButton.backgroundColor = .secondarySystemGroupedBackground
        qrButton.layer.cornerRadius = 14
        qrButton.clipsToBounds = true
        qrButton.addTarget(self, action: #selector(tapQR), for: .touchUpInside)
        qrButton.addSubview(qrImageView)
        qrButton.heightAnchor.constraint(equalToConstant: 220).isActive = true
        NSLayoutConstraint.activate([
            qrImageView.centerXAnchor.constraint(equalTo: qrButton.centerXAnchor),
            qrImageView.centerYAnchor.constraint(equalTo: qrButton.centerYAnchor),
            qrImageView.widthAnchor.constraint(equalToConstant: 180),
            qrImageView.heightAnchor.constraint(equalToConstant: 180)
        ])

        step1.textColor = .secondaryLabel
        step2.textColor = .secondaryLabel
        statusLabel.textColor = .secondaryLabel
        spinner.hidesWhenStopped = true

        let statusRow = UIStackView(arrangedSubviews: [spinner, statusLabel])
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center

        saveButton.addTarget(self, action: #selector(tapSave), for: .touchUpInside)

        contentStack.addArrangedSubview(UIHelpers.makeCard([nameField, nameLimitLabel], title: L10n.tr("ecard_name")))
        contentStack.addArrangedSubview(UIHelpers.makeCard([qrButton]))
        contentStack.addArrangedSubview(UIHelpers.makeCard([stepsTitle, step1, step2, statusRow]))
        contentStack.addArrangedSubview(saveButton)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func loadContent(_ id: Int) {
        setBusy(true, status: L10n.tr("ecard_loading_content"))
        repo.getElectronicCardContent(id: id) { [weak self] result in
            guard let self = self else { return }
            self.setBusy(false, status: "")
            switch result {
            case .success(let text):
                self.qrContent = text
                self.contentReady = true
                self.renderQR()
            case .failure(let error):
                self.presentNotice(error.localizedDescription) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func renderQR() {
        if let image = ElectronicCardQR.image(from: qrContent) {
            qrImageView.image = image
            qrImageView.contentMode = .scaleAspectFit
        } else {
            qrImageView.image = UIImage(systemName: "qrcode")
            qrImageView.contentMode = .scaleAspectFit
        }
    }

    @objc private func nameChanged() {
        guard nameField.markedTextRange == nil else { return }
        guard var text = nameField.text, text.utf16.count > ElectronicCardRules.maxNameUTF16 else { return }
        while text.utf16.count > ElectronicCardRules.maxNameUTF16 {
            text.removeLast()
        }
        nameField.text = text
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        true
    }

    @objc private func tapQR() {
        view.endEditing(true)
        let sheet = UIAlertController(title: L10n.tr("ecard_source"), message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: L10n.tr("ecard_scan"), style: .default) { [weak self] _ in
            self?.openScanner()
        })
        sheet.addAction(UIAlertAction(title: L10n.tr("ecard_album"), style: .default) { [weak self] _ in
            self?.openAlbum()
        })
        sheet.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = qrButton
            pop.sourceRect = qrButton.bounds
        }
        present(sheet, animated: true)
    }

    private func openScanner() {
        let scanner = ElectronicCardScannerViewController()
        scanner.onResult = { [weak self] text in
            self?.applyQR(text)
        }
        navigationController?.pushViewController(scanner, animated: true)
    }

    private func openAlbum() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            ElectronicCardQR.decode(image) { text in
                guard let self = self else { return }
                if let text, !text.isEmpty {
                    self.applyQR(text)
                } else {
                    self.presentNotice(L10n.tr("ecard_scan_failed"))
                }
            }
        }
    }

    private func applyQR(_ text: String) {
        qrContent = text
        contentReady = true
        statusLabel.text = ""
        renderQR()
    }

    @objc private func tapSave() {
        guard !saving, contentReady else { return }
        view.endEditing(true)
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            presentNotice(L10n.tr("ecard_need_name"))
            return
        }
        guard !qrContent.isEmpty else {
            presentNotice(L10n.tr("ecard_need_qr"))
            return
        }
        guard repo.isConnected() else {
            presentNotice(L10n.tr("status_need_connect"))
            return
        }
        saving = true
        setBusy(true, status: L10n.tr("ecard_saving"))
        let card = ElectronicCard(id: existing?.id ?? assignedId, name: name, content: qrContent)
        let finish: (Result<Void, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            self.saving = false
            self.setBusy(false, status: "")
            switch result {
            case .success:
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                self.presentNotice(error.localizedDescription)
            }
        }
        if existing == nil {
            repo.addElectronicCard(card, completion: finish)
        } else {
            repo.editElectronicCard(card, completion: finish)
        }
    }

    @objc private func tapDelete() {
        guard let existing, !saving else { return }
        let alert = UIAlertController(
            title: L10n.tr("ecard_delete"),
            message: L10n.tr("ecard_delete_confirm"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("ecard_delete"), style: .destructive) { [weak self] _ in
            self?.performDelete(existing)
        })
        present(alert, animated: true)
    }

    private func performDelete(_ card: ElectronicCard) {
        guard repo.isConnected() else {
            presentNotice(L10n.tr("status_need_connect"))
            return
        }
        saving = true
        setBusy(true, status: L10n.tr("ecard_deleting"))
        repo.deleteElectronicCard(id: card.id) { [weak self] result in
            guard let self = self else { return }
            self.saving = false
            self.setBusy(false, status: "")
            switch result {
            case .success:
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                self.presentNotice(error.localizedDescription)
            }
        }
    }

    private func setBusy(_ busy: Bool, status: String) {
        statusLabel.text = status
        saveButton.isEnabled = !busy
        navigationItem.rightBarButtonItem?.isEnabled = !busy
        if busy { spinner.startAnimating() } else { spinner.stopAnimating() }
    }

    private func presentNotice(_ message: String, then completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: L10n.tr("e_card"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

// MARK: - Scanner

/// Camera QR scan plus album fallback. Aligns with HaWoFit `QrCardScannerVC`.
final class ElectronicCardScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, PHPickerViewControllerDelegate {
    var onResult: ((String) -> Void)?

    private let session = AVCaptureSession()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let hintLabel = UIHelpers.makeLabel("", style: .body)
    private var found = false
    private var configured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = L10n.tr("ecard_scan")
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
        view.layer.addSublayer(previewLayer)

        hintLabel.text = L10n.tr("ecard_scan_hint")
        hintLabel.textColor = .white
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        let album = UIHelpers.makeButton(L10n.tr("ecard_album"))
        album.translatesAutoresizingMaskIntoConstraints = false
        album.addTarget(self, action: #selector(openAlbum), for: .touchUpInside)

        let frame = UIView()
        frame.translatesAutoresizingMaskIntoConstraints = false
        frame.layer.borderColor = UIColor.white.cgColor
        frame.layer.borderWidth = 2
        frame.layer.cornerRadius = 12
        frame.isUserInteractionEnabled = false

        view.addSubview(frame)
        view.addSubview(hintLabel)
        view.addSubview(album)
        NSLayoutConstraint.activate([
            frame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frame.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            frame.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            frame.heightAnchor.constraint(equalTo: frame.widthAnchor),
            hintLabel.topAnchor.constraint(equalTo: frame.bottomAnchor, constant: 24),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            album.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 24),
            album.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            album.widthAnchor.constraint(equalToConstant: 180)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = L10n.tr("ecard_scan")
        hintLabel.text = L10n.tr("ecard_scan_hint")
        found = false
        requestCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.stopRunning()
            }
        }
    }

    private func requestCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentNotice(L10n.tr("ecard_camera_unavailable"))
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.startCamera() }
                    else { self?.presentCameraDenied() }
                }
            }
        default:
            presentCameraDenied()
        }
    }

    private func startCamera() {
        if !configured {
            session.beginConfiguration()
            session.sessionPreset = .high
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                presentNotice(L10n.tr("ecard_camera_unavailable"))
                return
            }
            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                presentNotice(L10n.tr("ecard_camera_unavailable"))
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            if output.availableMetadataObjectTypes.contains(.qr) {
                output.metadataObjectTypes = [.qr]
            }
            session.commitConfiguration()
            configured = true
        }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !found,
              let value = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first?.stringValue,
              !value.isEmpty else { return }
        found = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            if session.isRunning { session.stopRunning() }
        }
        onResult?(value)
        navigationController?.popViewController(animated: true)
    }

    @objc private func openAlbum() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            ElectronicCardQR.decode(image) { text in
                guard let self = self else { return }
                if let text, !text.isEmpty {
                    self.found = true
                    self.onResult?(text)
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.presentNotice(L10n.tr("ecard_scan_failed"))
                }
            }
        }
    }

    private func presentCameraDenied() {
        let alert = UIAlertController(
            title: L10n.tr("ecard_permission_title"),
            message: L10n.tr("ecard_camera_denied"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: L10n.tr("ecard_settings"), style: .default) { [weak self] _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func presentNotice(_ message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: L10n.tr("ecard_scan"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - QR helpers

enum ElectronicCardQR {
    private static let context = CIContext()

    static func image(from text: String, side: CGFloat = 180) -> UIImage? {
        guard !text.isEmpty,
              let data = text.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let extent = output.extent.integral
        let scale = max(1, floor(side / extent.width))
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func decode(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = cgImage(from: image) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        let request = VNDetectBarcodesRequest { request, _ in
            let code = (request.results as? [VNBarcodeObservation])?
                .first { $0.symbology == .qr }?
                .payloadStringValue
            DispatchQueue.main.async { completion(code) }
        }
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(image.imageOrientation))
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    private static func cgImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage { return cgImage }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let rendered = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return rendered.cgImage
    }

    private static func cgOrientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
