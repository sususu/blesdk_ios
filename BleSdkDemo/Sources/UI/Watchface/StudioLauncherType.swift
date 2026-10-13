import Foundation

/// Firmware complication / launcher ids for `QjsAppLinkWidget` (aligned with Android `StudioLauncherType`).
enum StudioLauncherType {
    /// Call history
    static let callRecord = 1006
    /// Weather app
    static let weather = 1027
    /// Activity / workout data
    static let activity = 1101
    /// Phone dialer
    static let phone = 1102
    /// Notification center
    static let notifications = 1115
}
