
import UIKit

public class SequenceImageWidget: ValueWidget {
    public var images: [UIImage] = []
    public var imagePaths: [String] = []
    public var resMode: String = "once"
    public var imagePrefix: String = ""
    public var resInterval: Int = 80
    public var startDelay: Int = 0

    public override init() {
        super.init()
        self.dependence = QjsDependence(module: "seqframe", path: "seqframe.js")
    }

    public override func start() -> String {
        var sb = ""
        let name = "this.seq" + getJsVarName()
        let pathName = "this.seqpath" + getJsVarName()
        let fontImagePath = "this.path() + \"\(getImagePrefix())\""
        sb += "\n"
        sb += "\t\t\(pathName) = \(fontImagePath);\n"
        sb += "\t\t\(name) = new seqframe(this.root());\n"
        sb += "\t\t\(name).set_pos(\(getLocation().x), \(getLocation().y));\n"
        // 图片前缀
        let frameCount = images.isEmpty ? imagePaths.count : images.count
        sb += "\t\t\(name).prefix(\(pathName), \(frameCount));\n"
        // 播放模式
        let mode = getResMode() == "once" ? 2 : 1
        sb += "\t\t\(name).playback_mode(\(mode));\n"
        // 播放延迟
        sb += "\t\t\(name).refresh_open(\(getResInterval()), \(getStartDelay()));\n"
        sb += "\t\t\(name).select(0);\n"
        return sb
    }

    public override func pause() -> String {
        let name = "this.seq" + getJsVarName()
        return "\t\t\(name).refresh_pause();\n"
    }

    public override func resume() -> String {
        let name = "this.seq" + getJsVarName()
        return "\t\t\(name).refresh_resume();\n"
    }

    public func getImages() -> [UIImage] {
        return images
    }

    public func setImages(_ images: [UIImage]) {
        self.images = images
    }

    public func getImagePaths() -> [String] {
        return imagePaths
    }

    public func setImagePaths(_ imagePaths: [String]) {
        self.imagePaths = imagePaths
    }

    public func getResMode() -> String {
        return resMode
    }

    public func setResMode(_ resMode: String) {
        self.resMode = resMode
    }

    public func getImagePrefix() -> String {
        return imagePrefix
    }

    public func setImagePrefix(_ imagePrefix: String) {
        self.imagePrefix = imagePrefix
    }

    public func getResInterval() -> Int {
        return resInterval
    }

    public func setResInterval(_ resInterval: Int) {
        self.resInterval = resInterval
    }

    public func getStartDelay() -> Int {
        return startDelay
    }

    public func setStartDelay(_ startDelay: Int) {
        self.startDelay = startDelay
    }
    
    public override func copy() -> Widget {
        let obj = SequenceImageWidget()
        obj.location = self.location
        obj.size = self.size
        obj.valueType = self.valueType
        obj.images = self.images
        obj.imagePaths = self.imagePaths
        obj.resMode = self.resMode
        obj.imagePrefix = self.imagePrefix
        obj.resInterval = self.resInterval
        obj.startDelay = self.startDelay
        return obj
    }
}
