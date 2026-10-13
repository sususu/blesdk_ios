import UIKit

/// Circular progress / arc bound to a `QjsValueType` percent value (e.g. battery).
///
/// Maps to low-level `ArcWidget` (`roundbar.js`).
@objc public class QjsArcWidget: QjsWidget {
    @objc public var lineWidth: Int = 10
    @objc public var foreColor: UIColor = UIColor(red: 0xF3 / 255.0, green: 0x91 / 255.0, blue: 0xA9 / 255.0, alpha: 1)
    @objc public var backColor: UIColor = .white
    @objc public var startAngle: Int = 0
    @objc public var endAngle: Int = 360
    @objc public var cap: Bool = false

    @objc public override init() {
        super.init()
        self.name = "Arc"
        self.width = 120
        self.height = 120
        self.valueType = QjsValueType.batteryNum.rawValue
    }

    @objc public convenience init(tintColor: UIColor) {
        self.init()
        self.foreColor = tintColor
        self.tintColor = tintColor
    }

    open override func qjsWidgets() -> [Widget] {
        let widget = ArcWidget()
        widget.setLocation(Point(x: x, y: y))
        widget.setSize(Size(width: width, height: height))
        widget.setValueType(valueType)
        widget.setLineWidth(lineWidth)
        widget.setForeColor(foreColor)
        widget.setBackColor(backColor)
        widget.setStartAngle(startAngle)
        widget.setEndAngle(endAngle)
        widget.setCap(cap)
        return [widget]
    }
}
