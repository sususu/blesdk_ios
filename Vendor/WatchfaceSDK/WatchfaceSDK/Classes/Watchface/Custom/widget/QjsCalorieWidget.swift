
import UIKit

@objc public class QjsCalorieWidget: QjsIconDataWidget {
    public override init() {
        super.init()
        initCalorie()
    }

    @objc public override init(tintColor: UIColor) {
        super.init(tintColor: tintColor)
        initCalorie()
    }

    private func initCalorie() {
        setName("Calorie")
        // max value is 9999
        width = 20 * 4
        setIcon("icon_kcal.png")
        setValueType(QjsValueType.calorieNum.rawValue)
    }
    
    public override func setIconAlign(_ align: QjsAlignment) {
        super.setIconAlign(align)
        if align == .Left || align == .Right {
            width = 20 * 4 + 40
            height = 26
        } else {
            width = 20 * 4
            height = 26 + 40
        }
    }
}
