import UIKit

/// iOS integration guide aligned with Android `ai/ReadMe.md`, using AiSDK APIs.
final class AiGuideViewController: UIViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("ai_guide")
        view.backgroundColor = .systemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.text = Self.guideMarkdown
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    /// Kept as a single string so Demo ships the guide offline (no extra assets).
    private static let guideMarkdown = """
    # AiSDK Integration Guide (iOS)

    Aligned with Android `ai/ReadMe.md`. Entry point: `AiSDK.sharedInstance()`.

    ## 1. Deliverables / Dependencies

    BleSdkDemo integrates via CocoaPods:

    - `AiSDK` (git: github.com/HWdan/HwAiSDK, branch `main`)
    - `HwBluetoothSDK` (path: Vendor/HwBluetoothSDK, required)
    - `WatchfaceSDK` (git: github.com/HWdan/WatchfaceSDK, branch `main`; pulls Zip + SSZipArchive transitively)
    - `AFNetworking`
    - Vendored inside AiSDK pod: `NativeLib.xcframework` (AFlash), `JLBmpConvertKit.xcframework` (JieLi)

    Info.plist must declare `NSMicrophoneUsageDescription` (voice Q&A / watchface recording).

    ## 2. Integration Steps

    ### Step 1 — Connect the watch first (HwBluetoothSDK)

    AI features assume BLE is connected. In this Demo, scan and bind on Home before opening AI DEMO.

    ### Step 2 — Set callbacks and logging

    ```
    let ai = AiSDK.sharedInstance()
    ai.setLogger(self)                      // ILog
    ai.setAiErrorMessageProvider(self)      // IAiErrorMessageProvider
    ai.callback = self                      // AiSDKCallback
    ```

    ### Step 3 — setDeviceInfo (required)

    Set before using AI watchface / Q&A:

    ```
    let info = AiDeviceInfo()
    info.setValue(deviceId, forKey: "Id")   // use KVC for Id in Swift
    info.mac = mac
    info.name = name
    info.type = productModel                // e.g. KW331
    info.width / height / cornerRadius
    info.thumbnailWidth / Height / CornerRadius
    info.currentLocale = "zh" | "en"
    ai.setDeviceInfo(info)
    ```

    Call `setDeviceInfo` again after reconnect or when resolution / locale changes.

    Git AiSDK 1.3.3 no longer exposes `platformType` on `AiDeviceInfo`; preview/install
    is handled inside AiSDK + WatchfaceSDK. Still set correct panel size and `type`.

    ### Step 4 — startWorking

    ```
    ai.startWorking()
    ```

    Registers BLE AI listeners (recording, watchface, Q&A, translate, Agent, meeting, health, etc.).
    **Triggers happen on the watch**; the phone Demo supplies params, logs, and UI.

    ### Step 5 — Cleanup

    ```
    ai.stopWorking()
    ai.callback = nil
    ```

    ## 3. Main Callbacks (AiSDKCallback)

    | Callback | Description |
    |----------|-------------|
    | aiStart/StopRecording | Watch started / stopped recording |
    | aiVoiceToTextDone | ASR text |
    | aiAnswerDone | AI Q&A result |
    | aiTranslateDone / aiAgentDone | Translate / Agent |
    | aiMeetingDone | Meeting summary |
    | aiHealthAnalysisDone | Health analysis |
    | aiImageDone / aiPreviewDone | Watchface image / preview |
    | aiStartSendingWatchface / Progress / Sent | Watchface push |

    ## 4. Common Error Codes (excerpt)

    | Code | Meaning |
    |------|---------|
    | 80002 | Empty recording |
    | 80023 | Crop / scale failed |
    | 80027 | QJS watchface build failed |
    | 80031 | AI model error |
    | 80041 | No microphone permission |
    | 80051 | DeviceInfo not set |
    | 80421 | AI answer failed |
    | 10416 / 10516 | Daily quota exceeded |
    | 1101~1107 | AFlash network / config errors |

    Use `errorMsg(withCode:)` or implement `IAiErrorMessageProvider`.

    ## 5. Checklist

    - [ ] Pods and xcframeworks in place
    - [ ] Microphone permission granted
    - [ ] Watch connected
    - [ ] setDeviceInfo + startWorking
    - [ ] AiSDKCallback implemented for UI feedback
    - [ ] stopWorking when leaving the screen

    ## 6. Next Step

    Go back and open **AI DEMO** to verify watchface / Q&A flows on a connected watch.
    """
}
