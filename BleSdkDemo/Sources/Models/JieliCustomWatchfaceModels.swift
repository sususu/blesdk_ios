import Foundation

enum JieliWatchfaceDisplayMode: Int, CaseIterable {
    case single = 0
    case sequential = 1
    case random = 2

    var localizationKey: String {
        switch self {
        case .single:
            return "wf_jl_mode_single"
        case .sequential:
            return "wf_jl_mode_sequential"
        case .random:
            return "wf_jl_mode_random"
        }
    }
}

enum JieliWatchfacePointerStyle: Int32, CaseIterable {
    case none = 0
    case style1 = 1
    case style2 = 2
    case style3 = 3

    var localizationKey: String {
        switch self {
        case .none:
            return "wf_jl_pointer_none"
        case .style1:
            return "wf_jl_pointer_1"
        case .style2:
            return "wf_jl_pointer_2"
        case .style3:
            return "wf_jl_pointer_3"
        }
    }
}

enum JieliWatchfaceComponentType: Int, CaseIterable {
    case off
    case time
    case heartRate
    case steps
    case calories
    case battery
    case weather
    case distance
    case date

    var localizationKey: String {
        switch self {
        case .off:
            return "wf_jl_component_off"
        case .time:
            return "wf_jl_component_time"
        case .heartRate:
            return "wf_jl_component_heart_rate"
        case .steps:
            return "wf_jl_component_steps"
        case .calories:
            return "wf_jl_component_calories"
        case .battery:
            return "wf_jl_component_battery"
        case .weather:
            return "wf_jl_component_weather"
        case .distance:
            return "wf_jl_component_distance"
        case .date:
            return "wf_jl_component_date"
        }
    }

    var rowHeight: CGFloat {
        self == .time ? 109 : (self == .off ? 0 : 28)
    }
}

struct JieliCustomWatchfaceGeometry: Equatable {
    var width: Int
    var height: Int
    var cornerRadius: Int
    var thumbnailWidth: Int
    var thumbnailHeight: Int
    var thumbnailCornerRadius: Int

    var isRound: Bool {
        width == height && cornerRadius * 2 >= min(width, height)
    }
}

struct JieliCustomWatchfaceDraft: Equatable {
    var geometry: JieliCustomWatchfaceGeometry
    var displayMode: JieliWatchfaceDisplayMode = .single
    var pointerStyle: JieliWatchfacePointerStyle = .none
    var components: [JieliWatchfaceComponentType] = [.time, .heartRate, .steps, .calories]
    var rgbHex: String = "FFFFFF"
    var coverImageIndex: Int = 0
}

struct JieliWatchfaceComponentPlacement: Equatable {
    let type: JieliWatchfaceComponentType
    let position: CGPoint

    static func == (
        lhs: JieliWatchfaceComponentPlacement,
        rhs: JieliWatchfaceComponentPlacement
    ) -> Bool {
        lhs.type == rhs.type
            && lhs.position.x == rhs.position.x
            && lhs.position.y == rhs.position.y
    }
}

enum JieliCustomWatchfaceRules {
    static let componentWidth: CGFloat = 212

    static func maxBackgroundCount(storageKB: Int) -> Int {
        let usable = storageKB * 1024 - 100 * 1024 - 70_800
        guard usable > 0 else { return 1 }
        return min(8, max(1, usable / 220_128))
    }

    static func normalizedCoverIndex(_ index: Int, imageCount: Int) -> Int {
        guard imageCount > 0 else { return 0 }
        return min(max(index, 0), imageCount - 1)
    }

    static func componentPlacements(
        _ components: [JieliWatchfaceComponentType],
        isRound: Bool
    ) -> [JieliWatchfaceComponentPlacement] {
        let x: CGFloat = isRound ? 121 : 100
        var y: CGFloat = 52

        return components.compactMap { component in
            guard component != .off else { return nil }

            let placement = JieliWatchfaceComponentPlacement(
                type: component,
                position: CGPoint(x: x, y: y)
            )
            y += component.rowHeight + 14
            return placement
        }
    }
}
