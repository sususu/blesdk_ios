
import UIKit

public class GroupWidget: ValueWidget {
    public var images: [Int: UIImage] = [:]
    public var imagePaths: [Int: String] = [:]
    public var imagePrefix: String = ""
    public var alignment: NSTextAlignment = .left

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "label", path: "label.js")
    }

    public override func start() -> String {
        var sb = ""
        if getImages().isEmpty { return sb }
        let name = "this.group" + getJsVarName()
        let pathName = "this.gpath" + getJsVarName()
        let fontImagePath = "this.path() + \"\(getImagePrefix())\""
        // 创建
        sb += "\n"
        sb += "\t\t\(pathName) = \(fontImagePath);\n"
        sb += "\t\t\(name) = new label(this.root());\n"
        sb += "\t\t\(name).set_long_mode(1);\n"
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
        // 2023-05-17 杨浩：图片字体也不用set_local_font了
        // sb += "\t\t\(name).set_local_font(\(maxHeight), lv.color_make(0xff,0xff,0xff))\n"
        sb += "\t\t\(name).set_align(\(align));\n"
        sb += "\t\t\(name).set_font_image(0, 0, \(pathName), 0);\n"

        if getValueType() >= 0 {
            // 绑定数据
            let textName = "this.gtext_" + getJsVarName()
            // 初始化值
            sb += "\t\t\(textName) = lv.app_db_get_val_text(\(getValueType()));\n"
            sb += "\t\t\(name).set_text(\(textName));\n"
            // 绑定数据
            sb += "\t\t\(name).bind(\(getValueType()), function(idx, val) {\n"
            sb += "\t\t\t\(textName) = lv.app_db_get_val_text(\(getValueType()));\n"
            sb += "\t\t\tthis.set_text(\(textName));\n"
            sb += "\t\t})\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.group" + getJsVarName()
        let textName = "this.gtext_" + getJsVarName()
        sb += "\t\t\(textName) = lv.app_db_get_val_text(\(getValueType()));\n"
        sb += "\t\t\(name).set_text(\(textName));\n"
        return sb
    }

    public func getImages() -> [Int: UIImage] {
        return images
    }

    public func setImages(_ images: [Int: UIImage]) {
        self.images = images
    }

    public func getImagePaths() -> [Int: String] {
        return imagePaths
    }

    public func setImagePaths(_ imagePaths: [Int: String]) {
        self.imagePaths = imagePaths
    }

    public func getImagePrefix() -> String {
        return imagePrefix
    }

    public func setImagePrefix(_ imagePrefix: String) {
        self.imagePrefix = imagePrefix
    }

    public func getAlignment() -> NSTextAlignment {
        return alignment
    }

    public func setAlignment(_ alignment: NSTextAlignment) {
        self.alignment = alignment
    }
    
    public override func copy() -> Widget {
        let obj = GroupWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.images = self.images
        obj.imagePaths = self.imagePaths
        obj.imagePrefix = self.imagePrefix
        obj.alignment = self.alignment
        
        return obj
    }
}
