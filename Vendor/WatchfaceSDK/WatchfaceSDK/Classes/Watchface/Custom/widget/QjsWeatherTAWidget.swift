
import UIKit

@objc public class QjsWeatherTAWidget: QjsIconDataWidget {
    
    private var weatherImages: [String] = []
    
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
        
        weatherImages.append("icon_wer_01.png")
        weatherImages.append("icon_wer_02.png")
        weatherImages.append("icon_wer_03.png")
        weatherImages.append("icon_wer_04.png")
        weatherImages.append("icon_wer_05.png")
        weatherImages.append("icon_wer_06.png")
        weatherImages.append("icon_wer_07.png")
        weatherImages.append("icon_wer_08.png")
        weatherImages.append("icon_wer_09.png")
        weatherImages.append("icon_wer_10.png")
        weatherImages.append("icon_wer_11.png")
        weatherImages.append("icon_wer_12.png")
        weatherImages.append("icon_wer_13.png")
        weatherImages.append("icon_wer_14.png")
        weatherImages.append("icon_wer_15.png")
        
        setIconAlign(.Left)
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
    
    open override func qjsWidgets() -> [Widget] {
        var bitmapMap: [Int: UIImage] = [:]
        var weatherBitmapMap: [String: UIImage] = [:]
        let width = 40
        
        var dataImgHeight: Int = 0
        for (key, imgName) in images {
            
            guard let bitmap = UIImage.loadImage(named: imgName) else {
                continue
            }
            dataImgHeight = Int(bitmap.size.height)
            if let color = getTintColor() {
                bitmapMap[key] = QjsFileUtils.changeBitmapColor(originalBitmap: bitmap, color: color)
            } else {
                bitmapMap[key] = bitmap
            }
        }
        
        for (i, imgName) in weatherImages.enumerated() {
            guard let bitmap = UIImage.loadImage(named: imgName) else {
                continue
            }
            let key = String.init(format: "%02d", i)
            weatherBitmapMap[key] = bitmap
        }
        
        if bitmapMap.count != images.count {
            return []
        }
        
        if weatherBitmapMap.count != weatherImages.count {
            return []
        }
        
        iconOffset = Int((width - dataImgHeight) / 2)
        

        var widgetList: [Widget] = []

        let optionWidget = OptionWidget()
        optionWidget.setMaxCount(weatherBitmapMap.count)
        optionWidget.setValueType(333)
        optionWidget.setImages(weatherBitmapMap)

        let dataGroupWidget = GroupWidget()
        dataGroupWidget.setValueType(getValueType())
        dataGroupWidget.setAlignment(.center)
        dataGroupWidget.setImages(bitmapMap)
        
        switch iconAlign {
            case .Left: do {
                optionWidget.setLocation(Point(x: getLocation().x, y: getLocation().y - iconOffset))
                optionWidget.setSize(Size(width: width, height: width))

                let newX = getLocation().x + optionWidget.getSize().width
                let newY = getLocation().y
                var newWidth = getSize().width - optionWidget.getSize().width
                if newWidth < 0 { newWidth = 0 }
                let newHeight = getSize().height
                
                dataGroupWidget.setLocation(Point(x: newX, y: newY))
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                break
            }
            case .Right: do {
                optionWidget.setSize(Size(width: width, height: width))
                optionWidget.setLocation(Point(x: getLocation().x + getSize().width - optionWidget.getSize().width, y: getLocation().y - iconOffset))
                
                var newWidth = getSize().width - optionWidget.getSize().width
                if newWidth < 0 { newWidth = 0 }
                let newHeight = getSize().height
                
                dataGroupWidget.setLocation(getLocation())
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                break
            }
            case .Bottom: do {
                dataGroupWidget.setLocation(getLocation())
                var newHeight = 0
                optionWidget.setSize(Size(width: width, height: width))
                newHeight = getSize().height - optionWidget.getSize().height
                let newWidth = getSize().width
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                let newX = getLocation().x + (getSize().width - optionWidget.getSize().width) / 2
                let newY = getLocation().y + getSize().height - optionWidget.getSize().height
                optionWidget.setLocation(Point(x: newX, y: newY))
            }
            case .Top: do {
                
                var newHeight = 0
                var newY = getLocation().y
                optionWidget.setSize(Size(width: width, height: width))
                newHeight = getSize().height - optionWidget.getSize().height
                newY += optionWidget.getSize().height
                
                let newX = getLocation().x + (getSize().width - optionWidget.getSize().width) / 2
                
                optionWidget.setLocation(Point(x: newX, y: getLocation().y))
                    
                var newWidth = getSize().width
                if newWidth < 0 {
                    newWidth = 0
                }
                dataGroupWidget.setLocation(Point(x: getLocation().x, y: newY))
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                break
            }
        }
        widgetList.append(optionWidget)
        widgetList.append(dataGroupWidget)
        return widgetList
    }
}

