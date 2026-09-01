import Foundation
import UIKit
import AiSDK
import WatchfaceSDK

/// Central facade over `HwBluetoothSDK` / `SifliWatchfaceSDK`, mirroring the Android
/// `BleRepository` surface used by the demo app.
///
/// Responsibilities:
/// - One-time SDK initialization and teardown
/// - BLE scan / connect / disconnect, plus auto-reconnect aligned with HaWoFit `BleConnectManager`
/// - Device bind / unbind and post-bind configuration (time, user info, language, etc.)
/// - Health data sync (activity / heart rate / sleep)
/// - Goals, alarms, reminders, social notification switches, contacts
/// - File transfers: music, album photos, AGPS (primarily via Sifli push; JL paths remain available)
///
/// Threading: most SDK callbacks are hoppped onto the main queue before invoking completions
/// or emitting `ConnectionEvent`s so UI callers can update safely.
///
/// Lifecycle notes:
/// - Call `initSDK()` once at app launch (idempotent).
/// - Enable `autoReconnectEnabled` after a successful bind; disable it on manual disconnect / unbind.
/// - Only one music/album/AGPS transfer may run at a time (`isTransferring` / Sifli `isWorking`).
final class BleRepository {
    /// Shared singleton used by all feature screens.
    static let shared = BleRepository()

    /// Persists the last successfully bound device (MAC, name, firmware metadata).
    private let store = BoundDeviceStore.shared

    /// Whether `initSDK()` has already configured the underlying SDKs and callbacks.
    private var initialized = false

    /// Observers notified of connection / reconnect lifecycle events.
    /// Registered via `addConnectionHandler(_:)`; there is no remove API in this demo.
    private(set) var connectionHandlers: [(ConnectionEvent) -> Void] = []

    /// When `true`, the repository will attempt to re-establish BLE after disconnects,
    /// Bluetooth power-on, and app returning to foreground — matching Android bind behavior.
    /// Turned on after bind succeeds; turned off on manual disconnect / unbind.
    private(set) var autoReconnectEnabled = false

    /// Delay before scheduling another reconnect attempt after a failure
    /// (aligned with `BleConnectManager`: 0.5s).
    private let reconnectRetryDelay: TimeInterval = 0.5

    /// Per-attempt connect timeout in seconds used by auto-reconnect
    /// (aligned with `BleConnectManager`: 13s).
    private let reconnectTimeout = 13

    /// Pending delayed reconnect work item; cancelled when connected or auto-reconnect is disabled.
    private var reconnectWorkItem: DispatchWorkItem?

    /// Monotonic counter of reconnect attempts since the last successful connection;
    /// reset to 0 on connect success or when reconnect is cancelled.
    private var reconnectAttempt = 0

    /// `true` while a reconnect `connect` call is in flight (prevents overlapping attempts
    /// from being confused; scheduling still uses `reconnectWorkItem`).
    private var reconnectInFlight = false

    /// `true` while a Sifli (or guarded) music / album / AGPS transfer is active.
    private(set) var isTransferring = false

    /// Which transfer kind currently owns the transfer lock, if any.
    private var activeTransferKind: TransferKind?

    /// High-level categories of exclusive file-transfer / DFU operations.
    /// Exclusive Sifli file-transfer kinds sharing one BLE lock (`beginTransfer`).
    /// `.watchface` covers Sifli online/custom push; `.jieliWatchface` uses JL multi-file transfer.
    enum TransferKind { case music, album, agps, ota, jieliOta, watchface, jieliWatchface }

    private init() {}

    /// Primary HaWoFit Bluetooth SDK entry point.
    var sdk: HwBluetoothSDK { HwBluetoothSDK.sharedInstance() }

    /// Secondary center API used for activity counts, goals, and JL multi-file transfer.
    var center: HwBluetoothCenter { HwBluetoothCenter.sharedInstance() }

    /// Registers a handler that receives `ConnectionEvent`s (connected, disconnected,
    /// reconnecting, reconnectFailed). Handlers are retained for the process lifetime.
    func addConnectionHandler(_ handler: @escaping (ConnectionEvent) -> Void) {
        connectionHandlers.append(handler)
    }

    /// Enables or disables automatic reconnection.
    /// When disabling, any scheduled or in-flight reconnect bookkeeping is cancelled.
    func setAutoReconnectEnabled(_ enabled: Bool) {
        autoReconnectEnabled = enabled
        if !enabled {
            cancelReconnect()
        }
    }

    /// Initializes `HwBluetoothSDK` and `SifliWatchfaceSDK` once, then installs:
    /// - connection-state callback (debounced 0.3s, matching `BleConnectManager`)
    /// - Bluetooth power-state callback (reconnect when BT becomes available)
    /// - `UIApplication.didBecomeActive` observer (reconnect when returning to foreground)
    func initSDK() {
        guard !initialized else { return }
        sdk.initSDK()
        SifliWatchfaceSDK.getInstance().initSDK()
        // HaWoFit AppDelegate also warms SFDialPlateManager before any dial push.
        _ = SFDialPlateManager.share
        SifliOtaPusher.shared.warmUp()
        AiSDK.sharedInstance().setJLBmpDataConverter {
            JieliWatchfaceImageEncoder.convert($0)
        }
        initialized = true

        // Debounce connection-state handling by 0.3s (BleConnectManager parity).
        sdk.addBluetoothConnectionStateChangedCallback { [weak self] state in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.handleConnectionStateChanged(state)
            }
        }

        // When Bluetooth becomes available again and a device is bound, reconnect immediately.
        sdk.addBluetoothStateChangedCallback { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if state == .available,
                   self.autoReconnectEnabled,
                   !self.isConnected() {
                    self.startConnectBluetooth(reasonKey: "reason_bt_on")
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }
    }

    /// Tears down the Bluetooth SDK if it was initialized.
    /// Uses `destroySDK` when available, otherwise falls back to `destroy` (Swift/ObjC naming variance).
    func destroy() {
        if initialized {
            // ObjC destroySDK; some Swift overlays map this as destroy().
            if sdk.responds(to: NSSelectorFromString("destroySDK")) {
                sdk.perform(NSSelectorFromString("destroySDK"))
            } else {
                sdk.perform(NSSelectorFromString("destroy"))
            }
            initialized = false
        }
    }

    /// SDK library version string from `HwBluetoothSDK`.
    func version() -> String { sdk.version() }

    /// Whether the SDK currently reports an active BLE connection.
    func isConnected() -> Bool { sdk.connected() }

    /// Name of the currently connected peripheral, if any.
    func connectedName() -> String? { sdk.connectedDevice()?.name }

    /// MAC address of the currently connected peripheral, if any.
    func connectedMac() -> String? { sdk.connectedDevice()?.macAddress }

    /// CoreBluetooth peripheral UUID string of the connected device (required by Sifli APIs).
    func connectedUUID() -> String? { sdk.connectedDevice()?.peripheral?.identifier.uuidString }

    /// Loads the persisted bound-device record from local storage (may be nil if never bound).
    func loadBoundDevice() -> BoundDeviceRecord? { store.load() }

    /// Persists bind result metadata after a successful bind / device-info fetch.
    /// - Parameters:
    ///   - mac: Device MAC address (primary reconnect key).
    ///   - name: Optional display name.
    ///   - info: Optional rich device info used to fill firmware / battery / protocol fields.
    func saveBoundDevice(mac: String, name: String?, info: BleDeviceInfoModel?) {
        store.save(BoundDeviceRecord(
            macAddress: mac,
            name: name,
            deviceId: info?.id,
            type: info?.type,
            firmwareVersion: info?.firmwareVersion,
            battery: info?.battery,
            protocolVersion: info?.protocolVersion
        ))
    }

    /// Clears the locally persisted bound-device record (typically after unbind).
    func clearBoundDevice() { store.clear() }

    // MARK: - Scan / Connect

    /// Scans for nearby BLE devices for `timeout` seconds.
    ///
    /// Results are deduplicated by MAC (or UUID fallback) and sorted by RSSI descending
    /// on each update. `onFinish` is invoked when the scan window ends.
    /// - Parameters:
    ///   - timeout: Scan duration in seconds (default 10).
    ///   - onUpdate: Called on the main queue whenever the device map changes.
    ///   - onFinish: Called on the main queue when scanning stops.
    func scan(timeout: TimeInterval = 10,
              onUpdate: @escaping ([BleDeviceItem]) -> Void,
              onFinish: @escaping () -> Void) {
        var map: [String: BleDeviceItem] = [:]
        sdk.scan(callback: { devices, _ in
            guard let devices = devices else { return }
            for d in devices {
                let key = (d.macAddress?.isEmpty == false ? d.macAddress! : (d.uuid ?? UUID().uuidString))
                map[key] = BleDeviceItem(
                    name: d.name,
                    macAddress: d.macAddress ?? "",
                    uuid: d.uuid,
                    rssi: d.rssi?.intValue
                )
            }
            DispatchQueue.main.async {
                onUpdate(Array(map.values).sorted { ($0.rssi ?? -999) > ($1.rssi ?? -999) })
            }
        }, stopAfter: timeout, stopCallback: {
            DispatchQueue.main.async { onFinish() }
        })
    }

    /// Stops an in-progress scan started by `scan(...)`.
    func stopScan() { sdk.stopScan() }

