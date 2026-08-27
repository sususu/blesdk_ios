import UIKit

/// Full AiSDK bridge for AI DEMO — aligns with Example `HwMainVC` + Android `AiEvent` surface.
///
/// Watch-driven: phone starts listening and displays callbacks; does not push prompts itself.
final class AiDemoBridge: NSObject, AiSDKCallback, ILog, IAiErrorMessageProvider {
    var onLog: ((String) -> Void)?
    var onStatus: ((String) -> Void)?
    var onResultImage: ((UIImage?) -> Void)?
    var onPreviewImage: ((UIImage?) -> Void)?
    var onProgress: ((Float) -> Void)?
    var onBusy: ((Bool) -> Void)?

    func startWorking() {
        clearAiPreviewZipCache()
        let ai = AiSDK.sharedInstance()
        ai.setLogger(self)
        ai.setAiErrorMessageProvider(self)
        ai.callback = self
        ai.startWorking()
        setAnimeStyle(true)
        emitLog("[AI] startWorking")
    }

    /// AiSDK `generatePreviewZip` reuses `Caches/tempZipFolder` without deleting first;
    /// stale files can make SSZipArchive produce a bad zip → SFDial `Unzip Failed`.
    private func clearAiPreviewZipCache() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let caches else { return }
        let fm = FileManager.default
        for name in ["tempZipFolder", "target.zip", "JW_AIPreview1.bin"] {
            let url = caches.appendingPathComponent(name)
            try? fm.removeItem(at: url)
        }
    }

    func stopWorking() {
        AiSDK.sharedInstance().stopWorking()
        emitBusy(false)
        emitLog("[AI] stopWorking")
    }

    func setDeviceInfo(_ info: AiDeviceInfo, platform: HWPlatformType? = nil) {
        AiSDK.sharedInstance().setDeviceInfo(info)
        let id = (info.value(forKey: "Id") as? String) ?? "-"
        let label = platform.map { platformLabel($0) } ?? "-"
        emitLog("[AI] setDeviceInfo id=\(id) \(info.width)x\(info.height) platform=\(label)")
    }

    private func platformLabel(_ type: HWPlatformType) -> String {
        switch type {
        case .jieLi: return "JieLi(2)"
        case .realtek: return "Realtek(1)"
        default: return "Sifli(0)"
        }
    }

    func setAnimeStyle(_ anime: Bool) {
        // AiStyleAnime = 3, AiStylePencilDrawing = 9
        AiSDK.sharedInstance().aiStyle = AiStyle(rawValue: anime ? 3 : 9) ?? AiStyle(rawValue: 3)!
        emitLog("[AI] style=\(anime ? "anime(3)" : "pencil(9)")")
    }

    func queryOrder(mac: String) {
        guard !mac.isEmpty else {
            emitLog("[AI] getOrderInfo skipped: empty mac")
            return
        }
        emitStatus(L10n.tr("ai_order_querying"))
        AiSDK.sharedInstance().getOrderInfo(withMac: mac) { [weak self] order, errorMsg in
            DispatchQueue.main.async {
                if let errorMsg, !errorMsg.isEmpty {
                    self?.onStatus?(errorMsg)
                    self?.onLog?("[AI] order error: \(errorMsg)")
                    return
                }
                let line = L10n.tr(
                    "ai_order_summary",
                    order.id ?? "-",
                    order.orderStatus,
                    order.orderNum,
                    order.price ?? "-"
                )
                self?.onStatus?(line)
                self?.onLog?("[AI] \(line)")
            }
        }
    }

    // MARK: - ILog

    func d(_ msg: String!) { emitLog("[D] \(msg ?? "")") }
    func i(_ msg: String!) { emitLog("[I] \(msg ?? "")") }
    func w(_ msg: String!) { emitLog("[W] \(msg ?? "")") }
    func e(_ msg: String!) { emitLog("[E] \(msg ?? "")") }

    // MARK: - Main-thread UI emitters

    private func emitLog(_ msg: String) {
        if Thread.isMainThread {
            onLog?(msg)
        } else {
            DispatchQueue.main.async { [weak self] in self?.onLog?(msg) }
        }
    }

    private func emitStatus(_ msg: String) {
        if Thread.isMainThread {
            onStatus?(msg)
        } else {
            DispatchQueue.main.async { [weak self] in self?.onStatus?(msg) }
        }
    }

    private func emitBusy(_ busy: Bool) {
        if Thread.isMainThread {
            onBusy?(busy)
        } else {
            DispatchQueue.main.async { [weak self] in self?.onBusy?(busy) }
        }
    }

    // MARK: - IAiErrorMessageProvider

    func message(forCode code: Int) -> String! {
        Self.localizedError(code) ?? AiSDK.sharedInstance().errorMsg(withCode: code)
    }

    /// Mirrors Example `HwMainVC.messageForCode:` for common AiError* values (raw codes).
    private static func localizedError(_ code: Int) -> String? {
        switch code {
        case 0: return ""
        case 80001: return L10n.tr("ai_err_answer_failed")
        case 80002: return L10n.tr("ai_err_record_empty")
        case 80009: return L10n.tr("ai_err_asr_empty")
        case 80010: return L10n.tr("ai_err_crop")
        case 80011: return L10n.tr("ai_err_bin")
        case 80012: return L10n.tr("ai_err_qjs")
        case 80013: return L10n.tr("ai_err_model")
        case 80014: return L10n.tr("ai_err_no_device_info")
        case 80015: return L10n.tr("ai_err_vtt_empty")
        case 8: return L10n.tr("ai_err_no_quota")
        case 9: return L10n.tr("ai_err_daily_free")
        case 10: return L10n.tr("ai_err_free")
        case 12: return L10n.tr("ai_err_content")
        case 13: return L10n.tr("ai_err_lang")
        case 1102: return L10n.tr("ai_err_aflash_connect")
        case 1101: return L10n.tr("ai_err_aflash_timeout")
        case 1103: return L10n.tr("ai_err_aflash_unknown")
        case 50: return L10n.tr("ai_err_aflash_server")
        case 1105: return L10n.tr("ai_err_aflash_domain")
        case 1106: return L10n.tr("ai_err_aflash_version")
        case 1107: return L10n.tr("ai_err_aflash_config")
        case 61: return L10n.tr("ai_err_aflash_auth")
        default: return nil
        }
    }

    // MARK: - AiSDKCallback

    func aiStartRecording(_ type: Int) {
        DispatchQueue.main.async {
            self.onStatus?(L10n.tr("ai_cb_recording_start", type))
            self.onLog?("[CB] aiStartRecording type=\(type)")
        }
    }

    func aiStopRecording(_ type: Int) {
        DispatchQueue.main.async {
            self.onStatus?(L10n.tr("ai_cb_recording_stop", type))
            self.onLog?("[CB] aiStopRecording type=\(type)")
        }
    }

    func aiVoice(toTextDone text: String?, type: Int) {
        DispatchQueue.main.async {
            let t = text ?? ""
            self.onLog?("[CB] ASR type=\(type): \(t.prefix(120))")
            self.onStatus?(L10n.tr("ai_cb_asr", t.isEmpty ? "-" : String(t.prefix(40))))
        }
    }

    func aiAnswerDone(_ result: String?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            if code != 0 {
                self.onStatus?(errorMsg ?? "answer code=\(code)")
                self.onLog?("[CB] answer fail code=\(code) \(errorMsg ?? "")")
            } else {
                let t = result ?? ""
                self.onStatus?(L10n.tr("ai_cb_answer_ok"))
                self.onLog?("[CB] answer: \(t.prefix(200))")
            }
        }
    }

    func aiTranslateDone(_ result: String?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            if code != 0 {
                self.onLog?("[CB] translate fail \(errorMsg ?? "code=\(code)")")
            } else {
                self.onStatus?(L10n.tr("ai_cb_translate_ok"))
                self.onLog?("[CB] translate: \((result ?? "").prefix(200))")
            }
        }
    }

    func aiAgentDone(_ result: String?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            if code != 0 {
                self.onLog?("[CB] agent fail \(errorMsg ?? "code=\(code)")")
            } else {
                self.onStatus?(L10n.tr("ai_cb_agent_ok"))
                self.onLog?("[CB] agent: \((result ?? "").prefix(200))")
            }
        }
    }

    func aiMeetingDone(_ meeting: HwMeeting?, voiceFilePath: String?, meetingTime: Date?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            if code != 0 {
                self.onLog?("[CB] meeting fail \(errorMsg ?? "code=\(code)")")
            } else {
                self.onStatus?(L10n.tr("ai_cb_meeting_ok"))
                self.onLog?("[CB] meeting voice=\(voiceFilePath ?? "-") time=\(String(describing: meetingTime))")
            }
        }
    }

    func aiHealthAnalysisDone(_ healthAnalysis: HwHealthAnalysisResult?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            if code != 0 {
                self.onLog?("[CB] health fail \(errorMsg ?? "code=\(code)")")
            } else {
                self.onStatus?(L10n.tr("ai_cb_health_ok"))
                self.onLog?("[CB] healthAnalysis done")
            }
        }
    }

    func aiImageDone(_ image: UIImage?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onResultImage?(image)
            if code != 0 {
                self.onStatus?(errorMsg ?? "aiImage code=\(code)")
                self.onLog?(errorMsg ?? "aiImage code=\(code)")
            } else {
                self.onStatus?(L10n.tr("wf_ai_image_ok"))
            }
        }
    }

    func aiPreviewDone(_ image: UIImage?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onPreviewImage?(image)
            if code != 0 {
                self.onLog?(errorMsg ?? "preview code=\(code)")
            } else {
                self.onStatus?(L10n.tr("wf_ai_preview_ok"))
            }
        }
    }

    func aiStartSendingPreview() {
        DispatchQueue.main.async {
            self.onLog?("[CB] aiStartSendingPreview")
        }
    }

    func aiSentPreview(_ code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onLog?("[CB] aiSentPreview code=\(code) \(errorMsg ?? "")")
            if code != 0 {
                self.onStatus?(L10n.tr("ai_preview_push_failed_hint"))
            }
        }
    }

    func aiStartSendingWatchface() {
        DispatchQueue.main.async {
            self.onBusy?(true)
            self.onStatus?(L10n.tr("wf_ai_installing"))
        }
    }

    func aiSendingWatchfaceProgressUpdated(_ progress: Float) {
        DispatchQueue.main.async { self.onProgress?(progress) }
    }

    func aiSentWatchface(_ watchface: SlifiCustomWatchface?, code: Int, errorMsg: String?) {
        DispatchQueue.main.async {
            self.onBusy?(false)
            self.onProgress?(code == 0 ? 1 : 0)
            if code == 0 {
                self.onStatus?(L10n.tr("wf_install_ok"))
                self.onLog?(L10n.tr("wf_install_ok") + " name=\(watchface?.name ?? "-")")
            } else {
                self.onStatus?(L10n.tr("wf_install_fail"))
                self.onLog?(errorMsg ?? "code=\(code)")
            }
        }
    }

    func aiDidEnterTranslate(withInputLangugae inputLanguage: Int, outputLanguage: Int) {
        DispatchQueue.main.async {
            self.onLog?("[CB] enter translate in=\(inputLanguage) out=\(outputLanguage)")
            self.onStatus?(L10n.tr("ai_cb_translate_enter", inputLanguage, outputLanguage))
        }
    }

    func aiDidRequestAiTranslateResult() {
        DispatchQueue.main.async {
            self.onLog?("[CB] request translate result")
        }
    }
}
