import UIKit
import AiSDK

final class AiAnalysisViewController: FeatureBaseViewController, AiSDKCallback {
    enum Kind: Int, CaseIterable {
        case exercise, insight, body, sleepDay, sleepWeek, sleepMonth
        var titleKey: String { ["ai_analysis_exercise", "ai_analysis_insight", "ai_analysis_body", "ai_analysis_sleep_day", "ai_analysis_sleep_week", "ai_analysis_sleep_month"][rawValue] }
        var period: Int { rawValue - Kind.sleepDay.rawValue }
    }
    private let kind: Kind
    private let channel = UITextField()
    private let appKey = UITextField()
    private var requestID: UUID?
    private var timeout: DispatchWorkItem?
    private var completion: ((Result<String, Error>) -> Void)?
    private var previousCallback: AiSDKCallback?
    private var handler: DefaultHealthAnalysisResultHandler?

    init(kind: Kind) { self.kind = kind; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        title = L10n.tr(kind.titleKey)
        super.viewDidLoad()
    }

    override func buildActions() {
        actionsStack.addArrangedSubview(UIHelpers.makeLabel(L10n.tr("ai_analysis_mock_note"), style: .footnote))
        if kind != .exercise {
            for (field, placeholder) in [(channel, "OAS Channel ID"), (appKey, "OAS App Key")] {
                field.placeholder = placeholder
                field.borderStyle = .roundedRect
                field.autocorrectionType = .no
                field.autocapitalizationType = .none
                field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
                field.accessibilityLabel = placeholder
                actionsStack.addArrangedSubview(field)
            }
            appKey.isSecureTextEntry = false
            channel.text = ProcessInfo.processInfo.environment["AI_OAS_CHANNEL_ID"] ?? "3ba3da7850ef1216"
            appKey.text = ProcessInfo.processInfo.environment["AI_OAS_APP_KEY"] ?? "wvpN7oWEDNMobV5NqlZ2KMVgNy3UVYIHGTBilfcPDWmu6akkAn+Ha7K5C5oKGAgbB+ZKtog7tNo/hv2/dHf5BQbSDngVlbT+HD7SPQ1b4F1psCR2PaTPlLS6dauYYQc4iNgxR0LurPjpBfcxXgkQUq9R"
        }
        addAction(L10n.tr("ai_analysis_input")) { [weak self] in
            guard let self else { return }
            self.resultLabel.text = self.mockPreview()
        }
        addAction(L10n.tr("ai_analysis_generate")) { [weak self] in self?.generate() }
        resultLabel.text = mockPreview()
    }

    private func mockPreview() -> String {
        if kind.period >= 0 {
            let input = AiAnalysisMock.sleep(period: kind.period)
            return "\(input.date)\n" + zip(input.sleepHours, input.getUpHours).enumerated().map {
                "\($0.offset + 1). \($0.element.0) → \($0.element.1)"
            }.joined(separator: "\n")
        }
        return L10n.tr(kind == .exercise ? "ai_analysis_mock_exercise" : (kind == .insight ? "ai_analysis_mock_insight" : "ai_analysis_mock_body"))
    }

