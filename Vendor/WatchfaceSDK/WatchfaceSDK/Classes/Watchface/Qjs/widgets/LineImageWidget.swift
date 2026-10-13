
import UIKit

public class LineImageWidget: SingleImageWidget {
    public var cap: Bool = false

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "linegraph", path: "linegraph.js")
    }

    public override func start() -> String {
        var sb = ""
        let name = "this.lineimg" + getJsVarName()

        var binPath = getImagePath()
        binPath = binPath.replacingOccurrences(of: ".png", with: ".bin")
        let path = "this.path() + \"\(binPath)\""
        let radius = isCap() ? getSize().height / 2 : 0
        sb += "\n"
        sb += "\t\t\(name) = new linegraph(this.root());\n"
        sb += "\t\t\(name).set_src(\(path));\n"
        sb += "\t\t\(name).set_radius(\(radius));\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"

        // 绑定数据
        if getValueType() >= 0 {
            let percent_name = "this.pp_" + getJsVarName()
            // 初始化值
            // 除以10000是固件app_db_get_val_percent获取回来就是10000倍的百分比
            sb += "\t\t\(percent_name) = lv.app_db_get_val_percent(\(getValueType()));\n"
            sb += "\t\t\(name).set_percent(\(percent_name) * 100 / 10000);\n"
            // 绑定值变化
            sb += "\t\t\(name).bind(\(getValueType()), function(idx, val) {\n"
            sb += "\t\t\t\t\(percent_name) = lv.app_db_get_val_percent(\(getValueType()));\n"
            sb += "\t\t\t\tthis.set_percent(\(percent_name) * 100 / 10000);\n"
            sb += "\t\t});\n"
        }
        return sb
    }

    public override func resume() -> String {
        var sb = ""
        let name = "this.lineimg" + getJsVarName()

        let percent_name = "this.pp_" + getJsVarName()
        // 初始化值
        // 除以10000是固件app_db_get_val_percent获取回来就是10000倍的百分比
        sb += "\t\t\(percent_name) = lv.app_db_get_val_percent(\(getValueType()));\n"
        sb += "\t\t\(name).set_percent(\(percent_name) * 100 / 10000);\n"

        return sb
    }

    func isCap() -> Bool {
        return cap
    }

    func setCap(_ cap: Bool) {
        self.cap = cap
    }
    
    public override func copy() -> Widget {
        let obj = LineImageWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.cap = self.cap
        obj.image = self.image
        obj.imagePath = self.imagePath
        
        return obj
    }
}
