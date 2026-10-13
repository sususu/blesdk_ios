
import UIKit

public class Widget: QjsLifeCycle {
    public var name: String = ""
    public var namePrefix: String = ""
    public var nameSuffix: String = ""
    public var location: Point = Point.zero
    public var size: Size = Size.zero
    public var dependence: QjsDependence?
    public var jsVarName: String = ""

    public init() {}

    public func getName() -> String {
        return name
    }

    public func setName(_ name: String) {
        self.name = name
    }

    public func getNamePrefix() -> String {
        return namePrefix
    }

    public func setNamePrefix(_ namePrefix: String) {
        self.namePrefix = namePrefix
    }

    public func getNameSuffix() -> String {
        return nameSuffix
    }

    public func setNameSuffix(_ nameSuffix: String) {
        self.nameSuffix = nameSuffix
    }

    public func getLocation() -> Point {
        return location
    }

    public func setLocation(_ location: Point) {
        self.location = location
    }

    public func getSize() -> Size {
        return size
    }

    public func setSize(_ size: Size) {
        self.size = size
    }

    public func getDependence() -> QjsDependence? {
        return dependence
    }

    public func setDependence(_ dependence: QjsDependence) {
        self.dependence = dependence
    }

    public func getJsVarName() -> String {
        return jsVarName
    }

    public func setJsVarName(_ jsVarName: String) {
        self.jsVarName = jsVarName
    }

    public func start() -> String {
        return ""
    }
    
    public func refresh() -> String {
        return ""
    }
    
    public func resume() -> String {
        return ""
    }
    
    public func pause() -> String {
        return ""
    }
    
    public func stop() -> String {
        return ""
    }
    
    public func toQjs(_ isAOD: Bool) -> String {
        return ""
    }
    
    public func copy() -> Widget {
        return Widget()
    }
}
