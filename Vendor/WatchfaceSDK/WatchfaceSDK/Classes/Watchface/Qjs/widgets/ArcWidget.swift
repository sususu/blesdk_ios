
import UIKit

public class ArcWidget: ValueWidget {
    public var lineWidth: Int = 0
    public var cap: Bool = false
    public var foreColor: UIColor = UIColor(red: 0xF3/255.0, green: 0x91/255.0, blue: 0xA9/255.0, alpha: 1.0)
    public var backColor: UIColor = UIColor.white
    public var startAngle: Int = 0
    public var endAngle: Int = 360

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "roundbar", path: "roundbar.js")
    }

    public override func start() -> String {
        let name = "this.arc" + getJsVarName()
        let red1 = String(format: "0x%02X", Int(backColor.cgColor.components![0] * 255))
        let green1 = String(format: "0x%02X", Int(backColor.cgColor.components![1] * 255))
        let blue1 = String(format: "0x%02X", Int(backColor.cgColor.components![2] * 255))
        let colorStr1 = String(format: "lv.color_make(%@,%@,%@)", red1, green1, blue1)

        let red2 = String(format: "0x%02X", Int(foreColor.cgColor.components![0] * 255))
        let green2 = String(format: "0x%02X", Int(foreColor.cgColor.components![1] * 255))
        let blue2 = String(format: "0x%02X", Int(foreColor.cgColor.components![2] * 255))
        let colorStr2 = String(format: "lv.color_make(%@,%@,%@)", red2, green2, blue2)

        var sb = ""
        // 创建
        sb += "\n"
        sb += "\t\t\(name) = new roundbar(this.root());\n"
        sb += "\t\t\(name).set_line_width(\(getLineWidth()));\n"
        sb += "\t\t\(name).set_angles(\(getStartAngle()), \(getEndAngle()));\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"
        sb += "\t\t\(name).set_color(\(colorStr1), \(colorStr2));\n"
        sb += "\t\t\(name).set_size(\(getSize().width), \(getSize().height));\n"

        if getValueType() >= 0 {
            // 绑定数据
            let percent_name = "this.pp_" + getJsVarName()
            // 初始化值
            sb += String(format: "\t\t%@ = lv.app_db_get_val_percent(%@);\n", percent_name, getValueType())
            sb += String(format: "\t\t%@.set_value(%@*(%@-%@)/10000);\n", name, percent_name, getEndAngle(), getStartAngle())
            // 绑定数据
            sb += String(format: "\t\t%@.bind(%@, function(idx, val)", name, getValueType())
            sb += " {\n"
            sb += String(format: "\t\t\t%@ = lv.app_db_get_val_percent(%@);\n", percent_name, getValueType())
            sb += String(format: "\t\t\t%@.set_value(%@*(%@-%@)/10000);\n", "this", percent_name, getEndAngle(), getStartAngle())
            sb += "\t\t});\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.arc" + getJsVarName()
        let percent_name = "this.pp_" + getJsVarName()
        sb += String(format: "\t\t%@ = lv.app_db_get_val_percent(%@);\n", percent_name, getValueType())
        sb += String(format: "\t\t%@.set_value(%@*(%@-%@)/10000);\n", name, percent_name, getEndAngle(), getStartAngle())
        return sb
    }

    public func getLineWidth() -> Int {
        return lineWidth
    }

    public func setLineWidth(_ lineWidth: Int) {
        self.lineWidth = lineWidth
    }

    public func isCap() -> Bool {
        return cap
    }

    public func setCap(_ cap: Bool) {
        self.cap = cap
    }

    public func getForeColor() -> UIColor {
        return foreColor
    }

    public func setForeColor(_ foreColor: UIColor) {
        self.foreColor = foreColor
    }

    public func getBackColor() -> UIColor {
        return backColor
    }

    public func setBackColor(_ backColor: UIColor) {
        self.backColor = backColor
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
        let obj = ArcWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.lineWidth = self.lineWidth
        obj.cap = self.cap
        obj.foreColor = self.foreColor
        obj.backColor = self.backColor
        obj.startAngle = self.startAngle
        obj.endAngle = self.endAngle
        
        return obj
    }
}

