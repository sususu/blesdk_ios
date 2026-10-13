import Foundation

struct BleDeviceItem: Equatable {
    var name: String?
    var macAddress: String
    var uuid: String?
    var rssi: Int?
}

struct BleDeviceInfoModel {
    var id: String?
    var type: String?
    var firmwareVersion: String?
    var mac: String?
    var battery: Int?
    var protocolVersion: Int?
    var displayingWatchfaceId: String?
    /// Offline-map device UUID from firmware (`HwDeviceInfo.mapUUID`).
    var mapUuid: String?
    /// Whether the watch has already accepted a map auth code.
    var mapAuthorized: Bool = false
}

struct BoundDeviceRecord: Codable {
    var macAddress: String
    var name: String?
    var deviceId: String?
    var type: String?
    var firmwareVersion: String?
    var battery: Int?
    var protocolVersion: Int?
    var mapUuid: String?
    var mapAuthorized: Bool?
}

struct HealthDataCount {
    var activityCount: Int = 0
    var sleepCount: Int = 0
    var heartrateCount: Int = 0
    var hrfCount: Int = 0
}

struct MusicStorage {
    var availableKb: Int
    var totalKb: Int
}

struct BleGpsStatusModel {
    var agpsValidStartTimeMs: Int64 = 0
    var agpsValidEndTimeMs: Int64 = 0
    var gpsClipType: String?
    var gpsFirmwareVersion: String?
    var gpsFirmwareBuild: Int = 0
}

enum DevicePhase {
    case idle
    case connected
    case bound
    case syncing
    case unbinding
}

enum FlowStepStatus {
    case pending
    case running
    case done
    case failed
    case skipped
}

struct FlowStep {
    var api: String
    var description: String
    var platformNote: String?
    var status: FlowStepStatus = .pending
    var detail: String?
}

enum ConnectionEvent {
    case connected(name: String?, mac: String?)
    case disconnected
    /// 对齐 HaWoFit BleConnectManager 的自动重连过程通知
    case reconnecting(attempt: Int, reason: String)
    case reconnectFailed(attempt: Int, message: String)
}

struct SdkError: Error, LocalizedError {
    let code: Int
    let message: String
    var errorDescription: String? { "[\(code)] \(message)" }
}
