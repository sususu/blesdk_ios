
import UIKit

public class LinkTextWidget: TextWidget {
    public var linkSymbol: String = "%"
    // 设置文本模式, 此接口需要在set_size前调用
        /*
         * 0: 将对象大小扩展为文本大小，此模式下宽高均无效
         * 1: 保持对象的宽度，文本太长会自动换行，扩展对象的高度，此模式宽有效，高无效
         * 2: 如果文本太长，会在最后以...形式省略，此模式宽高均有效
         * 3: 保持大小并来回滚动文本，此模式宽高均有效
         * 4: 保持大小并循环滚动文本，此模式宽高均有效
         * 5：保持大小并裁剪文本 ，此模式宽高均有效
         */
    public var contentDisplayType: Int = 3
    public var secondValueType: Int = -1
    public var secondText: String = ""
    public var secondValue: Int = -1

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "linklabel", path: "linklabel.js")
    }

    public override func start() -> String {
        var sb = ""
        let name = "this.linktxt" + getJsVarName()
        // 创建
        sb += "\n"
        sb += "\t\t\(name) = new linklabel(this.root());\n"
        sb += "\t\t\(name).set_long_mode(5);\n"
        // 设置linklabel的显示项
        /*
         * 1:显示分隔符左边的字符串
         * 2:显示分隔符右边的字符串
         * 3:显示分隔符两边的字符串
         */
        sb += "\t\t\(name).set_items(3);\n"
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
        if !getLinkSymbol().isEmpty {
            sb += "\t\t\(name).set_sep(\"\(getLinkSymbol())\");\n"
        }

        if getValueType() >= 0 {
            // 绑定数据
            let textL_name = "this.ltext_l_" + getJsVarName()
            let textR_name = "this.ltext_r_" + getJsVarName()
            // 初始化值
            sb += String(format: "\t\t%@ = lv.app_db_get_val_text(%@);\n", textL_name, getValueType())
            sb += String(format: "\t\t%@.set_text(1, %@);\n", name, textL_name)
            sb += String(format: "\t\t%@ = lv.app_db_get_val_text(%@);\n", textR_name, getSecondValueType())
            sb += String(format: "\t\t%@.set_text(2, %@);\n", name, textR_name)
            // 绑定数据
            sb += String(format: "\t\t%@.data_bind(%@);\n", name, getValueType())
            sb += String(format: "\t\t%@.bind(%@, function(idx, val) {\n", name, getSecondValueType())
            sb += String(format: "\t\t\t%@ = lv.app_db_get_val_text(%@);\n", textL_name, getValueType())
            sb += String(format: "\t\t\t%@.set_text(1, %@)\n", "this", textL_name)
            sb += String(format: "\t\t\t%@ = lv.app_db_get_val_text(%@);\n", textR_name, getSecondValueType())
            sb += String(format: "\t\t\t%@.set_text(2, %@)\n", "this", textR_name)
            sb += "\t\t});\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.linktxt" + getJsVarName()
        let textL_name = "this.ltext_l_" + getJsVarName()
        let textR_name = "this.ltext_r_" + getJsVarName()

        sb += String(format: "\t\t%@.set_text(1, %@);\n", name, textL_name)
        sb += String(format: "\t\t%@.set_text(2, %@);\n", name, textR_name)

        return sb
    }

    public func getLinkSymbol() -> String {
        return linkSymbol
    }

    public func setLinkSymbol(_ linkSymbol: String) {
        self.linkSymbol = linkSymbol
    }

    public func getContentDisplayType() -> Int {
        return contentDisplayType
    }

    public func setContentDisplayType(_ contentDisplayType: Int) {
        self.contentDisplayType = contentDisplayType
    }

    public func getSecondValueType() -> Int {
        return secondValueType
    }

    public func setSecondValueType(_ secondValueType: Int) {
        self.secondValueType = secondValueType
    }

    public func getSecondText() -> String {
        return secondText
    }

    public func setSecondText(_ secondText: String) {
        self.secondText = secondText
    }

    public func getSecondValue() -> Int {
        return secondValue
    }

    public func setSecondValue(_ secondValue: Int) {
        self.secondValue = secondValue
    }
    
    public override func copy() -> Widget {
        let obj = LinkTextWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.alignment = self.alignment
        obj.color = self.color
        obj.fontFamily = self.fontFamily
        obj.fontSize = self.fontSize
        obj.linkSymbol = self.linkSymbol
        obj.contentDisplayType = self.contentDisplayType
        obj.secondValueType = self.secondValueType
        obj.secondText = self.secondText
        
        return obj
    }
}
