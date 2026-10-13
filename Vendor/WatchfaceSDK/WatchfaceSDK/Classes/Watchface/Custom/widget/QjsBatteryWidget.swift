
import UIKit

@objc public class QjsBatteryWidget: QjsIconDataWidget {
    public override init() {
        super.init()
        initBattery()
    }

    @objc public override init(tintColor: UIColor) {
        super.init(tintColor: tintColor)
        initBattery()
    }

    private func initBattery() {
        setName("Battery")
        // max value is 100
        width = 20 * 3
        setIcon("icon_battery.png")
        setValueType(QjsValueType.batteryNum.rawValue)
    }
    
    public override func setIconAlign(_ align: QjsAlignment) {
        super.setIconAlign(align)
        if align == .Left || align == .Right {
            width = 20 * 3 + 40
            height = 26
        } else {
            width = 20 * 3
            height = 26 + 40
        }
    }
}
