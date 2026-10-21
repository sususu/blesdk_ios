import UIKit
import AiSDK

/// Product-style health report, aligned with HaWoFit and the Android SDK demo.
/// Watch Generate Report is delivered by `AiSDK.startWorking` → `aiHealthAnalysisDone`.
/// This page chains the existing `AiSDKCallback` and does not call `stopWorking`.
final class AiHealthAnalysisViewController: UIViewController {
    private let repo = BleRepository.shared
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let emptyStack = UIStackView()
    private let resultStack = UIStackView()
    private let statusRow = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UIHelpers.makeLabel("", style: .footnote)
    private let generateButton = UIHelpers.makeButton("", primary: true)
    private let emptyLabel = UIHelpers.makeLabel("", style: .body)

    private var displayed: AiHealthAnalysisRecord?
    private var busy = false
    private var requestID: UUID?
    private var timeout: DispatchWorkItem?
    private var handler: DefaultHealthAnalysisResultHandler?
    private var callbackProxy: AiHealthAnalysisCallbackProxy?
    private var listening = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        displayed = AiHealthAnalysisStore.latest()

        let history = UIBarButtonItem(
            image: UIImage(systemName: "clock.arrow.circlepath"),
            style: .plain,
            target: self,
            action: #selector(tapRecords)
        )
        history.accessibilityIdentifier = "ai_health_records"
        navigationItem.rightBarButtonItem = history

        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        emptyStack.axis = .vertical
        emptyStack.spacing = 16
        emptyStack.alignment = .center
        let icon = UIImageView(image: UIImage(systemName: "heart.text.square"))
        icon.tintColor = .secondaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 72).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 72).isActive = true
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyStack.addArrangedSubview(icon)
        emptyStack.addArrangedSubview(emptyLabel)
        emptyStack.isLayoutMarginsRelativeArrangement = true
        emptyStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 48, leading: 24, bottom: 24, trailing: 24)

        resultStack.axis = .vertical
        resultStack.spacing = 12
        content.addArrangedSubview(emptyStack)
        content.addArrangedSubview(resultStack)

        spinner.hidesWhenStopped = true
        statusLabel.textColor = .secondaryLabel
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center
        statusRow.addArrangedSubview(spinner)
        statusRow.addArrangedSubview(statusLabel)
        statusRow.isHidden = true

        generateButton.accessibilityIdentifier = "ai_health_generate"
        generateButton.addTarget(self, action: #selector(tapGenerate), for: .touchUpInside)

        let bottom = UIStackView(arrangedSubviews: [statusRow, generateButton])
        bottom.axis = .vertical
        bottom.spacing = 8
        bottom.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottom)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottom.topAnchor, constant: -8),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
            bottom.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bottom.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        applyChrome()
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyChrome()
        render()
        startDeviceListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || isBeingDismissed else { return }
        cancelDemoRequest()
        stopDeviceListening()
    }

    private func applyChrome() {
        title = L10n.tr("ai_health_analysis")
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.tr("ai_health_records")
        emptyLabel.text = L10n.tr("ai_health_empty")
        generateButton.setTitle(L10n.tr("ai_health_generate"), for: .normal)
    }

    private func render() {
        let record = displayed
        let metrics = record?.metrics ?? []
        let hasContent = record != nil && (!metrics.isEmpty || !(record?.summary.isEmpty ?? true))
        emptyStack.isHidden = hasContent
        resultStack.isHidden = !hasContent
        resultStack.arrangedSubviews.forEach {
            resultStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let record, hasContent else { return }

        let time = UIHelpers.makeLabel(record.timeText(), style: .subheadline)
        time.textColor = .secondaryLabel
        resultStack.addArrangedSubview(time)

        for metric in metrics {
            resultStack.addArrangedSubview(metricCard(symbol: metric.symbol, title: L10n.tr(metric.titleKey), body: metric.body))
        }
        if !record.summary.isEmpty {
            resultStack.addArrangedSubview(summaryCard(record.summary))
        }
    }

    private func metricCard(symbol: String, title: String, body: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let titleLabel = UIHelpers.makeLabel(title, style: .headline)
        let header = UIStackView(arrangedSubviews: [icon, titleLabel])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center

        let bodyLabel = UIHelpers.makeLabel(body, style: .body)
        bodyLabel.textColor = .label
        return UIHelpers.makeCard([header, bodyLabel])
    }

    private func summaryCard(_ summary: String) -> UIView {
        let card = metricCard(symbol: "sparkles", title: L10n.tr("ai_health_summary"), body: summary)
        card.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        return card
    }

    @objc private func tapRecords() {
        let records = AiHealthAnalysisRecordsViewController()
        records.onSelect = { [weak self] record in
            self?.displayed = record
            self?.showStatus("")
        }
        navigationController?.pushViewController(records, animated: true)
    }

    @objc private func tapGenerate() {
        guard !busy else { return }
        guard repo.isConnected() else {
            showStatus(L10n.tr("status_need_connect"))
            return
        }
        let token = UUID()
        requestID = token
        setBusy(true)
        showStatus(L10n.tr("ai_health_generating"))
        let work = DispatchWorkItem { [weak self] in
            self?.fail(token, message: L10n.tr("ai_analysis_timeout"))
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 90, execute: work)
        let deviceUUID = repo.connectedUUID()
        repo.getDeviceInfo { [weak self] result in
            guard let self, self.requestID == token else { return }
            guard self.repo.isConnected(), self.repo.connectedUUID() == deviceUUID else {
                self.fail(token, message: L10n.tr("status_need_connect"))
                return
            }
            switch result {
            case .failure(let error):
                self.fail(token, message: error.localizedDescription)
            case .success(let device):
                guard let id = device.id, !id.isEmpty else {
                    self.fail(token, message: L10n.tr("ai_analysis_need_device"))
                    return
                }
                self.ensureDeviceInfo(id: id, protocolVersion: device.protocolVersion)
                self.send(token)
            }
        }
    }

    /// Keeps an existing AI DEMO device profile. A full replace can `cancelAll` when id, locale, or platform differ.
    private func ensureDeviceInfo(id: String, protocolVersion: Int?) {
        let ai = AiSDK.sharedInstance()
        if let existing = currentDeviceInfo() {
            if existing.healthAnalysisAppOnly {
                existing.healthAnalysisAppOnly = false
                ai.setDeviceInfo(existing)
            }
            return
        }
        guard !id.isEmpty else { return }
        let panel = AiDeviceInfoBuilder.Panel(
            width: 480, height: 480, cornerRadius: 240,
            thumbnailWidth: 264, thumbnailHeight: 264, thumbnailCornerRadius: 132
        )
        let prefersJieli = AiPlatformHelper.isJieliProtocol(protocolVersion)
        let info = AiDeviceInfoBuilder.make(
            repo: repo,
            deviceId: id,
            panel: panel,
            protocolVersion: protocolVersion,
            userPrefersJieli: prefersJieli,
            locale: LocaleHelper.current == .zh ? "zh" : (LocaleHelper.current == .en ? "en" : nil)
        )
        info.supportedLocales = ["zh", "en"]
        info.healthAnalysisAppOnly = false
        ai.setDeviceInfo(info)
    }

    private func send(_ token: UUID) {
        guard requestID == token else { return }
        let handler = DefaultHealthAnalysisResultHandler()
        handler.appOnly = true
        self.handler = handler
        handler.analysis(AiAnalysisMock.exercise())
    }

    private func handleHealthResult(_ result: HwHealthAnalysisResult?, code: Int, message: String?) {
        let deliver = { [weak self] in
            guard let self else { return }
            if let token = self.requestID {
                if code == 0, let result {
                    self.succeed(token, result)
                } else {
                    let text = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    self.fail(token, message: text.isEmpty ? L10n.tr("ai_health_failed") : text)
                }
                return
            }
            guard code == 0, let result else {
                let text = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.showStatus(text.isEmpty ? L10n.tr("ai_health_failed") : text)
                return
            }
            let summary = self.trimmed(result.summary)
            guard !summary.isEmpty else {
                self.showStatus(L10n.tr("ai_analysis_empty"))
                return
            }
            let record = self.record(from: result, summary: summary)
            AiHealthAnalysisStore.save(record)
            self.displayed = record
            self.showStatus(L10n.tr("ai_health_received"))
            self.render()
        }
        if Thread.isMainThread { deliver() } else { DispatchQueue.main.async(execute: deliver) }
    }

    private func succeed(_ token: UUID, _ result: HwHealthAnalysisResult) {
        guard requestID == token else { return }
        let summary = trimmed(result.summary)
        guard !summary.isEmpty else {
            fail(token, message: L10n.tr("ai_analysis_empty"))
            return
        }
        let record = record(from: result, summary: summary)
        cleanupRequest()
        setBusy(false)
        AiHealthAnalysisStore.save(record)
        displayed = record
        showStatus(L10n.tr("ai_health_saved"))
        render()
    }

    private func fail(_ token: UUID, message: String) {
        guard requestID == token else { return }
        cleanupRequest()
        setBusy(false)
        showStatus(message)
    }

    private func startDeviceListening() {
        let ai = AiSDK.sharedInstance()
        if callbackProxy == nil {
            let current = ai.value(forKey: "callback") as? AiSDKCallback
            let proxy = AiHealthAnalysisCallbackProxy(previous: current) { [weak self] result, code, message in
                self?.handleHealthResult(result, code: code, message: message)
            }
            callbackProxy = proxy
            ai.callback = proxy
        } else if (ai.value(forKey: "callback") as AnyObject?) !== callbackProxy, let proxy = callbackProxy {
            proxy.previous = ai.value(forKey: "callback") as? AiSDKCallback
            ai.callback = proxy
        }
        ai.startWorking()
        listening = true
        if currentDeviceInfo() == nil {
            guard repo.isConnected() else {
                if !busy { showStatus(L10n.tr("status_need_connect")) }
                return
            }
            repo.getDeviceInfo { [weak self] result in
                guard let self, self.listening else { return }
                if case .success(let device) = result, let id = device.id, !id.isEmpty {
                    self.ensureDeviceInfo(id: id, protocolVersion: device.protocolVersion)
                }
                if !self.busy { self.showStatus(L10n.tr("ai_health_waiting")) }
            }
        } else {
            ensureDeviceInfo(id: "", protocolVersion: nil)
            if !busy { showStatus(L10n.tr("ai_health_waiting")) }
        }
    }

    private func stopDeviceListening() {
        listening = false
        let ai = AiSDK.sharedInstance()
        if let callbackProxy, (ai.value(forKey: "callback") as AnyObject?) === callbackProxy {
            if let previous = callbackProxy.previous {
                ai.callback = previous
            } else {
                ai.setValue(nil, forKey: "callback")
            }
        }
        self.callbackProxy = nil
    }

    private func currentDeviceInfo() -> AiDeviceInfo? {
        guard let value = AiSDK.sharedInstance().perform(NSSelectorFromString("getDeviceInfo"))?.takeUnretainedValue() else { return nil }
        let info = value as? AiDeviceInfo
        let id = (info?.value(forKey: "Id") as? String) ?? ""
        return id.isEmpty ? nil : info
    }

    private func record(from result: HwHealthAnalysisResult, summary: String) -> AiHealthAnalysisRecord {
        AiHealthAnalysisRecord(
            time: Int64(Date().timeIntervalSince1970 * 1000),
            step: trimmed(result.step),
            heartRate: trimmed(result.heartRate),
            sleep: trimmed(result.sleep),
            spO2: trimmed(result.spO2),
            stress: trimmed(result.stress),
            pai: trimmed(result.pai),
            weight: trimmed(result.weight),
            summary: summary
        )
    }

    private func cancelDemoRequest() {
        requestID = nil
        timeout?.cancel()
        timeout = nil
        handler?.cancel()
        handler = nil
        setBusy(false)
    }

    private func cleanupRequest() {
        requestID = nil
        timeout?.cancel()
        timeout = nil
        handler?.cancel()
        handler = nil
    }

    private func setBusy(_ busy: Bool) {
        self.busy = busy
        generateButton.isEnabled = !busy
        navigationItem.rightBarButtonItem?.isEnabled = !busy
        if busy { spinner.startAnimating() } else { spinner.stopAnimating() }
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text
        statusRow.isHidden = text.isEmpty
    }

    private func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

struct AiHealthAnalysisRecord: Codable {
    var time: Int64
    var step: String
    var heartRate: String
    var sleep: String
    var spO2: String
    var stress: String
    var pai: String
    var weight: String
    var summary: String

    var date: Date { Date(timeIntervalSince1970: TimeInterval(time) / 1000) }

    var metrics: [(symbol: String, titleKey: String, body: String)] {
        [
            ("figure.walk", "ai_health_steps", step),
            ("heart.fill", "ai_health_hr", heartRate),
            ("moon.fill", "ai_health_sleep", sleep),
            ("drop.fill", "ai_health_spo2", spO2),
            ("brain.head.profile", "ai_health_stress", stress),
            ("flame.fill", "ai_health_pai", pai),
            ("scalemass.fill", "ai_health_weight", weight)
        ].filter { !$0.body.isEmpty }
    }

    func timeText() -> String {
        let clock = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        if Calendar.current.isDateInToday(date) {
            return "\(L10n.tr("ai_health_today")) \(clock)"
        }
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.dateFormat = "MM-dd"
        return "\(day.string(from: date)) \(clock)"
    }
}

enum AiHealthAnalysisStore {
    private static let key = "demo.aiHealthAnalysis.records"

    static func latest() -> AiHealthAnalysisRecord? { all().first }

    static func all() -> [AiHealthAnalysisRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([AiHealthAnalysisRecord].self, from: data) else { return [] }
        return records.sorted { $0.time > $1.time }
    }

    static func save(_ record: AiHealthAnalysisRecord) {
        var records = all()
        let day = dayKey(record.date)
        if let index = records.firstIndex(where: { dayKey($0.date) == day }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
        records.sort { $0.time > $1.time }
        if records.count > 100 { records = Array(records.prefix(100)) }
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func sections() -> [(month: String, records: [AiHealthAnalysisRecord])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        var order: [String] = []
        var grouped: [String: [AiHealthAnalysisRecord]] = [:]
        for record in all() {
            let month = formatter.string(from: record.date)
            if grouped[month] == nil {
                order.append(month)
                grouped[month] = []
            }
            grouped[month, default: []].append(record)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// Forwards every AiSDK callback to the previous owner, and also reports health results here.
final class AiHealthAnalysisCallbackProxy: NSObject, AiSDKCallback {
    var previous: AiSDKCallback?
    private let onHealth: (HwHealthAnalysisResult?, Int, String?) -> Void

    init(previous: AiSDKCallback?, onHealth: @escaping (HwHealthAnalysisResult?, Int, String?) -> Void) {
        self.previous = previous
        self.onHealth = onHealth
    }

    func aiStartRecording(_ type: Int) { previous?.aiStartRecording?(type) }
    func aiStopRecording(_ type: Int) { previous?.aiStopRecording?(type) }
    func aiVoice(toTextDone text: String?, type: Int) { previous?.aiVoice?(toTextDone: text ?? "", type: type) }
    func aiAnswerDone(_ result: String?, code: Int, errorMsg: String?) { previous?.aiAnswerDone?(result, code: code, errorMsg: errorMsg) }
    func aiTranslateDone(_ result: String?, code: Int, errorMsg: String?) { previous?.aiTranslateDone?(result, code: code, errorMsg: errorMsg) }
    func aiAgentDone(_ result: String?, code: Int, errorMsg: String?) { previous?.aiAgentDone?(result, code: code, errorMsg: errorMsg) }
    func aiMeetingDone(_ meeting: HwMeeting?, voiceFilePath: String?, meetingTime: Date?, code: Int, errorMsg: String?) {
        previous?.aiMeetingDone?(meeting, voiceFilePath: voiceFilePath, meetingTime: meetingTime, code: code, errorMsg: errorMsg)
    }
    func aiHealthAnalysisDone(_ result: HwHealthAnalysisResult?, code: Int, errorMsg: String?) {
        onHealth(result, code, errorMsg)
        previous?.aiHealthAnalysisDone?(result, code: code, errorMsg: errorMsg)
    }
    func aiImageDone(_ image: UIImage?, code: Int, errorMsg: String?) {
        previous?.aiImageDone?(image ?? UIImage(), code: code, errorMsg: errorMsg)
    }
    func aiPreviewDone(_ image: UIImage?, code: Int, errorMsg: String?) {
        previous?.aiPreviewDone?(image ?? UIImage(), code: code, errorMsg: errorMsg)
    }
    func aiStartSendingPreview() { previous?.aiStartSendingPreview?() }
    func aiSentPreview(_ code: Int, errorMsg: String?) { previous?.aiSentPreview?(code, errorMsg: errorMsg) }
    func aiStartSendingWatchface() { previous?.aiStartSendingWatchface?() }
    func aiSendingWatchfaceProgressUpdated(_ progress: Float) { previous?.aiSendingWatchfaceProgressUpdated?(progress) }
    func aiSentWatchface(_ watchface: SlifiCustomWatchface?, code: Int, errorMsg: String?) {
        previous?.aiSentWatchface?(watchface, code: code, errorMsg: errorMsg)
    }
    func aiDidEnterTranslate(withInputLangugae inputLanguage: Int, outputLanguage: Int) {
        previous?.aiDidEnterTranslate?(withInputLangugae: inputLanguage, outputLanguage: outputLanguage)
    }
    func aiDidRequestAiTranslateResult() { previous?.aiDidRequestAiTranslateResult?() }
}

final class AiHealthAnalysisRecordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var onSelect: ((AiHealthAnalysisRecord) -> Void)?
    private var sections: [(month: String, records: [AiHealthAnalysisRecord])] = []
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UIHelpers.makeLabel("", style: .body)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "record")
        view.addSubview(table)

        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = L10n.tr("ai_health_records")
        emptyLabel.text = L10n.tr("ai_health_records_empty")
        sections = AiHealthAnalysisStore.sections()
        emptyLabel.isHidden = !sections.isEmpty
        table.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].records.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].month
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "record", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section].records[indexPath.row].timeText()
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect?(sections[indexPath.section].records[indexPath.row])
        navigationController?.popViewController(animated: true)
    }
}
