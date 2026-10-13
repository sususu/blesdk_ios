
import Foundation

public class ValueWidget: Widget {
    public var valueType: Int = -1
    public var value: Int = 0

    public override init() {
        super.init()
    }

    public func getValueType() -> Int {
        return valueType
    }

    public func setValueType(_ valueType: Int) {
        self.valueType = valueType
    }

    public func getValue() -> Int {
        return value
    }

    public func setValue(_ value: Int) {
        self.value = value
    }
    
    public override func resume() -> String {
        return ""
    }
    
    public override func start() -> String {
        return ""
    }
    
    public override func pause() -> String {
        return ""
    }
    
    public override func stop() -> String {
        return ""
    }
    
}
