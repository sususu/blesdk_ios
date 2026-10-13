
import UIKit

@objc public class QjsHeartrateWidget: QjsIconDataWidget {
    public override init() {
        super.init()
        initHeartrate()
    }

    @objc public override init(tintColor: UIColor) {
        super.init(tintColor: tintColor)
        setName("Heartrate")
        initHeartrate()
    }

    private func initHeartrate() {
        // max value is 255
        width = 20 * 3
        setIcon("icon_heart.png")
        setValueType(QjsValueType.heartrateNum.rawValue)
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
