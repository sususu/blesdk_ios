
import UIKit

public class PointerWidget: SingleImageWidget {
    public var centerPoint: Point = Point.zero
    public var rotationCenterPoint: Point = Point.zero
    public var startAngle: Int = 0
    public var endAngle: Int = 360

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "pointer", path: "pointer.js")
    }

    public override func start() -> String {
        let x = getCenterPoint().x - getRotationCenterPoint().x
        let y = getCenterPoint().y - getRotationCenterPoint().y

        var sb = ""
        let name = "this.pointer" + getJsVarName()
        // 创建
        var binPath = getImagePath()
        binPath = binPath.replacingOccurrences(of: ".png", with: ".bin")
        let path = "this.path() + \"\(binPath)\""
        sb += "\n"
        sb += "\t\t\(name) = new pointer(this.root());\n"
        sb += "\t\t\(name).set_src(\(path));\n"
        sb += "\t\t\(name).set_range(\(getStartAngle() * 10), \(getEndAngle() * 10));\n"
        sb += "\t\t\(name).set_pos(\(x), \(y));\n"
        sb += "\t\t\(name).set_pivot(\(getRotationCenterPoint().x), \(getRotationCenterPoint().y));\n"

        if getValueType() >= 0 {
            // 绑定数据
            let percent_name = "this.pp_" + getJsVarName()
            // 初始化值
            sb += "\t\t\(percent_name) = lv.app_db_get_val_percent(\(getValueType()));\n"
            sb += "\t\t\(name).set_value(\(percent_name) * (\(getEndAngle() * 10) - \(getStartAngle() * 10)) / 10000);\n"
            // 绑定数据
            sb += "\t\t\(name).bind(\(getValueType()), function(idx, val) {\n"
            sb += "\t\t\t\t\(percent_name) = lv.app_db_get_val_percent(\(getValueType()));\n"
            sb += "\t\t\t\tthis.set_value(\(percent_name) * (\(getEndAngle() * 10) - \(getStartAngle() * 10)) / 10000);\n"
            sb += "\t\t});\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.pointer" + getJsVarName()
        let percent_name = "this.pp_" + getJsVarName()
        // 初始化值
        sb += "\t\t\(percent_name) = lv.app_db_get_val_percent(\(getValueType()));\n"
        sb += "\t\t\(name).set_value(\(percent_name) * (\(getEndAngle() * 10) - \(getStartAngle() * 10)) / 10000);\n"
        return sb
    }

    public func getCenterPoint() -> Point {
        return centerPoint
    }

    public func setCenterPoint(_ centerPoint: Point) {
        self.centerPoint = centerPoint
    }

    public func getRotationCenterPoint() -> Point {
        return rotationCenterPoint
    }

    public func setRotationCenterPoint(_ rotationCenterPoint: Point) {
        self.rotationCenterPoint = rotationCenterPoint
    }

    public func getStartAngle() -> Int {
        return startAngle
    }

    public func setStartAngle(_ startAngle: Int) {
        self.startAngle = startAngle
    }

    public func getEndAngle() -> Int {
        return endAngle
    }

    public func setEndAngle(_ endAngle: Int) {
        self.endAngle = endAngle
    }
    
    public override func copy() -> Widget {
        let obj = PointerWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.image = self.image
        obj.imagePath = self.imagePath
        obj.centerPoint = self.centerPoint
        obj.rotationCenterPoint = self.rotationCenterPoint
        obj.startAngle = self.startAngle
        obj.endAngle = self.endAngle
        return obj
    }
}
