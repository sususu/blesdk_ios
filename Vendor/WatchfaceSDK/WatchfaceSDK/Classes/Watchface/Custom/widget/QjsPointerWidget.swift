
import UIKit

@objc public class QjsPointerWidget: QjsWidget {
    public var center = Point.zero
    public var rotationCenter = Point.zero
    public var image: UIImage?
    
    public init(watchfaceSize: Size) {
        super.init()
        self.center = Point(x: watchfaceSize.width / 2, y: watchfaceSize.height / 2)
    }
    
    public func setImage(_ image: UIImage) {
        self.image = image
    }

    public func getCenter() -> Point {
        return center
    }

    public func setCenter(_ center: Point) {
        self.center = center
    }

    public func getImage() -> UIImage? {
        return image
    }

    public func getRotationCenter() -> Point {
        return rotationCenter
    }

    public func setRotationCenter(_ rotationCenter: Point) {
        self.rotationCenter = rotationCenter
    }
}