    private func generate() {
        guard repo.isConnected() else { statusLabel.text = L10n.tr("status_need_connect"); return }
        let channelID = (channel.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (appKey.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard kind == .exercise || (!channelID.isEmpty && !key.isEmpty) else {
            statusLabel.text = L10n.tr("ai_analysis_need_channel"); return
        }
        view.endEditing(true)
        run(L10n.tr("ai_analysis_generating")) { done in
            self.completion = done
            self.channel.isEnabled = false
            self.appKey.isEnabled = false
            let token = UUID()
            self.requestID = token
            let deviceUUID = self.repo.connectedUUID()
            let work = DispatchWorkItem { [weak self] in
                self?.finish(token, result: .failure(SdkError(code: -1, message: L10n.tr("ai_analysis_timeout"))))
            }
            self.timeout = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 90, execute: work)
            self.repo.getDeviceInfo { [weak self] result in
                guard let self, self.requestID == token else { return }
                guard self.repo.isConnected(), self.repo.connectedUUID() == deviceUUID else {
                    self.finish(token, result: .failure(SdkError(code: -1, message: L10n.tr("status_need_connect")))); return
                }
                switch result {
                case .failure(let error): self.finish(token, result: .failure(error))
                case .success(let device):
                    guard let id = device.id, !id.isEmpty else {
                        self.finish(token, result: .failure(SdkError(code: -1, message: L10n.tr("ai_analysis_need_device")))); return
                    }
                    let ai = AiSDK.sharedInstance()
                    if self.kind != .exercise {
                        AiOASClient.shared.configure(channelId: channelID, appKey: key, appUuid: nil, appChannel: nil)
                    }
                    let panel = AiDeviceInfoBuilder.Panel(width: 480, height: 480, cornerRadius: 240,
                        thumbnailWidth: 264, thumbnailHeight: 264, thumbnailCornerRadius: 132)
                    let info = AiDeviceInfoBuilder.make(repo: self.repo, deviceId: id, panel: panel,
                        protocolVersion: device.protocolVersion, userPrefersJieli: true,
                        locale: LocaleHelper.current == .zh ? "zh" : (LocaleHelper.current == .en ? "en" : nil))
                    info.supportedLocales = ["zh", "en"]
                    info.healthAnalysisAppOnly = true
                    ai.setDeviceInfo(info)
                    self.send(token)
                }
            }
        }
    }

    private func send(_ token: UUID) {
        let ai = AiSDK.sharedInstance()
        switch kind {
        case .exercise:
            previousCallback = ai.value(forKey: "callback") as? AiSDKCallback
            ai.callback = self
            let handler = DefaultHealthAnalysisResultHandler()
            handler.appOnly = true
            self.handler = handler
            handler.analysis(AiAnalysisMock.exercise())
        case .insight:
            ai.generateExerciseInsight(AiAnalysisMock.insight()) { [weak self] result, error in
                let text = result.map { "\($0.title)\n\n\($0.content)\n\n" + L10n.tr("ai_analysis_reminder", $0.reminderType) + "\n" + ($0.mood ?? "") }
                self?.complete(token, text: text, error: error)
            }
        case .body:
            ai.generateBodyStatus(AiAnalysisMock.body()) { [weak self] result, error in
                let text = result.map { "\($0.title)\n\n\($0.level) · \($0.rating)/100\n\n\($0.content)" }
                self?.complete(token, text: text, error: error)
            }
        case .sleepDay, .sleepWeek, .sleepMonth:
            ai.generateSleepChronotype(AiAnalysisMock.sleep(period: kind.period)) { [weak self] result, error in
                let text = result.map { "\($0.bestTime)\n\($0.bestTimeIntro)\n\n\($0.chronotypeIntro)\n\n\($0.adjustmentIntro)\n\n\($0.sleepPlanStart) → \($0.sleepPlanEnd)" }
                self?.complete(token, text: text, error: error)
            }
        }
    }

    func aiHealthAnalysisDone(_ result: HwHealthAnalysisResult?, code: Int, errorMsg: String?) {
        guard kind == .exercise, let token = requestID else { return }
        let text = result.map { [$0.step, $0.heartRate, $0.spO2, $0.stress, $0.bp, $0.sleep, $0.pai, $0.weight, $0.summary].joined(separator: "\n\n") }
        let error: Error? = code == 0 ? nil : SdkError(code: code, message: errorMsg ?? "AI error \(code)")
        complete(token, text: text, error: error)
    }

    private func complete(_ token: UUID, text: String?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error { self?.finish(token, result: .failure(error)) }
            else if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self?.finish(token, result: .success(text))
            } else { self?.finish(token, result: .failure(SdkError(code: -1, message: L10n.tr("ai_analysis_empty")))) }
        }
    }

    private func finish(_ token: UUID, result: Result<String, Error>) {
        guard requestID == token else { return }
        requestID = nil
        timeout?.cancel()
        timeout = nil
        handler?.cancel()
        handler = nil
        let ai = AiSDK.sharedInstance()
        if (ai.value(forKey: "callback") as AnyObject?) === self { ai.setValue(previousCallback, forKey: "callback") }
        previousCallback = nil
        channel.isEnabled = true
        appKey.isEnabled = true
        let done = completion
        completion = nil
        done?(result)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = requestID {
            finish(token, result: .failure(SdkError(code: -1, message: L10n.tr("ai_analysis_cancelled"))))
        }
    }
}

