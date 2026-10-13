import Foundation

public class QjsDependence: Qjs {
    static let BASE_PATH = "/support_script/qjs/"
    var name: String?
    var module: String
    var path: String

    public init() {
        self.module = ""
        self.path = ""
    }

    public init(name: String, module: String, path: String) {
        self.name = name
        self.module = module
        self.path = QjsDependence.BASE_PATH + path
    }

    public init(module: String, path: String) {
        self.module = module
        self.path = QjsDependence.BASE_PATH + path
    }

    static func baseDependences() -> [QjsDependence] {
        var list = [QjsDependence]()
        let d1 = QjsDependence()
        d1.setName(name: "lv")
        d1.setModule(module: "*")
        d1.setPath(path: "lv")

        let d2 = QjsDependence()
        d2.setPath(path: "lvapp")
        d2.setModule(module: "app")
        list.append(d1)
        list.append(d2)
        return list
    }

    public func toQjs(_ isAOD: Bool) -> String {
        var result = "import "
        result += getModuleString()
        result += " from \"\(path)\""
        return result
    }

    private func getModuleString() -> String {
        var result = ""
        if module == "*" {
            result = "*"
        } else {
            result = "{ \(module) }"
        }

        if let name = name, !name.isEmpty {
            result += " as \(name)"
        }
        return result
    }

    func getName() -> String? {
        return name
    }

    func setName(name: String) {
        self.name = name
    }

    func getModule() -> String {
        return module
    }

    func setModule(module: String) {
        self.module = module
    }

    func getPath() -> String {
        return path
    }

    func setPath(path: String) {
        self.path = path
    }

    // test
    static func main() {
        // Your test code here
    }
}

