import UIKit

/// Two DB text values joined by a separator (low-level `LinkTextWidget` / `linklabel.js`).
@objc public class QjsLinkTextWidget: QjsWidget {
    @objc public var linkSymbol: String = "/"
    @objc public var secondValueType: Int = -1
    @objc public var fontSize: Int = 26
    @objc public var textColor: UIColor = .white

    @objc public override init() {
        super.init()
        self.name = "LinkText"
        self.width = 160
        self.height = 32
    }

    @objc public convenience init(primaryType: Int, secondType: Int, symbol: String = "/", tintColor: UIColor = .white) {
        self.init()
        self.valueType = primaryType
        self.secondValueType = secondType
        self.linkSymbol = symbol
        self.textColor = tintColor
        self.tintColor = tintColor
    }

    open override func qjsWidgets() -> [Widget] {
        let widget = LinkTextWidget()
        widget.setLocation(Point(x: x, y: y))
        widget.setSize(Size(width: width, height: height))
        widget.setValueType(valueType)
        widget.setSecondValueType(secondValueType)
        widget.setLinkSymbol(linkSymbol)
        widget.setFontSize(fontSize)
        widget.setColor(textColor)
        widget.setAlignment(.center)
        return [widget]
    }
}