    /// Connects using a discovered `HwBluetoothDevice` instance.
    /// On success, emits `.connected` and returns a `BleDeviceItem` snapshot.
    /// - Parameters:
    ///   - device: Device from a prior scan callback.
    ///   - timeout: Connect timeout in seconds (default 30).
    ///   - completion: Main-queue result.
    func connect(device: HwBluetoothDevice, timeout: TimeInterval = 30,
                 completion: @escaping (Result<BleDeviceItem, Error>) -> Void) {
        sdk.connect(with: device, timeout: Int(timeout)) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let item = BleDeviceItem(
                    name: device.name,
                    macAddress: device.macAddress ?? "",
                    uuid: device.uuid,
                    rssi: device.rssi?.intValue
                )
                self?.emit(.connected(name: item.name, mac: item.macAddress))
                completion(.success(item))
            }
        }
    }

    /// Connects by MAC address (used for reconnect / known devices without a scan result).
    /// On success, emits `.connected` with the live peripheral name when available.
    func connect(mac: String, timeout: TimeInterval = 30,
                 completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.connect(withMac: mac, timeout: Int(timeout)) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    let d = self?.sdk.connectedDevice()
                    self?.emit(.connected(name: d?.name, mac: d?.macAddress ?? mac))
                    completion(.success(()))
                }
            }
        }
    }

    /// Disconnects the current peripheral.
    /// Cancels queued reconnect retries; callers that want a permanent disconnect should
    /// also call `setAutoReconnectEnabled(false)` beforehand so auto-reconnect does not restart.
    func disconnect(completion: ((Error?) -> Void)? = nil) {
        // Caller should disable autoReconnect for a manual disconnect; here we only cancel queued retries.
        cancelReconnect()
        sdk.disconnect { error in
            DispatchQueue.main.async {
                self.emit(.disconnected)
                completion?(error)
            }
        }
    }

    // MARK: - Reconnect (aligned with HaWoFit BleConnectManager)

    /// Entry point for automatic reconnection (cold start, foreground, BT power-on, disconnect).
    ///
    /// Preconditions (all required):
    /// - `autoReconnectEnabled == true`
    /// - a bound device exists in `BoundDeviceStore`
    /// - not already connected
    /// - Bluetooth radio is powered on
    /// - app is not in background (background reconnect loop is intentionally disabled)
    ///
    /// Prefer `getLastConnectedDevice()` when available; otherwise fall back to stored MAC.
    /// - Parameter reasonKey: Localization key describing why reconnect started (for UI / logs).
    func startConnectBluetooth(reasonKey: String = "reason_auto") {
        guard autoReconnectEnabled else { return }
        guard store.load() != nil else { return }
        guard !isConnected() else {
            cancelReconnect()
            return
        }
        guard sdk.powerOn() else { return }
        // Do not start reconnect in background (same as BleConnectManager; background loop is commented out).
        if UIApplication.shared.applicationState == .background { return }

        cancelScheduledReconnect()
        reconnectAttempt += 1
        let attempt = reconnectAttempt
        let reason = L10n.tr(reasonKey)
        emit(.reconnecting(attempt: attempt, reason: reason))

        reconnectInFlight = true

        if let last = sdk.getLastConnectedDevice() {
            sdk.connect(with: last, timeout: reconnectTimeout) { [weak self] error in
                DispatchQueue.main.async {
                    self?.handleReconnectCallback(error: error, reasonKey: reasonKey, attempt: attempt)
                }
            }
            return
        }

        guard let mac = store.load()?.macAddress, !mac.isEmpty else {
            reconnectInFlight = false
            return
        }
        sdk.connect(withMac: mac, timeout: reconnectTimeout) { [weak self] error in
            DispatchQueue.main.async {
                self?.handleReconnectCallback(error: error, reasonKey: reasonKey, attempt: attempt)
            }
        }
    }

    /// Handles SDK connection-state transitions after the 0.3s debounce.
    /// - `.connected`: clears reconnect state and emits success.
    /// - `.disconnected`: emits disconnect; if auto-reconnect is allowed (foreground + BT on),
    ///   immediately calls `startConnectBluetooth` (BleConnectManager parity).
    private func handleConnectionStateChanged(_ state: HwBluetoothConnectionState) {
        if state == .connected {
            cancelReconnect()
            reconnectAttempt = 0
            reconnectInFlight = false
            let d = sdk.connectedDevice()
            emit(.connected(name: d?.name, mac: d?.macAddress))
            return
        }
        guard state == .disconnected else { return }
        emit(.disconnected)
        // BleConnectManager.bluetoothConnectionStateChanged:
        // foreground + BT on + bound → startConnectBluetooth immediately.
        guard autoReconnectEnabled else { return }
        guard sdk.powerOn() else { return }
        if UIApplication.shared.applicationState == .background { return }
        startConnectBluetooth(reasonKey: "reason_auto")
    }

    /// Processes the result of a reconnect `connect` call.
    /// On failure, emits `.reconnectFailed` and schedules another attempt after `reconnectRetryDelay`
    /// (unless background / auto-reconnect off / already connected). On success, resets attempt count.
    private func handleReconnectCallback(error: Error?, reasonKey: String, attempt: Int) {
        reconnectInFlight = false
        if let error = error {
            emit(.reconnectFailed(attempt: attempt, message: error.localizedDescription))
            if UIApplication.shared.applicationState == .background { return }
            guard autoReconnectEnabled, !isConnected() else { return }
            scheduleReconnectRetry(reasonKey: reasonKey)
            return
        }
        reconnectAttempt = 0
        let d = sdk.connectedDevice()
        emit(.connected(name: d?.name, mac: d?.macAddress ?? store.load()?.macAddress))
    }

    /// Schedules `startConnectBluetooth` after `reconnectRetryDelay`, replacing any prior work item.
    private func scheduleReconnectRetry(reasonKey: String) {
        cancelScheduledReconnect()
        let work = DispatchWorkItem { [weak self] in
            self?.startConnectBluetooth(reasonKey: reasonKey)
        }
        reconnectWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectRetryDelay, execute: work)
    }

    /// Cancels only the delayed retry work item (does not reset attempt counters).
    private func cancelScheduledReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
    }

    /// Fully stops reconnect: cancels scheduled work and resets in-flight / attempt state.
    private func cancelReconnect() {
        cancelScheduledReconnect()
        reconnectInFlight = false
        reconnectAttempt = 0
    }

    /// Triggered when the app becomes active; starts reconnect if bound and not connected.
    private func applicationDidBecomeActive() {
        guard autoReconnectEnabled else { return }
        guard store.load() != nil else { return }
        guard !isConnected() else { return }
        startConnectBluetooth(reasonKey: "reason_foreground")
    }

    // MARK: - Bind / Unbind
    //
    // Bind flow (see `BindFlowViewController`):
    //   startBind → set time/user/unit/language → getDeviceInfo → endBind →
    //   getPairState → (optional) requestDeviceToPair → Home saves BoundDeviceStore
    //
    // Unbind flow (see `UnbindFlowViewController`):
    //   unbindDevice → disconnect → removeConnectionCache → clearBoundDevice →
    //   **iOS prompt**: user must Forget This Device in Settings → Bluetooth
    //   (Android can call removeBond; iOS cannot clear system pairing from the app).

    /// Begins the device bind handshake (user confirmation on the watch).
    /// Must be followed by config APIs and eventually `endBind`.
    func startBind(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.startBindDevice { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Completes the bind session after `startBind` succeeds and follow-up config is done.
    func endBind(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.endBindDevice { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Notifies the watch firmware to unbind.
    ///
    /// This alone is **not** a full unbind on iOS: also disconnect, clear SDK cache +
    /// local store, disable auto-reconnect, and prompt the user to forget the device
    /// in system Bluetooth settings (no `removeBond` API).
    func unbindDevice(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.unbindDevice { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Syncs phone wall-clock time to the device (24-hour format).
    func setDeviceTime(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setDeviceTime(Date(), is24H: true) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Pushes demo user profile (male, age 28, 175 cm, 70 kg) used by the bind demo flow.
    func setUserInfo(completion: @escaping (Result<Void, Error>) -> Void) {
        let user = HwUserInfo()
        user.gender = .male
        user.age = 28
        user.height = 175
        user.weight = 70
        sdk.setUserInfo(user) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Sets distance / unit system to metric.
    func setUnitMetric(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setUnit(.metric) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Sets device UI language. Default raw value `0x01` matches the demo's English setting.
    func setLanguage(_ language: HwLanguage = HwLanguage(rawValue: 0x01)!,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setLanguage(language) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Fetches device info (id, type, firmware, MAC, battery, protocol, watchface id).
    /// Also calls `updateMacAddressIfNeed` when a MAC is present so later reconnects stay accurate.
    ///
    /// Note: Swift imports ObjC property `Id` as `id`. Do not use KVC key `"id"`
    /// (throws `NSUnknownKeyException`).
    func getDeviceInfo(completion: @escaping (Result<BleDeviceInfoModel, Error>) -> Void) {
        sdk.getDeviceInfo { info, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let info = info else {
                    completion(.failure(SdkError(code: -1, message: "deviceInfo nil")))
                    return
                }
                var model = BleDeviceInfoModel()
                // Swift maps ObjC `Id` to `id`; avoid KVC "id" (NSUnknownKeyException).
                model.id = info.id
                model.type = info.type
                model.firmwareVersion = info.firmwareVersion
                model.mac = info.mac
                model.battery = Int(info.battery)
                model.protocolVersion = Int(info.protocolVersion)
                model.displayingWatchfaceId = info.displayingWatchfaceId
                if let mac = model.mac, !mac.isEmpty {
                    self.sdk.updateMacAddressIfNeed(withMac: mac)
                }
                completion(.success(model))
            }
        }
    }

    /// Queries whether the phone/watch pairing state is established.
    /// Used during bind to decide whether `requestDeviceToPair` can be skipped.
    /// Note: iOS has no public `createBond` / `removeBond` like Android.
    func getPairState(completion: @escaping (Result<Bool, Error>) -> Void) {
        sdk.getPairState { ok, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(ok)) }
            }
        }
    }

    /// Asks the device to enter pairing mode / prompt the user to pair (soft step in bind).
    func requestDeviceToPair(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.requestDeviceToPair { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Clears SDK-side connection cache (part of unbind cleanup before re-pair).
    func removeConnectionCache() { sdk.removeConnectionCache() }

    // MARK: - Health sync
    //
    // `syncHealthData` mirrors Android `sync`:
    //   1) getActivityNum (counts) → 2) pull activities / HR / sleep by count →
    //   3) delete each non-empty category on the device → 4) return a summary string.
    // Home may reconnect before calling this when the watch is bound but offline.

    /// Reads how many activity / sleep / heart-rate / HRF records are buffered on the device.
    func getHealthDataCount(completion: @escaping (Result<HealthDataCount, Error>) -> Void) {
        center.getActivityNum { sportNum, sleepNum, heartrateNum, hrfNum, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                completion(.success(HealthDataCount(
                    activityCount: Int(sportNum),
                    sleepCount: Int(sleepNum),
                    heartrateCount: Int(heartrateNum),
                    hrfCount: Int(hrfNum)
                )))
            }
        }
    }

    /// Pulls up to `count` activity records from the device.
    func getActivities(count: UInt, completion: @escaping (Result<[HwActivity], Error>) -> Void) {
        guard count > 0 else { completion(.success([])); return }
        sdk.getActivities(count) { list, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success((list as? [HwActivity]) ?? [])) }
            }
        }
    }

    /// Pulls heart-rate records (default up to 50). Returned as `[Any]` because the SDK
    /// type varies across firmware / SDK versions in this demo.
    func getHeartrates(count: UInt = 50, completion: @escaping (Result<[Any], Error>) -> Void) {
        sdk.getHeartrates(count) { list, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(list ?? [])) }
            }
        }
    }

    /// Pulls sleep records (default up to 50). Same untyped list caveat as heart rates.
    func getSleeps(count: UInt = 50, completion: @escaping (Result<[Any], Error>) -> Void) {
        sdk.getSleeps(count) { list, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(list ?? [])) }
            }
        }
    }

    /// Deletes all activity records stored on the device after a successful sync pull.
    func deleteActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteActivities { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Deletes all heart-rate records stored on the device after a successful sync pull.
    func deleteHeartrates(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteHeartrates { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Deletes all sleep records stored on the device after a successful sync pull.
    func deleteSleeps(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.deleteSleeps { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Full health sync pipeline aligned with Android `sync`:
    /// 1. Query on-device counts
    /// 2. Fetch activities / heart rates / sleeps by those counts
    /// 3. Delete each non-empty category from the device
    /// 4. Return a localized summary string (counts + step sum)
    ///
    /// Fetch failures for individual categories are treated as empty lists so sync can continue;
    /// only the initial count query failure aborts the whole operation.
    func syncHealthData(completion: @escaping (Result<String, Error>) -> Void) {
        getHealthDataCount { [weak self] countResult in
            guard let self = self else { return }
            switch countResult {
            case .failure(let e): completion(.failure(e))
            case .success(let count):
                self.fetchActivities(count: count.activityCount) { actResult in
                    let actList = (try? actResult.get()) ?? []
                    let actN = actList.count
                    let stepSum = actList.reduce(0) { $0 + Int($1.step) }
                    self.fetchHeartrates(count: count.heartrateCount) { hrResult in
                        let hrN = (try? hrResult.get())?.count ?? 0
                        self.fetchSleeps(count: count.sleepCount) { sleepResult in
                            let sleepN = (try? sleepResult.get())?.count ?? 0
                            let summary = L10n.tr("sync_summary", actN, stepSum, hrN, sleepN)
                            let afterDeletes = {
                                completion(.success(summary))
                            }
                            let delSleeps = {
                                if sleepN > 0 {
                                    self.deleteSleeps { _ in afterDeletes() }
                                } else {
                                    afterDeletes()
                                }
                            }
                            let delHR = {
                                if hrN > 0 {
                                    self.deleteHeartrates { _ in delSleeps() }
                                } else {
                                    delSleeps()
                                }
                            }
                            if actN > 0 {
                                self.deleteActivities { _ in delHR() }
                            } else {
                                delHR()
                            }
                        }
                    }
                }
            }
        }
    }

    /// Helper that no-ops when `count == 0` instead of calling the SDK with a zero request.
    private func fetchActivities(count: Int, completion: @escaping (Result<[HwActivity], Error>) -> Void) {
        guard count > 0 else { completion(.success([])); return }
        getActivities(count: UInt(count), completion: completion)
    }

    private func fetchHeartrates(count: Int, completion: @escaping (Result<[Any], Error>) -> Void) {
        guard count > 0 else { completion(.success([])); return }
        getHeartrates(count: UInt(count), completion: completion)
    }

    private func fetchSleeps(count: Int, completion: @escaping (Result<[Any], Error>) -> Void) {
        guard count > 0 else { completion(.success([])); return }
        getSleeps(count: UInt(count), completion: completion)
    }

    // MARK: - Goals

    /// Reads the current goal configuration from the device.
    func getGoals(completion: @escaping (Result<HwGoal, Error>) -> Void) {
        center.getGoalInfoModel { goal, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else if let goal = goal { completion(.success(goal)) }
                else { completion(.failure(SdkError(code: -1, message: "goal nil"))) }
            }
        }
    }

    /// Sets a single goal value for the given `HwGoalType`.
    func setGoal(type: HwGoalType, value: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setGoalWith(type, goal: value) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Sequentially writes a fixed demo goal set (steps, calories, distance, sleep, duration).
    /// Stops and fails on the first individual `setGoal` error.
    func setDemoGoals(completion: @escaping (Result<Void, Error>) -> Void) {
        let steps: [(HwGoalType, Int)] = [
            (.step, 80), (.caloris, 400), (.distance, 5), (.sleep, 8), (.duration, 30)
        ]
        func run(_ i: Int) {
            if i >= steps.count { completion(.success(())); return }
            let (t, v) = steps[i]
            setGoal(type: t, value: v) { result in
                switch result {
                case .failure(let e): completion(.failure(e))
                case .success: run(i + 1)
                }
            }
        }
        run(0)
    }

    // MARK: - Alarms / reminders

    /// Fetches all alarms currently stored on the device.
    func getAlarms(completion: @escaping (Result<[HwAlarm], Error>) -> Void) {
        sdk.getAlarmsWithCallback { list, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success((list as? [HwAlarm]) ?? [])) }
            }
        }
    }

    /// Adds one demo weekday alarm at 07:30 with localized custom text
    /// (aligned with Android `createDemoAlarm`).
    func addDemoAlarm(completion: @escaping (Result<Void, Error>) -> Void) {
        let alarm = HwAlarm()
        alarm.setValue(true, forKey: "S")
        alarm.custom = L10n.tr("alarms_demo_content")
        alarm.times = [HwTimePoint(hour: 7, minute: 30)]
        // Weekdays Mon–Fri (Android createDemoAlarm parity).
        let weekdays = Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue) | Int(HwWeek.wednesday.rawValue)
            | Int(HwWeek.thursday.rawValue) | Int(HwWeek.friday.rawValue)
        alarm.setValue(weekdays, forKey: "week")
        sdk.add(alarm) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Deletes every alarm. Prefers the batch `deleteAlarms` API when present;
    /// otherwise loads the list and deletes each alarm by ID concurrently via `DispatchGroup`.
    func deleteAllAlarms(completion: @escaping (Result<Void, Error>) -> Void) {
        // Prefer batch API if present.
        let sel = NSSelectorFromString("deleteAlarmsWithCallback:")
        if sdk.responds(to: sel) {
            sdk.deleteAlarms { ok, error in
                DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
            }
            return
        }
        getAlarms { result in
            switch result {
            case .failure(let e): completion(.failure(e))
            case .success(let list):
                if list.isEmpty { completion(.success(())); return }
                let group = DispatchGroup()
                var firstError: Error?
                for a in list {
                    group.enter()
                    let idVal = (a.value(forKey: "Id") as? NSNumber)?.uintValue ?? 0
                    self.sdk.deleteAlarm(byID: idVal) { ok, error in
                        if let error = error, firstError == nil { firstError = error }
                        if !ok, firstError == nil { firstError = SdkError(code: -1, message: "del fail") }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    if let firstError = firstError { completion(.failure(firstError)) }
                    else { completion(.success(())) }
                }
            }
        }
    }

    /// Reads the sedentary-reminder configuration from the device.
    func getSedentary(completion: @escaping (Result<HwSedentaryReminder, Error>) -> Void) {
        sdk.getSedentaryReminder { reminder, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else if let reminder = reminder { completion(.success(reminder)) }
                else { completion(.failure(SdkError(code: -1, message: "nil"))) }
            }
        }
    }

    /// Writes a demo sedentary reminder: weekdays 09:00–18:00, interval 1 hour.
    func setDemoSedentary(completion: @escaping (Result<Void, Error>) -> Void) {
        let r = HwSedentaryReminder()
        r.on = true
        r.startTime = HwTimePoint(hour: 9, minute: 0)
        r.endTime = HwTimePoint(hour: 18, minute: 0)
        r.interval = 3600
        r.setValue(Self.weekdaysMask, forKey: "week")
        sdk.setSedentaryReminder(r) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Writes a demo drink-water reminder: every day 08:00–20:00, interval 1 hour, duration 5.
    func setDemoDrinkWater(completion: @escaping (Result<Void, Error>) -> Void) {
        let c = HwDrinkWaterConfig()
        c.eventOn = true
        c.startHour = 8
        c.startMinute = 0
        c.endHour = 20
        c.endMinute = 0
        c.timeInterval = 3600
        c.duration = 5
        c.setValue(Self.everyDayMask, forKey: "week")
        sdk.setDrinkWaterConfig(c) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Writes a demo hand-washing reminder: every day 08:00–22:00, interval 2 hours, duration 5.
    func setDemoWashHand(completion: @escaping (Result<Void, Error>) -> Void) {
        let c = HwHandwashingConfig()
        c.eventOn = true
        c.startHour = 8
        c.startMinute = 0
        c.endHour = 22
        c.endMinute = 0
        c.timeInterval = 7200
        c.duration = 5
        c.setValue(Self.everyDayMask, forKey: "week")
        sdk.setHandwashingConfig(c) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Bitmask for Monday–Friday (`HwWeek` flags ORed together).
    private static var weekdaysMask: Int {
        Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue) | Int(HwWeek.wednesday.rawValue)
            | Int(HwWeek.thursday.rawValue) | Int(HwWeek.friday.rawValue)
    }

    /// Bitmask for all seven days of the week.
    private static var everyDayMask: Int {
        weekdaysMask | Int(HwWeek.saturday.rawValue) | Int(HwWeek.sunday.rawValue)
    }

    // MARK: - Notify / contacts

    /// Notification switch list (aligned with Android `getSocialAppSwitches`).
    /// Do not confuse with `getSocialApps`, which returns social-app icon packages.
    func getSocialSwitches(completion: @escaping (Result<[HwSocialSwitch], Error>) -> Void) {
        sdk.getSocialSwitches { list, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success((list as? [HwSocialSwitch]) ?? [])) }
            }
        }
    }

    /// Demo helper: enables WeChat / SMS / incoming-call notification switches sequentially
    /// (Android Wechat + SMS + IncomingCall parity).
    func enableDemoSocialSwitches(completion: @escaping (Result<Void, Error>) -> Void) {
        let types: [HwSocialSwitchType] = [.wechat, .message, .calls]
        func run(_ i: Int) {
            if i >= types.count {
                DispatchQueue.main.async { completion(.success(())) }
                return
            }
            sdk.setSocialSwitchWith(types[i], s: true) { ok, error in
                if let error = error {
                    DispatchQueue.main.async { completion(.failure(error)) }
                } else if !ok {
                    DispatchQueue.main.async {
                        completion(.failure(SdkError(code: -1, message: "setSocialSwitch failed type=\(types[i].rawValue)")))
                    }
                } else {
                    run(i + 1)
                }
            }
        }
        run(0)
    }

    /// Writes two hardcoded demo contacts onto the device.
    func setDemoContacts(completion: @escaping (Result<Void, Error>) -> Void) {
        let c1 = HwContact()
        c1.contactName = "Demo A"
        c1.contactPhone = "10086"
        let c2 = HwContact()
        c2.contactName = "Demo B"
        c2.contactPhone = "10010"
        sdk.setContacts([c1, c2]) { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    /// Sets the SOS / emergency contact name and phone number used by the watch.
    func setEmergencyContact(completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setSosName("Emergency", phoneNumber: "120") { ok, error in
            DispatchQueue.main.async { Self.boolResult(ok, error, completion) }
        }
    }

    // MARK: - Music / Album / AGPS
    //
    // Exclusive Sifli file transfers share one lock (`beginTransfer` / `endTransfer` /
    // `cancelTransfer`). Concurrent music, album, AGPS, OTA, or watchface pushes are
    // rejected with `err_transfer_busy`. iOS demo paths always use SifliWatchfaceSDK;
    // JL (classic BT) helpers remain for parity / debugging only.
    // Note: AI dial install is driven by AiSDK and does not call beginTransfer(.watchface);
    // the Watchface host still locks UI navigation while AiSDK reports send progress.
    //
    // Music zip layout:  …/selectTemp/music/mp3/*.mp3  →  zip entries music/mp3/*
    // Album:             resize/crop → allocate slots 1...50 → setPictures
    // AGPS:              AgpsXywBuilder zip (music/gps/agps/*) → syncZipFile type 3

    /// Queries available and total music storage on the device (values in KB).
    func getMusicStorage(completion: @escaping (Result<MusicStorage, Error>) -> Void) {
        sdk.getMusicAvailableStorage { available, total, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(MusicStorage(availableKb: Int(available), totalKb: Int(total)))) }
            }
        }
    }

    /// Returns the list of album slot / file IDs currently occupied on the device.
    func getAlbumFileIds(completion: @escaping (Result<[Int], Error>) -> Void) {
        sdk.getAlbumFilesIdList { ids, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                let ints: [Int] = (ids ?? []).compactMap { item -> Int? in
                    if let n = item as? NSNumber { return n.intValue }
                    if let i = item as? Int { return i }
                    return Int("\(item)")
                }
                completion(.success(ints))
            }
        }
    }

    /// Allocates `count` free album slot indices in the range 1...50
    /// (aligned with Android `allocateAlbumIndices`). Fails if not enough free slots remain.
    func allocateAlbumIndices(count: Int, completion: @escaping (Result<[Int], Error>) -> Void) {
        getAlbumFileIds { result in
            switch result {
            case .failure(let e): completion(.failure(e))
            case .success(let used):
                let usedSet = Set(used)
                var free: [Int] = []
                for i in 1...50 where !usedSet.contains(i) {
                    free.append(i)
                    if free.count >= count { break }
                }
                if free.count < count {
                    completion(.failure(SdkError(code: -1, message: L10n.tr("album_no_slots", count, free.count))))
                } else {
                    completion(.success(free))
                }
            }
        }
    }

    /// Queries whether classic Bluetooth (BT) is connected — relevant for JL transfer paths.
    func getBtConnectionState(completion: @escaping (Result<Bool, Error>) -> Void) {
        sdk.getBtConnectionState { ok, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(ok)) }
            }
        }
    }

    /// Reads GPS / AGPS status from the device, normalizing epoch times to milliseconds
    /// (SDK returns seconds; HaWoFit UI multiplies by 1000 when displaying).
    func getDeviceGpsStatus(completion: @escaping (Result<BleGpsStatusModel, Error>) -> Void) {
        sdk.getDeviceGpsStatus { status, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let status = status else {
                    completion(.failure(SdkError(code: -1, message: "gps status nil")))
                    return
                }
                var m = BleGpsStatusModel()
                // SDK returns second-level timestamps (HaWoFit displays after *1000).
                m.agpsValidStartTimeMs = Self.normalizeEpochMs(Int64(status.agpsValidStartTime))
                m.agpsValidEndTimeMs = Self.normalizeEpochMs(Int64(status.agpsValidEndTime))
                m.gpsClipType = status.gpsClipType
                m.gpsFirmwareVersion = status.gpsFirmwareVersion
                m.gpsFirmwareBuild = Int(status.gpsFirmwareBuild)
                completion(.success(m))
            }
        }
    }

    /// Aborts any active Sifli transfer / OTA and clears the local transfer lock.
    func cancelTransfer() {
        // Stop only the active channel — calling both can disturb the other BLE core.
        switch activeTransferKind {
        case .ota:
            SifliOtaPusher.shared.stop()
        case .jieliOta:
            sdk.otaV2Service?.stop()
        case .jieliWatchface:
            sdk.multipleFileTransferService?.stop()
        case .music, .album, .agps, .watchface:
            SifliWatchfaceSDK.getInstance().stop()
        case .none:
            SifliWatchfaceSDK.getInstance().stop()
            if SifliOtaPusher.shared.isWorking {
                SifliOtaPusher.shared.stop()
            }
        }
        isTransferring = false
        activeTransferKind = nil
    }

    /// Acquires the exclusive transfer lock for `kind`.
    /// Returns an error if another transfer (or Sifli `isWorking` / OTA) is already active.
    private func beginTransfer(_ kind: TransferKind) -> Error? {
        if isTransferring
            || SifliWatchfaceSDK.getInstance().isWorking
            || SifliOtaPusher.shared.isWorking
            || sdk.otaV2Service?.isRunning == true
            || sdk.multipleFileTransferService?.isRunning == true {
            return SdkError(code: -1, message: L10n.tr("err_transfer_busy"))
        }
        isTransferring = true
        activeTransferKind = kind
        return nil
    }

    /// Releases the exclusive transfer lock.
    private func endTransfer() {
        isTransferring = false
        activeTransferKind = nil
    }

    /// Preferred music push entry for iOS: always uses Sifli and does **not** require classic BT.
    ///
    /// Steps:
    /// 1. Acquire the exclusive transfer lock (`.music`).
    /// 2. Stage MP3s under a temp `…/selectTemp/music/mp3/` tree (`pushMusicSifliInternal`).
    /// 3. Call `SifliWatchfaceSDK.setMusicFiles` (compress → BLE push).
    /// 4. On finish: `stop()`, delete temp root, release lock.
    ///
    /// - Parameters:
    ///   - fileURLs: Source MP3 file URLs selected by the user.
    ///   - onReady: Invoked when packaging/compression succeeds and transfer is about to start.
    ///   - onProgress: Transfer progress in `0...1` (SDK reports 0...100).
    ///   - completion: Final success / failure after cleanup.
    func pushMusicAuto(fileURLs: [URL],
                       onReady: @escaping () -> Void,
                       onProgress: @escaping (Float) -> Void,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        if let err = beginTransfer(.music) { completion(.failure(err)); return }
        pushMusicSifliInternal(fileURLs: fileURLs, onReady: onReady, onProgress: onProgress, completion: completion)
    }

    /// Stages selected MP3s into `…/selectTemp/music/mp3/` then calls `pushMusicSifli`.
    ///
    /// Path layout matches HaWoFit `HwMusicService.getMusicSelectTempPath`:
    /// `SifliWatchfaceSDK.packageQjsMp3` strips the last path component and zips the `music`
    /// directory. The zip **must** contain `music/mp3/*.mp3`; a flat folder causes the watch
    /// to return error code **22** when starting a single-file session.
    private func pushMusicSifliInternal(fileURLs: [URL],
                                        onReady: @escaping () -> Void,
                                        onProgress: @escaping (Float) -> Void,
                                        completion: @escaping (Result<Void, Error>) -> Void) {
        // Unique root per push so concurrent / retry runs do not share directories.
        let fm = FileManager.default
        let root = fm.temporaryDirectory
            .appendingPathComponent("qjs_musics_\(UUID().uuidString)", isDirectory: true)
        // Must end with …/music/mp3 — packageQjsMp3 deletes "mp3" then zips "music".
        let mp3Dir = root.appendingPathComponent("selectTemp/music/mp3", isDirectory: true)
        do {
            try fm.createDirectory(at: mp3Dir, withIntermediateDirectories: true)
        } catch {
            endTransfer()
            completion(.failure(error))
            return
        }

        var copied = 0
        for url in fileURLs {
            // Sanitize names like HwMusicViewController (spaces / special chars removed).
            let name = Self.sanitizeMusicFileName(url.lastPathComponent)
            let dest = mp3Dir.appendingPathComponent(name)
            do {
                if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
                try fm.copyItem(at: url, to: dest)
                copied += 1
            } catch {
                continue
            }
        }
        guard copied > 0 else {
            endTransfer()
            completion(.failure(SdkError(code: -1, message: L10n.tr("err_no_music"))))
            return
        }

        // onCompress(true) ≈ packaging done; map SDK Int progress (0...100) to Float 0...1.
        pushMusicSifli(directoryURL: mp3Dir, onCompress: { ok in
            if ok { onReady() }
        }, onProgress: { p in
            onProgress(Float(p) / 100.0)
        }, completion: { [weak self] result in
            try? fm.removeItem(at: root)
            self?.endTransfer()
            completion(result)
        })
    }

    /// Sanitizes music file names for the watch: strips spaces and special characters
    /// (aligned with `HwMusicViewController`) so the firmware can resolve the file.
    private static func sanitizeMusicFileName(_ raw: String) -> String {
        let noSpace = raw.replacingOccurrences(of: " ", with: "")
        let banned = CharacterSet(charactersIn: "@／：；（）¥「」＂、[]{}#%-*+=_\\|~＜＞$€^•'@#$%^&*()_+'\"")
        let cleaned = noSpace.components(separatedBy: banned).joined()
        let base = cleaned.isEmpty ? "music.mp3" : cleaned
        if base.lowercased().hasSuffix(".mp3") { return base }
        return base + ".mp3"
    }

    /// JL (JieLi) multi-file music transfer over classic BT via `HwBluetoothCenter`.
    /// Kept for parity / debugging; iOS demo default path is `pushMusicAuto` (Sifli).
    func pushMusicJL(fileURLs: [URL],
                     onReady: @escaping () -> Void,
                     onProgress: @escaping (Float) -> Void,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        var models: [HwMultipleFileTransferModel] = []
        for url in fileURLs {
            guard let data = try? Data(contentsOf: url) else { continue }
            let m = HwMultipleFileTransferModel()
            m.fileName = url.lastPathComponent
            m.fileData = data
            m.musicType = MultipleFileTransferMusicType(rawValue: 0)!
            models.append(m)
        }
        guard !models.isEmpty else {
            completion(.failure(SdkError(code: -1, message: L10n.tr("err_no_music"))))
            return
        }
        
        HwBluetoothSDK.sharedInstance().multipleFileTransferService.start(
            withFileModels: models,
            transferType: MultipleFileTransferType(rawValue: 0x01)!,
            readyCallback: { ok, error in
                DispatchQueue.main.async {
                    if let error = error { completion(.failure(error)); return }
                    if ok { onReady() }
                }
            },
            progressCallback: { p, _ in
                DispatchQueue.main.async { onProgress(p) } }
            ,
            finishCallback: { ok, error in
                DispatchQueue.main.async {
                    if let error = error { completion(.failure(error)) }
                    else if ok { completion(.success(())) }
                    else { completion(.failure(SdkError(code: -1, message: "music transfer failed"))) }
                }
            }
        )
    }

    /// Low-level Sifli music push: `directoryURL` must point at the `mp3` folder whose parent
    /// tree packs to `music/mp3/*.mp3`. Requires a connected CoreBluetooth UUID.
    func pushMusicSifli(directoryURL: URL,
                        onCompress: @escaping (Bool) -> Void,
                        onProgress: @escaping (Int) -> Void,
                        completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uuid = connectedUUID() else {
            completion(.failure(SdkError(code: -1, message: "no connected uuid")))
            return
        }
        SifliWatchfaceSDK.getInstance().setMusicFiles(
            devIdentifier: uuid,
            musicFilePath: directoryURL,
            compressCallback: { ok in DispatchQueue.main.async { onCompress(ok) } },
            progressCallback: { p in DispatchQueue.main.async { onProgress(p) } },
            finishCallback: { ok, errInfo, errType, _ in
                DispatchQueue.main.async {
                    SifliWatchfaceSDK.getInstance().stop()
                    if ok { completion(.success(())) }
                    else { completion(.failure(SdkError(code: errType, message: errInfo ?? "sifli music fail"))) }
                }
            }
        )
    }

    /// Default album push resolution (demo / common Sifli watches). Production apps should
    /// use the product's actual display width/height.
    static let defaultAlbumSize = CGSize(width: 466, height: 466)

    /// Preferred album push entry: acquires transfer lock, resizes/crops images, allocates
    /// free album slots (`1...50`), then pushes via Sifli `setPictures`.
    ///
    /// Steps:
    /// 1. Aspect-fill + center-crop every image to `size` (default 466×466).
    /// 2. Query occupied IDs and pick free slot indices for the batch.
    /// 3. Set `SifliWatchfaceSDK.width/height` and push `QjsAlbumModel`s named by slot index.
    ///
    /// - Parameters:
    ///   - images: Source photos from the picker (any size / orientation).
    ///   - size: Target watch album resolution (UI-editable on the album demo screen).
    ///   - onReady: Called after compression succeeds / transfer is ready.
    ///   - onProgress: Progress in `0...1`.
    ///   - completion: Final result after releasing the transfer lock.
    func pushAlbumAuto(images: [UIImage],
                       size: CGSize = BleRepository.defaultAlbumSize,
                       onReady: @escaping () -> Void,
                       onProgress: @escaping (Float) -> Void,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        if let err = beginTransfer(.album) { completion(.failure(err)); return }
        // Crop before slot allocation so we fail fast on empty / invalid batches only via indices.
        let prepared = images.map { Self.resizeAndCropAlbumImage($0, to: size) }
        allocateAlbumIndices(count: prepared.count) { [weak self] idxResult in
            guard let self = self else { return }
            switch idxResult {
            case .failure(let e):
                self.endTransfer()
                completion(.failure(e))
            case .success(let indices):
                self.pushAlbumSifli(
                    images: prepared,
                    indices: indices,
                    width: Double(size.width),
                    height: Double(size.height),
                    onCompress: { _ in onReady() },
                    onProgress: { p in onProgress(Float(p) / 100.0) },
                    completion: { r in
                        self.endTransfer()
                        completion(r)
                    }
                )
            }
        }
    }

    /// Aspect-fill then center-crop to `size`, matching `HwAlbumService resizeAndCropImage:toSize:`.
    /// Uses scale factor 1 (device-independent pixel size for the watch).
    static func resizeAndCropAlbumImage(_ image: UIImage, to size: CGSize) -> UIImage {
        guard size.width > 0, size.height > 0, image.size.width > 0, image.size.height > 0 else { return image }
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: scaled))
        }
    }

    /// Low-level Sifli album push. Builds `QjsAlbumModel`s named by slot index.
    /// Re-crops if an image is not already exactly `width`×`height` because the SDK
    /// internally uses fit (letterbox) and may not fill the display otherwise.
    func pushAlbumSifli(images: [UIImage],
                        indices: [Int]? = nil,
                        width: Double = 466,
                        height: Double = 466,
                        onCompress: @escaping (Bool) -> Void,
                        onProgress: @escaping (Int) -> Void,
                        completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uuid = connectedUUID() else {
            completion(.failure(SdkError(code: -1, message: "no connected uuid")))
            return
        }
        let target = CGSize(width: width, height: height)
        let face = SifliWatchfaceSDK.getInstance()
        face.width = width
        face.height = height
        var albums: [QjsAlbumModel] = []
        for (i, img) in images.enumerated() {
            let m = QjsAlbumModel()
            let idx = indices?[safe: i] ?? (i + 1)
            m.name = "\(idx)"
            // Belt-and-suspenders: ensure SDK input is exact target size (SDK fit does not guarantee fill).
            let alreadyExact = abs(img.size.width - target.width) < 0.5 && abs(img.size.height - target.height) < 0.5
            m.image = alreadyExact ? img : Self.resizeAndCropAlbumImage(img, to: target)
            albums.append(m)
        }
        face.setPictures(
            devIdentifier: uuid,
            compressSuccessCallback: { ok in DispatchQueue.main.async { onCompress(ok) } },
            albums: albums,
            progressCallback: { p in DispatchQueue.main.async { onProgress(p) } },
            finishCallback: { ok, errInfo, errType, _ in
                DispatchQueue.main.async {
                    face.stop()
                    if ok { completion(.success(())) }
                    else { completion(.failure(SdkError(code: errType, message: errInfo ?? "album fail"))) }
                }
            }
        )
    }

    /// JL multi-file album transfer (JPEG payload, transfer type `0x02`). Alternate path;
    /// demo default is `pushAlbumAuto` (Sifli).
    func pushAlbumJL(images: [UIImage],
                     indices: [Int]? = nil,
                     size: CGSize = BleRepository.defaultAlbumSize,
                     onReady: @escaping () -> Void,
                     onProgress: @escaping (Float) -> Void,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        var models: [HwMultipleFileTransferModel] = []
        for (i, image) in images.enumerated() {
            let resized = Self.resizeAndCropAlbumImage(image, to: size)
            guard let data = resized.jpegData(compressionQuality: 0.9) else { continue }
            let m = HwMultipleFileTransferModel()
            let idx = indices?[safe: i] ?? (i + 1)
            m.fileName = "PNG_\(idx).bin"
            m.fileData = data
            m.photoType = MultipleFileTransferPhotoType(rawValue: 1)!
            models.append(m)
        }
        guard !models.isEmpty else {
            completion(.failure(SdkError(code: -1, message: L10n.tr("err_no_images"))))
            return
        }
        HwBluetoothSDK.sharedInstance().multipleFileTransferService.start(
            withFileModels: models,
            transferType: MultipleFileTransferType(rawValue: 0x02)!,
            readyCallback: { ok, error in
                DispatchQueue.main.async {
                    if let error = error { completion(.failure(error)); return }
                    if ok { onReady() }
                }
            },
            progressCallback: { p, _ in DispatchQueue.main.async { onProgress(p) } },
            finishCallback: { ok, error in
                DispatchQueue.main.async {
                    if let error = error { completion(.failure(error)) }
                    else if ok { completion(.success(())) }
                    else { completion(.failure(SdkError(code: -1, message: "album transfer failed"))) }
                }
            }
        )
    }

    /// Pushes an AGPS assistance zip via Sifli (`syncZipFile`, `type: 3`, `byteAlign: true`).
    ///
    /// The zip must already contain entries under `music/gps/agps/` (see `AgpsXywBuilder`).
    /// Acquires the exclusive transfer lock for the duration of the operation.
    ///
    /// - Parameters:
    ///   - zipURL: Local path to the AGPS package produced by `AgpsXywBuilder`.
    ///   - onProgress: Integer progress from the Sifli SDK (typically `0...100`).
    ///   - completion: Success / failure after `stop()` and lock release.
    func pushAgpsZip(zipURL: URL,
                     onProgress: @escaping (Int) -> Void,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        if let err = beginTransfer(.agps) { completion(.failure(err)); return }
        guard let uuid = connectedUUID() else {
            endTransfer()
            completion(.failure(SdkError(code: -1, message: "no connected uuid")))
            return
        }
        // type 3 = AGPS / offline-map style zip push in SifliWatchfaceSDK; byteAlign matches APP.
        SifliWatchfaceSDK.getInstance().syncZipFile(
            devIdentifier: uuid,
            filePath: zipURL,
            type: 3,
            byteAlign: true,
            progressCallback: { p in DispatchQueue.main.async { onProgress(p) } },
            finishCallback: { [weak self] ok, errInfo, errType, _ in
                DispatchQueue.main.async {
                    SifliWatchfaceSDK.getInstance().stop()
                    self?.endTransfer()
                    if ok { completion(.success(())) }
                    else { completion(.failure(SdkError(code: errType, message: errInfo ?? "agps fail"))) }
                }
            }
        )
    }

    // MARK: - Sifli OTA (firmware DFU)
    //
    // Demo flow mirrors Android `OtaUpgradeFragment` / ViewModel:
    //   refresh device info → check server → download/unzip → SFOTAManager.startOTANand
    // Push implementation mirrors HaWoFit `OtaHandler.startSifliOta` (Sifli only).

    /// Reads battery percentage (0...100) from the watch.
    func getBattery(completion: @escaping (Result<Int, Error>) -> Void) {
        sdk.getBatteryWithCallback { value, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(Int(value))) }
            }
        }
    }

    /// Explicit firmware version string query (some devices omit it in `getDeviceInfo`).
    func getFirmwareVersion(completion: @escaping (Result<String, Error>) -> Void) {
        sdk.getFirmwareVersion { value, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(value ?? "")) }
            }
        }
    }

    /// Device upgrade state (`none` required before starting a new OTA).
    func getDeviceUpgradeStatus(completion: @escaping (Result<HwDeviceUpgradeState, Error>) -> Void) {
        sdk.getDeviceUpgradeStatus { state, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(state)) }
            }
        }
    }

    /// Full Sifli OTA: prepare package from [info], then NAND DFU.
    ///
    /// Progress mapping (aligned with Android demo UI):
    /// - `0...40` prepare (download / unzip)
    /// - `40...100` DFU push
    ///
    /// After prepare, waits ~1.5s before `startOTANand` (Android / HaWoFit timing) so the
    /// OTA BLE core is ready. `resourcePath` is omitted for full packages.
    func startSifliOta(info: OtaUpgradeInfo,
                       onProgress: @escaping (Int, String) -> Void,
                       onLog: ((String) -> Void)? = nil,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        if let err = beginTransfer(.ota) { completion(.failure(err)); return }
        guard connectedUUID() != nil else {
            endTransfer()
            completion(.failure(SdkError(code: -1, message: "no connected uuid")))
            return
        }
        // Disable auto-reconnect for the DFU window (HaWoFit also keeps reconnect quiet during OTA).
        setAutoReconnectEnabled(false)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let package = try SifliOtaPusher.shared.preparePackage(info: info) { pct in
                    DispatchQueue.main.async {
                        onProgress(Int(Double(pct) * 0.4), L10n.tr("ota_phase_download"))
                    }
                }
                DispatchQueue.main.async {
                    onLog?(package.debugSummary)
                    onProgress(40, L10n.tr("ota_phase_push"))
                    // Re-read UUID after prepare (still need a live connection identity).
                    guard let uuid = self.connectedUUID() else {
                        self.endTransfer()
                        completion(.failure(SdkError(code: -1, message: "no connected uuid")))
                        return
                    }
                    onLog?("DFU target uuid=\(uuid)")
                    // Quiet SFDial BLE core before Sifli OTA starts its own CBCentralManager.
                    SifliWatchfaceSDK.getInstance().stop()
                    // Android OtaUpgradeFragment delays 1.5s before startActionDFUNand.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        guard self.activeTransferKind == .ota else { return }
                        SifliOtaPusher.shared.startDFU(
                            devIdentifier: uuid,
                            package: package,
                            onProgress: { p in
                                onProgress(40 + Int(Double(p) * 0.6), L10n.tr("ota_phase_push"))
                            },
                            onLog: onLog,
                            completion: { [weak self] result in
                                self?.endTransfer()
                                completion(result)
                            }
                        )
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.endTransfer()
                    completion(.failure(error))
                }
            }
        }
    }

    /// Downloads all Jieli firmware fragments in server order, then appends their raw bytes.
    /// This deliberately does not unzip or reinterpret supplier-provided aggregate-bin data.
    private func prepareJieliOtaData(
        info: OtaUpgradeInfo,
        onProgress: @escaping (Int) -> Void
    ) throws -> Data {
        guard !info.firmwares.isEmpty else {
            throw SdkError(code: -1, message: L10n.tr("ota_err_no_package"))
        }

        var aggregate = Data()
        for (index, item) in info.firmwares.enumerated() {
            let fallbackName = "jieli_ota_\(index).bin"
            let remoteName = URL(string: item.url)?.lastPathComponent
            let fileName: String
            if let name = item.name, !name.isEmpty {
                fileName = name
            } else if let remoteName = remoteName, !remoteName.isEmpty {
                fileName = remoteName
            } else {
                fileName = fallbackName
            }
            let fileURL = try OtaFirmwareApi.downloadToCache(
                url: item.url,
                fileName: fileName,
                expectMd5: item.md5,
                subDir: "BleSdkDemo/JieliOTA"
            ) { fileProgress in
                let total = ((index * 100) + fileProgress) / info.firmwares.count
                onProgress(total)
            }
            let bytes = try Data(contentsOf: fileURL)
            guard !bytes.isEmpty else {
                throw SdkError(code: -1, message: L10n.tr("jieli_ota_err_empty_bin"))
            }
            aggregate.append(bytes)
        }

        guard !aggregate.isEmpty else {
            throw SdkError(code: -1, message: L10n.tr("jieli_ota_err_empty_bin"))
        }
        return aggregate
    }

    /// Downloads the ordered Jieli aggregate bin and upgrades it through `HwOtaV2Service`.
    /// Download progress occupies 0...40%; the OTA V2 push occupies 40...100%.
    func startJieliOta(
        info: OtaUpgradeInfo,
        onProgress: @escaping (Int, String) -> Void,
        onLog: ((String) -> Void)? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let otaService = sdk.otaV2Service else {
            completion(.failure(SdkError(code: -1, message: L10n.tr("ota_failed"))))
            return
        }
        if let err = beginTransfer(.jieliOta) {
            completion(.failure(err))
            return
        }
        setAutoReconnectEnabled(false)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try self.prepareJieliOtaData(info: info) { pct in
                    DispatchQueue.main.async {
                        onProgress(Int(Double(pct) * 0.4), L10n.tr("jieli_ota_phase_download"))
                    }
                }
                DispatchQueue.main.async {
                    guard self.activeTransferKind == .jieliOta else { return }
                    onLog?(L10n.tr("jieli_ota_log_bytes", data.count))
                    otaService.start(
                        withBinData: data,
                        readyCallback: { ok, error in
                            DispatchQueue.main.async {
                                guard self.activeTransferKind == .jieliOta else { return }
                                if ok {
                                    onProgress(40, L10n.tr("jieli_ota_phase_push"))
                                } else if let error = error {
                                    onLog?(error.localizedDescription)
                                } else {
                                    onLog?(L10n.tr("ota_failed"))
                                }
                            }
                        },
                        progressCallback: { progress, _ in
                            DispatchQueue.main.async {
                                guard self.activeTransferKind == .jieliOta else { return }
                                let normalized = max(0, min(1, progress))
                                onProgress(
                                    40 + Int(normalized * 60),
                                    L10n.tr("jieli_ota_phase_push")
                                )
                            }
                        },
                        finishCallback: { ok, error in
                            DispatchQueue.main.async {
                                guard self.activeTransferKind == .jieliOta else { return }
                                self.endTransfer()
                                if ok {
                                    completion(.success(()))
                                } else {
                                    completion(.failure(error ?? SdkError(
                                        code: -1,
                                        message: L10n.tr("ota_failed")
                                    )))
                                }
                            }
                        }
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    guard self.activeTransferKind == .jieliOta else { return }
                    self.endTransfer()
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Watchface (Sifli online / custom)
    //
    // Three demo surfaces share this section:
    //   • Online  — catalog ZIP → setOnlineWatchface (dial type 5, byteAlign false)
    //   • Custom  — SlifiCustomWatchface widgets → setCustomWatchface (SDK zips then pushes)
    //   • AI      — AiSDK drives preview/install; App only supplies AiDeviceInfo + observes callbacks
    //
    // Transfer lock: online/custom acquire `.watchface` so they never overlap music/album/AGPS/OTA.
    // AI install runs inside AiSDK (it calls SifliWatchfaceSDK itself); the UI locks navigation
    // via WatchfaceHostViewController.setInstalling while AiSDK reports progress.
    //
    // This demo is **Sifli-only** for watchfaces (no JL online/custom path in the UI).

    /// Installed Sifli watchface **names** currently stored on the watch.
    /// Used by online install to decide "switch only" vs "download + push".
    func getSifliInstalledWatchfaceNames(completion: @escaping (Result<[String], Error>) -> Void) {
        sdk.getSifliInstalledWatchfaceNames { list, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success((list as? [String]) ?? [])) }
            }
        }
    }

    /// Activates an already-installed Sifli face by **name** (no ZIP transfer).
    /// Prefer this when `getSifliInstalledWatchfaceNames` already contains a matching name.
    func switchSifliWatchface(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.setSifliDisplayingWatchfaceName(name) { ok, error in
            DispatchQueue.main.async {
                Self.boolResult(ok, error, completion)
            }
        }
    }

    /// Reads the name of the watchface currently shown on a Sifli device.
    func getSifliDisplayingWatchfaceName(completion: @escaping (Result<String, Error>) -> Void) {
        sdk.getSifliDisplayingWatchfaceName { value, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(value ?? "")) }
            }
        }
    }

    /// Reads the device id required by AiSDK / AFlash (`AiDeviceInfo.Id`).
    func getDeviceId(completion: @escaping (Result<String, Error>) -> Void) {
        sdk.getDeviceId { value, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(value ?? "")) }
            }
        }
    }

    /// Pushes a server-downloaded online dial ZIP.
    ///
    /// Uses `SifliWatchfaceSDK.setOnlineWatchface`, which internally calls
    /// `SFDialPlateManager.pushDialPlate(..., type: 5, withByteAlign: false)`.
    /// Do **not** use `byteAlign: true` for online packages (that flag is for music/album/AGPS).
    ///
    /// Progress callback is normalized to `0...1` (SDK reports 0...100 integers).
    /// Acquires the exclusive `.watchface` transfer lock.
    func pushOnlineWatchfaceZip(zipURL: URL,
                                onProgress: @escaping (Float) -> Void,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        if let err = beginTransfer(.watchface) { completion(.failure(err)); return }
        guard let uuid = connectedUUID() else {
            endTransfer()
            completion(.failure(SdkError(code: -5, message: "no connected uuid")))
            return
        }
        guard FileManager.default.fileExists(atPath: zipURL.path) else {
            endTransfer()
            completion(.failure(SdkError(code: -3, message: "zip missing")))
            return
        }
        SifliWatchfaceSDK.getInstance().setOnlineWatchface(
            devIdentifier: uuid,
            filePath: zipURL,
            progressCallback: { p in
                // SDK reports 0...100 integers.
                DispatchQueue.main.async { onProgress(Float(p) / 100.0) }
            },
            finishCallback: { [weak self] ok, errInfo, errType, _ in
                DispatchQueue.main.async {
                    self?.endTransfer()
                    if ok { completion(.success(())) }
                    else {
                        completion(.failure(SdkError(
                            code: Int(errType),
                            message: errInfo ?? "online watchface fail"
                        )))
                    }
                }
            }
        )
    }

    /// Packages and pushes a custom dial built by the UI.
    ///
    /// The SDK zips QJS assets internally (`makeZip`) then pushes with dial type **5**.
    /// Custom packages use **byteAlign: true** inside the SDK path (unlike online packages).
    /// Requires a non-nil `thumbnailImage`; background is optional.
    ///
    /// Acquires the exclusive `.watchface` transfer lock.
    func pushCustomWatchface(_ watchface: SlifiCustomWatchface,
                             onCompress: ((Bool) -> Void)? = nil,
                             onProgress: @escaping (Float) -> Void,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        if let err = beginTransfer(.watchface) { completion(.failure(err)); return }
        guard let uuid = connectedUUID() else {
            endTransfer()
            completion(.failure(SdkError(code: -5, message: "no connected uuid")))
            return
        }
        SifliWatchfaceSDK.getInstance().setCustomWatchface(
            devIdentifier: uuid,
            watchface: watchface,
            compressSuccessCallback: { ok in
                DispatchQueue.main.async { onCompress?(ok) }
            },
            progressCallback: { p in
                DispatchQueue.main.async { onProgress(Float(p) / 100.0) }
            },
            finishCallback: { [weak self] ok, errInfo, errType, _ in
                DispatchQueue.main.async {
                    self?.endTransfer()
                    if ok { completion(.success(())) }
                    else {
                        completion(.failure(SdkError(
                            code: Int(errType),
                            message: errInfo ?? "custom watchface fail"
                        )))
                    }
                }
            }
        )
    }

    /// Online install pipeline used by the Online tab (aligned with HaWoFit `WatchfaceInstallVC`).
    ///
    /// # Steps
    /// 1. `getSifliInstalledWatchfaceNames` — if any installed name is a substring of
    ///    `item.name` (`catalog.name.contains(installedName)`), only call
    ///    `switchSifliWatchface` (no re-download).
    /// 2. Otherwise download `item.bin` into cache, verify `binMd5`, then
    ///    `pushOnlineWatchfaceZip`.
    /// 3. Query/switch failures fall back to download+push so the demo stays usable.
    ///
    /// # Progress mapping
    /// Download ≈ 0...40, BLE push ≈ 40...100 (percent integers for the UI bar).
    func installOnlineWatchface(_ item: OnlineWatchface,
                                onPhase: @escaping (OnlineWatchfaceInstallPhase) -> Void,
                                onProgress: @escaping (Int) -> Void,
                                onLog: ((String) -> Void)? = nil,
                                completion: @escaping (Result<Void, Error>) -> Void) {
        guard isConnected() else {
            completion(.failure(SdkError(code: 408, message: L10n.tr("status_need_connect"))))
            return
        }
        guard let binPath = item.bin, !binPath.isEmpty else {
            completion(.failure(SdkError(code: -1, message: L10n.tr("wf_err_no_bin"))))
            return
        }
        onPhase(.checking)
        getSifliInstalledWatchfaceNames { [weak self] result in
            guard let self = self else { return }
            let installed: [String]
            switch result {
            case .success(let names):
                installed = names
                onLog?("installed=\(names.joined(separator: ","))")
            case .failure(let e):
                onLog?("getSifliInstalledWatchfaceNames fail: \(e.localizedDescription); fallback download")
                installed = []
            }
            // HaWoFit match: catalog display name contains the short installed name.
            if let hit = installed.first(where: { name in
                let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
                return !n.isEmpty && item.name.contains(n)
            }) {
                onPhase(.switching)
                onLog?("already installed as \(hit); switching")
                self.switchSifliWatchface(name: hit) { switchResult in
                    switch switchResult {
                    case .success:
                        onPhase(.success)
                        onProgress(100)
                        completion(.success(()))
                    case .failure(let e):
                        onLog?("switch fail: \(e.localizedDescription); fallback download")
                        self.downloadAndPushOnline(item: item, bin: binPath, onPhase: onPhase, onProgress: onProgress, onLog: onLog, completion: completion)
                    }
                }
                return
            }
            self.downloadAndPushOnline(item: item, bin: binPath, onPhase: onPhase, onProgress: onProgress, onLog: onLog, completion: completion)
        }
    }

    /// Downloads `bin` into cache (MD5 when provided), then calls `pushOnlineWatchfaceZip`.
    /// Progress: download ≈ 0...40, BLE push ≈ 40...100.
    private func downloadAndPushOnline(item: OnlineWatchface,
                                       bin: String,
                                       onPhase: @escaping (OnlineWatchfaceInstallPhase) -> Void,
                                       onProgress: @escaping (Int) -> Void,
                                       onLog: ((String) -> Void)?,
                                       completion: @escaping (Result<Void, Error>) -> Void) {
        onPhase(.downloading)
        // Sync download API — keep off the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileName = (bin as NSString).lastPathComponent
                let zip = try WatchfaceApi.downloadToCache(
                    url: bin,
                    fileName: fileName.isEmpty ? "\(item.id).zip" : fileName,
                    expectMd5: item.binMd5,
                    onProgress: { pct in
                        DispatchQueue.main.async { onProgress(min(40, pct * 40 / 100)) }
                    }
                )
                DispatchQueue.main.async {
                    onLog?("downloaded \(zip.lastPathComponent)")
                    onPhase(.installing)
                    self.pushOnlineWatchfaceZip(zipURL: zip, onProgress: { p in
                        onProgress(40 + Int(p * 60))
                    }, completion: { result in
                        switch result {
                        case .success:
                            onPhase(.success)
                            onProgress(100)
                        case .failure:
                            onPhase(.failed)
                        }
                        completion(result)
                    })
                }
            } catch {
                DispatchQueue.main.async {
                    onPhase(.failed)
                    completion(.failure(error))
                }
            }
        }
    }

    /// Jieli online watchface install. The catalog and download are shared with Sifli;
    /// only the device transfer uses JL multiple-file transfer (`onlineDial`).
    func installJieliOnlineWatchface(_ item: OnlineWatchface,
                                     onPhase: @escaping (OnlineWatchfaceInstallPhase) -> Void,
                                     onProgress: @escaping (Int) -> Void,
                                     onLog: ((String) -> Void)? = nil,
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        guard isConnected() else {
            completion(.failure(SdkError(code: 408, message: L10n.tr("status_need_connect"))))
            return
        }
        guard let bin = item.bin, !bin.isEmpty else {
            completion(.failure(SdkError(code: -1, message: L10n.tr("wf_err_no_bin"))))
            return
        }

        onPhase(.downloading)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileName = (bin as NSString).lastPathComponent
                let fileURL = try WatchfaceApi.downloadToCache(
                    url: bin,
                    fileName: fileName.isEmpty ? "\(item.id).bin" : fileName,
                    expectMd5: item.binMd5,
                    onProgress: { pct in
                        DispatchQueue.main.async { onProgress(min(40, pct * 40 / 100)) }
                    }
                )
                let data = try Data(contentsOf: fileURL)
                DispatchQueue.main.async {
                    onLog?("downloaded \(fileURL.lastPathComponent), bytes=\(data.count)")
                    onPhase(.installing)
                    self.pushJieliOnlineWatchface(data: data, fileName: item.name, onProgress: { p in
                        onProgress(40 + Int(p * 60))
                    }, completion: { result in
                        switch result {
                        case .success:
                            onPhase(.success)
                            onProgress(100)
                        case .failure:
                            onPhase(.failed)
                        }
                        completion(result)
                    })
                }
            } catch {
                DispatchQueue.main.async {
                    onPhase(.failed)
                    completion(.failure(error))
                }
            }
        }
    }

    private func pushJieliOnlineWatchface(data: Data,
                                          fileName: String,
                                          onProgress: @escaping (Float) -> Void,
                                          completion: @escaping (Result<Void, Error>) -> Void) {
        if let error = beginTransfer(.jieliWatchface) {
            completion(.failure(error))
            return
        }
        guard let service = sdk.multipleFileTransferService else {
            endTransfer()
            completion(.failure(SdkError(code: -1, message: "multipleFileTransferService unavailable")))
            return
        }

        let model = HwMultipleFileTransferModel()
        model.fileData = data
        model.fileName = fileName

        service.start(
            withFileModels: [model],
            transferType: .onlineDial,
            readyCallback: { [weak self] _, error in
                guard let error = error else { return }
                DispatchQueue.main.async {
                    self?.endTransfer()
                    completion(.failure(error))
                }
            },
            progressCallback: { progress, _ in
                DispatchQueue.main.async { onProgress(progress) }
            },
            finishCallback: { [weak self] ok, error in
                DispatchQueue.main.async {
                    self?.endTransfer()
                    if let error = error {
                        completion(.failure(error))
                    } else if ok {
                        completion(.success(()))
                    } else {
                        completion(.failure(SdkError(code: -1, message: "online watchface transfer failed")))
                    }
                }
            }
        )
    }

    /// Returns the maximum number of Jieli custom-watchface backgrounds that fit on the device.
    func getJieliCustomWatchfaceCapacity(completion: @escaping (Result<Int, Error>) -> Void) {
        guard isConnected() else {
            completion(.failure(SdkError(code: 408, message: L10n.tr("status_need_connect"))))
            return
        }
        sdk.getCoustomInterfaceAvailableStorage { storageKB, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(JieliCustomWatchfaceRules.maxBackgroundCount(storageKB: storageKB)))
                }
            }
        }
    }

    /// Converts album images to Jieli 707N data, transfers them, then writes the dial layout.
    func pushJieliCustomWatchface(backgroundImages: [UIImage],
                                  thumbnailImage: UIImage,
                                  draft: JieliCustomWatchfaceDraft,
                                  onReady: (() -> Void)? = nil,
                                  onProgress: @escaping (Float) -> Void,
                                  completion: @escaping (Result<Void, Error>) -> Void) {
        guard isConnected() else {
            completion(.failure(SdkError(code: 408, message: L10n.tr("status_need_connect"))))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let geometry = draft.geometry
                let targetSize = CGSize(width: CGFloat(geometry.width), height: CGFloat(geometry.height))
                let thumbSize = CGSize(
                    width: CGFloat(geometry.thumbnailWidth),
                    height: CGFloat(geometry.thumbnailHeight)
                )
                let images = backgroundImages.isEmpty ? [Self.blackImage()] : backgroundImages

                var fileModels = try images.enumerated().map { index, image -> HwMultipleFileTransferModel in
                    let model = HwMultipleFileTransferModel()
                    model.fileName = "bg\(index + 1)"
                    model.fileData = try JieliWatchfaceImageEncoder.encode(
                        image,
                        size: targetSize,
                        cornerRadius: CGFloat(geometry.cornerRadius)
                    )
                    return model
                }

                let preview = HwMultipleFileTransferModel()
                preview.fileName = "pw"
                preview.fileData = try JieliWatchfaceImageEncoder.encode(
                    thumbnailImage,
                    size: thumbSize,
                    cornerRadius: CGFloat(geometry.thumbnailCornerRadius)
                )
                fileModels.append(preview)

                let config = Self.makeJieliCustomWatchfaceConfig(draft: draft, imageCount: images.count)
                DispatchQueue.main.async {
                    self.transferJieliCustomWatchface(
                        fileModels: fileModels,
                        config: config,
                        onReady: onReady,
                        onProgress: onProgress,
                        completion: completion
                    )
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    private func transferJieliCustomWatchface(fileModels: [HwMultipleFileTransferModel],
                                               config: HwJLWatchFaceConfigModel,
                                               onReady: (() -> Void)?,
                                               onProgress: @escaping (Float) -> Void,
                                               completion: @escaping (Result<Void, Error>) -> Void) {
        if let error = beginTransfer(.jieliWatchface) {
            completion(.failure(error))
            return
        }
        guard let service = sdk.multipleFileTransferService else {
            endTransfer()
            completion(.failure(SdkError(code: -1, message: "multipleFileTransferService unavailable")))
            return
        }

        service.start(
            withFileModels: fileModels,
            transferType: .customDialImage,
            readyCallback: { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.endTransfer()
                        completion(.failure(error))
                    } else {
                        onReady?()
                    }
                }
            },
            progressCallback: { value, _ in
                DispatchQueue.main.async { onProgress(value) }
            },
            finishCallback: { ok, error in
                DispatchQueue.main.async {
                    guard error == nil, ok else {
                        self.endTransfer()
                        completion(.failure(error ?? SdkError(code: -1, message: "custom watchface transfer failed")))
                        return
                    }
                    self.center.updateJLCustomWatceFace(config) { success, configError in
                        DispatchQueue.main.async {
                            self.endTransfer()
                            Self.boolResult(success, configError, completion)
                        }
                    }
                }
            }
        )
    }

    private static func makeJieliCustomWatchfaceConfig(draft: JieliCustomWatchfaceDraft,
                                                        imageCount: Int) -> HwJLWatchFaceConfigModel {
        let config = HwJLWatchFaceConfigModel()
        switch draft.displayMode {
        case .single: config.displayModeType = .displayModeType_SingleImage
        case .sequential: config.displayModeType = .displayModeType_QueueShow
        case .random: config.displayModeType = .displayModeType_RandomShow
        }
        config.imageCount = imageCount
        config.coverImageIndex = Int32(JieliCustomWatchfaceRules.normalizedCoverIndex(
            draft.coverImageIndex,
            imageCount: imageCount
        ))
        config.pointerStyle = draft.pointerStyle.rawValue
        config.rgbColorStr = draft.rgbHex
        config.compentArr = JieliCustomWatchfaceRules.componentPlacements(
            draft.components,
            isRound: draft.geometry.isRound
        ).map { placement in
            let component = HwJLWatchFaceConfigCompentModel()
            switch placement.type {
            case .time: component.compentType = .componentType_Time
            case .date: component.compentType = .componentType_Date
            case .heartRate: component.compentType = .componentType_HeartRate
            case .steps: component.compentType = .componentType_Steps
            case .distance: component.compentType = .componentType_Distance
            case .calories: component.compentType = .componentType_Calories
            case .weather: component.compentType = .componentType_Weather
            case .battery: component.compentType = .componentType_Battery
            case .off: break
            }
            component.position = placement.position
            return component
        }
        return config
    }

    private static func blackImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    // MARK: - Helpers

    /// Delivers a `ConnectionEvent` to all registered handlers (synchronously on the current queue;
    /// callers of `emit` typically already hop to main).
    private func emit(_ event: ConnectionEvent) {
        connectionHandlers.forEach { $0(event) }
    }

    /// Converts second-scale Unix epochs (~1e9) to milliseconds (~1e12).
    /// Values that already look like milliseconds are returned unchanged.
    private static func normalizeEpochMs(_ value: Int64) -> Int64 {
        // Seconds ~1e9, milliseconds ~1e12.
        if value > 0 && value < 10_000_000_000 { return value * 1000 }
        return value
    }

    /// Maps SDK `(ok, error)` pairs into `Result<Void, Error>`.
    /// Prefer the explicit `error` when present; otherwise treat `ok == false` as a generic failure.
    private static func boolResult(_ ok: Bool, _ error: Error?,
                                   _ completion: (Result<Void, Error>) -> Void) {
        if let error = error { completion(.failure(error)) }
        else if ok { completion(.success(())) }
        else { completion(.failure(SdkError(code: -1, message: "operation failed"))) }
    }
}

