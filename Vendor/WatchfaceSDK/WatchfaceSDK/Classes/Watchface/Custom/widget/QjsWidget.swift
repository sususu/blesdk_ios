
import UIKit

@objc open class QjsWidget: NSObject {
    @objc public var id: Int
    @objc public var width: Int
    @objc public var height: Int
    @objc public var x: Int
    @objc public var y: Int
    @objc public var tintColor: UIColor?
    @objc public var valueType: Int
    @objc public var name: String
    
    @objc public override init() {
        self.id = 0
        self.width = 0
        self.height = 0
        self.x = 0
        self.y = 0
        self.valueType = 0
        self.name = ""
    }
    
    public init(id: Int, width: Int, height: Int, x: Int, y: Int, valueType: Int, name: String) {
        self.id = id
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.valueType = valueType
        self.name = name
    }

    open func qjsWidgets() -> [Widget] {
        fatalError("This method must be overridden")
    }

    /**
     * Width, Height
     * @return CGSize
     */
    func getSize() -> Size {
        return Size(width: width, height: height)
    }
    
    func setSize(_ size: Size) {
        width = size.width
        height = size.height
    }

    /**
     * Left, Top
     * @return CGPoint
     */
    func getLocation() -> Point {
        return Point(x: x, y: y)
    }
    
    func setLocation(_ loc: Point) {
        x = loc.x
        y = loc.y
    }

    func getWidth() -> Int {
        return width
    }

    func getHeight() -> Int {
        return height
    }

    func getX() -> Int {
        return x
    }

    func setX(_ x: Int) {
        self.x = x
    }

    func getY() -> Int {
        return y
    }

    func setY(_ y: Int) {
        self.y = y
    }

    func getTintColor() -> UIColor? {
        return tintColor
    }

    func setTintColor(_ tintColor: UIColor) {
        self.tintColor = tintColor
    }

    func getValueType() -> Int {
        return valueType
    }

    func setValueType(_ valueType: Int) {
        self.valueType = valueType
    }

    func getId() -> Int {
        return id
    }

    func setId(_ id: Int) {
        self.id = id
    }

    func getName() -> String {
        return name
    }

    func setName(_ name: String) {
        self.name = name
    }
}
