
import UIKit

public class TextWidget: ValueWidget {
    public var alignment: NSTextAlignment = .left
    public var color: UIColor = .black
    public var fontFamily: String = "HarmonyOS_Sans_SC_Regular"
    public var fontSize: Int = 32

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "label", path: "label.js")
    }

    public override func start() -> String {
        var sb = ""
        let name = "this.txt" + getJsVarName()
        // 创建
        sb += "\n"
        sb += "\t\t\(name) = new label(this.root());\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"
        sb += "\t\t\(name).set_size(\(getSize().width), \(getSize().height));\n"
        let align: Int
        switch getAlignment() {
        case .left:
            align = 0
        case .right:
            align = 2
        default:
            align = 1
        }

        let red = String(format: "0x%02X", Int(getColor().cgColor.components![0] * 255))
        let green = String(format: "0x%02X", Int(getColor().cgColor.components![1] * 255))
        let blue = String(format: "0x%02X", Int(getColor().cgColor.components![2] * 255))
        let colorStr = String(format: "lv.color_make(%@,%@,%@)", red, green, blue)
        sb += "\t\t\(name).set_align(\(align));\n"
//        if getColor().alpha() < 255 {
//            sb += "\t\t\(name).set_style_local_text_opa(0, 0, \(getColor().alpha()))\n"
//        }
        sb += "\t\t\(name).set_fixed_font(\(getFontSize()), \(colorStr), \"\(getFontFamily())\", 0);\n"

        if getValueType() >= 0 {
            // 绑定数据
            let text_name = "this.text_" + getJsVarName()
            // 初始化值
            sb += String(format: "\t\t%@ = lv.app_db_get_val_text(%@);\n", text_name, getValueType())
            sb += String(format: "\t\t%@.set_text(%@);\n", name, text_name)
            // 绑定数据
            sb += String(format: "\t\t%@.bind(%@, function(idx, val) {\n", name, getValueType())
            sb += String(format: "\t\t\t%@ = lv.app_db_get_val_text(%@);\n", text_name, getValueType())
            sb += String(format: "\t\t\t%@.set_text(%@);\n", "this", text_name)
            sb += "\t\t});\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.txt" + getJsVarName()
        // 初始化值
        let text_name = "this.text_" + getJsVarName()
        sb += String(format: "\t\t%@ = lv.app_db_get_val_text(%@);\n", text_name, getValueType())
        sb += String(format: "\t\t%@.set_text(%@);\n", name, text_name)
        return sb
    }

    public func getAlignment() -> NSTextAlignment {
        return alignment
    }

    public func setAlignment(_ alignment: NSTextAlignment) {
        self.alignment = alignment
    }

    public func getColor() -> UIColor {
        return color
    }

    public func setColor(_ color: UIColor) {
        self.color = color
    }

    public func getFontFamily() -> String {
        return fontFamily
    }

    public func setFontFamily(_ fontFamily: String) {
        self.fontFamily = fontFamily
    }

    public func getFontSize() -> Int {
        return fontSize
    }

    public func setFontSize(_ fontSize: Int) {
        self.fontSize = fontSize
    }
    
    public override func copy() -> Widget {
        let obj = TextWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.alignment = self.alignment
        obj.color = self.color
        obj.fontFamily = self.fontFamily
        obj.fontSize = self.fontSize
        return obj
    }
}