/// Safe subscript that returns `nil` instead of trapping on out-of-range indices.
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - AiSDK device info (HaWoFit `HwAIManager.updateDeviceInfo` parity)

/// Resolves AiSDK `HWPlatformType` for the connected watch.
///
/// HaWoFit uses `Watch.isJLProtocol` → `product.mcu == "JieLi"` from the product catalog.
/// BleSdkDemo has no catalog, so we fall back to `protocolVersion >= 100` plus the manual JieLi switch.
enum AiPlatformHelper {
    static func isJieliProtocol(_ protocolVersion: Int?) -> Bool {
        guard let pv = protocolVersion else { return false }
        return pv >= 100
    }

    static func platformType(protocolVersion: Int?, userPrefersJieli: Bool) -> HWPlatformType {
        if isJieliProtocol(protocolVersion) || userPrefersJieli {
            return .jieLi
        }
        return .sifli
    }

    static func platformLabel(_ type: HWPlatformType) -> String {
        switch type {
        case .jieLi: return "JieLi(2)"
        case .realtek: return "Realtek(1)"
        default: return "Sifli(0)"
        }
    }
}

enum AiDeviceInfoBuilder {
    struct Panel {
        var width: Int
        var height: Int
        var cornerRadius: Int
        var thumbnailWidth: Int
        var thumbnailHeight: Int
        var thumbnailCornerRadius: Int
    }

