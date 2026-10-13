
import UIKit

public class OptionWidget: ValueWidget {
    public var images: [String: UIImage] = [:]
    public var imagePaths: [String] = []
    public var maxCount: Int = 0
    public var imagePrefix: String = ""

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "idximg", path: "idximg.js")
    }

    public override func start() -> String {
        var sb = ""
        let name = "this.option" + getJsVarName()
        // 创建
        sb += "\n"
        sb += "\t\t\(name) = new idximg(this.root());\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"
        sb += "\t\t\(name).prefix(this.path() + \"\(getImagePrefix())\");\n"

        if getValueType() >= 0 {
            // 绑定数据
            let index_name = "this.pe_" + getJsVarName()
            // 初始化值
            sb += "\t\t\(index_name) = lv.app_db_get_val_enum(\(getValueType()));\n"
            sb += "\t\t\(name).select(\(index_name));\n"
            // 绑定数据
            sb += "\t\t\(name).bind(\(getValueType()), function(idx, val) {\n"
            sb += "\t\t\t\(index_name) = lv.app_db_get_val_enum(\(getValueType()));\n"
            sb += "\t\t\tthis.select(\(index_name));\n"
            sb += "\t\t});\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.option" + getJsVarName()
        let index_name = "this.pe_" + getJsVarName()
        // 初始化值
        sb += "\t\t\(index_name) = lv.app_db_get_val_enum(\(getValueType()));\n"
        sb += "\t\t\(name).select(\(index_name));\n"
        return sb
    }

    public func getImages() -> [String: UIImage] {
        return images
    }

    public func setImages(_ images: [String: UIImage]) {
        self.images = images
    }

    public func getImagePaths() -> [String] {
        return imagePaths
    }

    public func setImagePaths(_ imagePaths: [String]) {
        self.imagePaths = imagePaths
    }

    public func getMaxCount() -> Int {
        return maxCount
    }

    public func setMaxCount(_ maxCount: Int) {
        self.maxCount = maxCount
    }

    public func getImagePrefix() -> String {
        return imagePrefix
    }

    public func setImagePrefix(_ imagePrefix: String) {
        self.imagePrefix = imagePrefix
    }
    
    public override func copy() -> Widget {
        let obj = OptionWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.imagePrefix = self.imagePrefix
        obj.images = self.images
        obj.imagePaths = self.imagePaths
        obj.maxCount = self.maxCount
        return obj
    }
}
