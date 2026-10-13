
import UIKit

@objc public class QjsWeatherWidget: QjsIconDataWidget {
    public override init() {
        super.init()
        initWeather()
    }

    @objc public override init(tintColor: UIColor) {
        super.init(tintColor: tintColor)
        initWeather()
    }

    private func initWeather() {
        setName("Weather")
        // max value is 999
        width = 20 * 3
        setIcon("icon_weather.png")
        setValueType(QjsValueType.temperatureNum.rawValue)
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

