import UIKit

/// Hot-zone shortcut that opens a watch app / complication (firmware launcher type).
///
/// Maps to low-level `AppLinkWidget` (`launcher.js`). Pass a firmware complication id
/// via `launcherType` (see demo `StudioLauncherType`: phone / notifications / activity / weather).
@objc public class QjsAppLinkWidget: QjsWidget {

    @objc public init(x: Int, y: Int, width: Int, height: Int, launcherType: Int) {
        super.init()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.valueType = launcherType
        self.name = "AppLink"
    }

    @objc public convenience init(launcherType: Int) {
        self.init(x: 0, y: 0, width: 72, height: 72, launcherType: launcherType)
    }

    open override func qjsWidgets() -> [Widget] {
        let widget = AppLinkWidget()
        widget.setLocation(Point(x: x, y: y))
        widget.setSize(Size(width: width, height: height))
        widget.setValueType(valueType)
        return [widget]
    }
}