// Mock only the input measurements; all reports come from the real SDK services.
enum AiAnalysisMock {
    static func date(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: value)
    }

    static func sleep(period: Int, now: Date = Date()) -> AiSleepChronotypeInput {
        precondition((0...2).contains(period))
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: now)
        let count = period == 0 ? 1 : (period == 1 ? 7 : calendar.component(.day, from: today))
        let first = calendar.date(byAdding: .day, value: -(count - 1), to: today)!
        let input = AiSleepChronotypeInput()
        input.period = period
        input.use12HourClock = false
        input.date = period == 0 ? date(today) : "\(date(today))-\(date(first))"
        input.sleepHours = (0..<count).map { ["23:10:00", "22:55:00", "23:25:00"][$0 % 3] }
        input.getUpHours = (0..<count).map { ["07:05:00", "06:55:00", "07:15:00"][$0 % 3] }
        return input
    }

    static func insight(now: Date = Date()) -> AiExerciseInsightInput {
        let input = AiExerciseInsightInput()
        input.date = "\(date(now))-\(date(Calendar.current.date(byAdding: .day, value: -6, to: now)!))"
        input.stepGoal = 8000; input.activityDurationGoalMinutes = 60; input.calorieGoalKcal = 350
        input.steps = [8200, 7600, 9100, 6300, 8500, 7200, 8800]
        input.activityDurationMinutes = [55, 45, 62, 35, 58, 42, 60]
        input.caloriesKcal = [360, 310, 410, 260, 390, 300, 400]
        input.mood = ["心情平和", "有点愉悦", "特别愉悦", "心情平和", "有点愉悦", "心情平和", "有点愉悦"]
        input.restingHeartRateBpm = [58, 60, 59, 61, 58, 60, 59]
        input.heartRateBpm = [72, 74, 76, 70, 75, 73, 74]
        input.heartRateVariability = [45, 42, 48, 40, 46, 43, 47]
        input.stress = [30, 35, 28, 40, 32, 36, 29]
        input.sleepDurationMinutes = [475, 470, 465, 450, 480, 460, 475]
        input.lightSleepMinutes = [250, 245, 240, 235, 255, 240, 250]
        input.deepSleepMinutes = [110, 105, 115, 100, 110, 105, 115]
        input.sleepQuality = 88
        return input
    }

    static func body(now: Date = Date()) -> AiBodyStatusInput {
        let input = AiBodyStatusInput()
        input.date = date(now)
        input.stepGoal = 8000; input.steps = 8200; input.activityDurationMinutes = 55
        input.caloriesKcal = 360; input.sleepQuality = 88
        input.restingHeartRateBpm = [58, 60, 59, 61, 58, 60]
        input.heartRateBpm = [65, 72, 85, 78, 70, 68]
        input.heartRateVariability = [45, 42, 48, 40, 46, 43]
        input.stress = [30, 35, 28, 40, 32, 36]
        input.sleepDurationMinutes = [475]; input.lightSleepMinutes = [250]; input.deepSleepMinutes = [110]
        return input
    }

    static func exercise() -> HwHealthData {
        let input = HwHealthData()
        input.gender = 1; input.age = 30; input.weight = 700; input.height = 175; input.unit = 0
        input.dailyDataList = (0..<7).map { index in
            let day = HwHealthDailyData()
            day.day = index; day.step = 8200 - index * 200
            day.minHr = 55; day.maxHr = 140; day.avgHr = 72
            day.minSpO2 = 95; day.maxSpO2 = 99; day.avgSpO2 = 97
            day.minStress = 20; day.maxStress = 55; day.avgStress = 32
            day.sleep = 475; day.pai = 35
            return day
        }
        return input
    }
}
