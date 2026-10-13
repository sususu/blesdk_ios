import Foundation

@objc public enum QjsValueType: Int {
    case none = -1
    case stepsNum = 0
    case calorieNum = 1
    case heartrateNum = 2
    case temperatureNum = 4
    case temperatureTypeNum = 73
    case batteryNum = 9
    case hourNum = 12
    case minuteNum = 13
    case secondNum = 14
    case hourPointer = 150
    case minutePointer = 153
    case secondPointer = 154
    case weekData = 52
    case dateNum = 17
    case distanceNum = 146
    case weatherNum = 21
    case activityTime = 214

    static func valueOf(_ value: Int) -> QjsValueType {
        return QjsValueType(rawValue: value) ?? .none
    }

    func getValue() -> Int {
        return self.rawValue
    }
}
