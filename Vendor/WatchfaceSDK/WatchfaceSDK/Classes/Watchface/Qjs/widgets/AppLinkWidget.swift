
import UIKit

public class AppLinkWidget: ValueWidget {

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "launcher", path: "launcher.js")
    }

    public override func start() -> String {
        let name = "this.applink" + getJsVarName()
        // 创建
        var sb = ""
        sb += "\n"
        sb += "\t\t\(name) = new launcher(this.root());\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"
        sb += "\t\t\(name).set_size(\(getSize().width), \(getSize().height));\n"
        sb += "\t\t\(name).set_type(\(getValueType()));\n"
        return sb
    }
    
    public override func copy() -> Widget {
        let obj = AppLinkWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        
        return obj
    }
}
