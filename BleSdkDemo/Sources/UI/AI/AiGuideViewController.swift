import UIKit

/// iOS integration guide aligned with Android `ai/ReadMe.md`, using AiSDK APIs.
final class AiGuideViewController: UIViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("ai_guide")
        view.backgroundColor = .systemGroupedBackground

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

    Entry point: `AiSDK.sharedInstance()`. Two flows: watch-triggered AI DEMO and app-triggered AI analysis.

    ## 1. Deliverables / Dependencies

    BleSdkDemo integrates via CocoaPods:

    - `AiSDK` (git: github.com/HWdan/HwAiSDK, branch `main`)
    - `HwBluetoothSDK` (path: Vendor/HwBluetoothSDK, required)
    - `WatchfaceSDK` (git: github.com/HWdan/WatchfaceSDK, branch `main`; pulls Zip + SSZipArchive transitively)
    - `JLBmpConvertKit` (git: github.com/sususu/JLBmpConvertKit, tag `1.2.0`; provided by the host)
    - `AFNetworking`
    - Vendored inside the current AiSDK pod: `NativeLib.xcframework` (AFlash)
    - OAS frameworks: bundled by AiSDK under `Vendor/OAS/*.xcframework`

    Use `pod install` with Podfile.lock. The current delivery needs no separate OAS Pod
    or private OAS specs source. Same AiSDK version numbers may have different Git
    commits; use the lockfile commit/checksum when reproducing an integration.

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
    info.width = 480
    info.height = 480
    info.cornerRadius = 240
    info.thumbnailWidth = 264
    info.thumbnailHeight = 264
    info.thumbnailCornerRadius = 132
    info.currentLocale = "zh"
    info.supportedLocales = ["zh", "en"]
    ai.setDeviceInfo(info)
    ```

    Call `setDeviceInfo` again after reconnect or when resolution / locale changes.

    The current AiDeviceInfo exposes `platformType`. Reuse AiPlatformHelper and
    AiDeviceInfoBuilder for platform resolution and the real product geometry.

    ### Step 4 — startWorking

    ```
    ai.startWorking()
    ```

    Registers BLE AI listeners (recording, watchface, Q&A, translate, Agent, meeting, health, etc.).
    These AI DEMO triggers happen on the watch. App-triggered analysis uses the
    direct report APIs below and does not require starting all watch listeners.

    ### Step 5 — Cleanup

    ```
    ai.stopWorking()
    // Restore the previous AiSDKCallback owner when this page finishes.
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

    Stop listeners only if this page started/owns them. Do not stop another
    module's global AiSDK session when leaving an app-triggered report page.

    ## 4. Common Error Codes (excerpt)

    | Code | Meaning |
    |------|---------|
    | 80002 | Empty recording |
    | 80006 | Health input is empty |
    | 80007 | Health analysis result is empty |
    | 80421 | AI answer failed |
    | 10416 / 10516 | Daily quota exceeded |
    | 1101~1107 | AFlash network / config errors |

    Use `errorMsg(withCode:)` or implement `IAiErrorMessageProvider`.

    ## 5. Checklist

    - [ ] Pods and xcframeworks in place
    - [ ] Microphone permission granted for voice features only
    - [ ] Watch connected
    - [ ] setDeviceInfo; startWorking for watch-triggered flows
    - [ ] AiSDKCallback implemented for UI feedback
    - [ ] stopWorking when leaving the screen

    ## 6. App-triggered AI analysis

    Home → AI contains six report entries. Inputs are mocked by AiAnalysisMock;
    returned reports use real cloud services. A real, AI-authorized device ID is
    required; replacing health data with mock data does not bypass authorization.

    - Exercise & health analysis: HwHealthData →
      DefaultHealthAnalysisResultHandler.analysis(_:), appOnly = true.
      Result: AiSDKCallback.aiHealthAnalysisDone.
    - AI insights: AiExerciseInsightInput → generateExerciseInsight(_:completion:).
    - Body status: AiBodyStatusInput → generateBodyStatus(_:completion:).
    - AI sleep day/week/month: AiSleepChronotypeInput →
      generateSleepChronotype(_:completion:), period = 0/1/2.

    Exercise & health analysis uses the daily health summary handler. It is
    different from the workout-detail getAiExerciseAnalyze API.

    ## 7. OAS configuration

    Configure before setDeviceInfo for insights, body status and sleep reports:

    ```
    AiOASClient.shared.configure(channelId: channelID, appKey: appKey,
                                appUuid: nil, appChannel: nil)
    info.healthAnalysisAppOnly = true
    ai.setDeviceInfo(info)
    ```

    Channel ID / App Key default to the hawofit configuration, are displayed in
    plain text and remain editable. AI_OAS_CHANNEL_ID / AI_OAS_APP_KEY environment
    variables override defaults. Page edits are not persisted. No actual keys
    are printed in this guide.

    ## 8. Input rules and examples

    Import AiSDK+HealthAgents.h and DefaultHealthAnalysisResultHandler.h through
    the app bridging header (already included by this Demo).

    ```
    let input = AiAnalysisMock.insight()
    ai.generateExerciseInsight(input) { result, error in
        // Check error and nil result; display the returned title/content.
    }
    let sleep = AiAnalysisMock.sleep(period: 1)
    ai.generateSleepChronotype(sleep) { result, error in
        // Display bestTime, chronotypeIntro, adjustmentIntro and sleep plan.
    }
    ```

    Insights: 7 aligned daily arrays, newest first; date range is
    yyyy/MM/dd-yyyy/MM/dd with the end date first. SDK mood enum strings are
    Chinese protocol values, not localized UI labels.

    Body status: today's yyyy/MM/dd; hourly arrays are chronological. HR is bpm,
    HRV is ms, calories are kcal, activity/sleep durations are minutes.

    Sleep: 1 item for a day, 7 for a week, month-to-date for a month (not rolling
    30 days). Newest first; sleepHours/getUpHours counts must match. Demo uses
    24-hour HH:mm:ss; missing days use string 0. SDK also supports 12-hour
    hh:mm:ss AM/PM with use12HourClock = true.

    ## 9. Request lifecycle and verification

    Disable duplicate submissions and credential edits while generating. Demo
    uses a 90-second UI timeout and ignores old results after leaving the page.
    Timeout does not guarantee that the cloud request was cancelled. Errors or
    empty results are shown as failures; users can retry.

    The daily health handler is retained and cancelled by the page; the previous
    global AiSDKCallback is restored on completion, timeout or exit. Direct OAS
    completions do not take over that callback.

    Build and mock input checks have passed. Real cloud/device authorization
    still needs on-device verification. See SDK_iOS.md section 23 in this repo
    for full integration details.
    """
}