    static func make(
        repo: BleRepository,
        deviceId: String,
        panel: Panel,
        protocolVersion: Int?,
        userPrefersJieli: Bool,
        locale: String? = nil
    ) -> AiDeviceInfo {
        let info = AiDeviceInfo()
        if !deviceId.isEmpty { info.setValue(deviceId, forKey: "Id") }
        info.mac = repo.connectedMac() ?? ""
        info.name = repo.connectedName() ?? ""
        info.type = repo.loadBoundDevice()?.type ?? ""

        let boundPv = repo.loadBoundDevice()?.protocolVersion
        let resolvedPv = protocolVersion ?? boundPv
        _ = AiPlatformHelper.platformType(
            protocolVersion: resolvedPv,
            userPrefersJieli: userPrefersJieli
        )

        info.width = panel.width > 0 ? panel.width : 480
        info.height = panel.height > 0 ? panel.height : 480
        info.cornerRadius = panel.cornerRadius > 0 ? panel.cornerRadius : 240
        info.thumbnailWidth = panel.thumbnailWidth > 0 ? panel.thumbnailWidth : 264
        info.thumbnailHeight = panel.thumbnailHeight > 0 ? panel.thumbnailHeight : 264
        info.thumbnailCornerRadius = panel.thumbnailCornerRadius > 0 ? panel.thumbnailCornerRadius : 132

        info.currentLocale = locale ?? Locale.current.languageCode ?? "en"
        return info
    }

    private static func isRoundPanel(_ info: AiDeviceInfo) -> Bool {
        let shortSide = min(info.width, info.height)
        return info.cornerRadius * 2 >= shortSide
    }

    static func resolvedPlatform(
        protocolVersion: Int?,
        userPrefersJieli: Bool,
        repo: BleRepository
    ) -> HWPlatformType {
        AiPlatformHelper.platformType(
            protocolVersion: protocolVersion ?? repo.loadBoundDevice()?.protocolVersion,
            userPrefersJieli: userPrefersJieli
        )
    }
}
