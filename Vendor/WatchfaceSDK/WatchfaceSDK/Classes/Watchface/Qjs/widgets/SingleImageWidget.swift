
import UIKit

public class SingleImageWidget: ValueWidget {
    public var image: UIImage?
    public var linkToApp: Int = 0
    public var imagePath: String = ""
    
    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "img", path: "img.js")
    }
    
    @objc dynamic public override func start() -> String {
        var sb = ""
        let name = "this.img" + getJsVarName()
        var binPath = getImagePath()
        binPath = binPath.replacingOccurrences(of: ".png", with: ".bin")
        let path = "this.path() + \"\(binPath)\""
        
        sb += "\n"
        sb += "\t\t\(name) = new img(this.root());\n"
        sb += "\t\t\(name).set_src(\(path));\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"
        
        return sb
    }
    
    public func getImage() -> UIImage? {
        return image
    }
    
    public func setImage(_ image: UIImage) {
        self.image = image
    }
    
    public func getLinkToApp() -> Int {
        return linkToApp
    }
    
    public func setLinkToApp(_ linkToApp: Int) {
        self.linkToApp = linkToApp
    }
    
    public func getImagePath() -> String {
        return imagePath
    }
    
    public func setImagePath(_ imagePath: String) {
        self.imagePath = imagePath
    }

    public override func copy() -> Widget {
        let obj = SingleImageWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.image = self.image
        obj.imagePath = self.imagePath
        return obj
    }
}
