
import UIKit

@objc public class QjsWeekWidget: QjsWidget {
    private var images: [String: String] = [:]

    public override init() {
        super.init()
        initWidget()
    }

    @objc public init(tintColor: UIColor) {
        super.init()
        self.tintColor = tintColor
        initWidget()
    }

    private func initWidget() {
        setName("Week")
        images["00"] = "week_00.png"
        images["01"] = "week_01.png"
        images["02"] = "week_02.png"
        images["03"] = "week_03.png"
        images["04"] = "week_04.png"
        images["05"] = "week_05.png"
        images["06"] = "week_06.png"

        width = 114
        height = 40
    }

    open override func qjsWidgets() -> [Widget] {
        var bitmapMap: [String: UIImage] = [:]
        let assetManager = Bundle.main
        
        
        for (key, imgName) in images {
            
            guard let bitmap = UIImage.loadImage(named: imgName) else {
                continue
            }
            if let color = getTintColor() {
                bitmapMap[key] = QjsFileUtils.changeBitmapColor(originalBitmap: bitmap, color: color)
            } else {
                bitmapMap[key] = bitmap
            }
           
        }

        var widgetList: [Widget] = []

        let dateWidget = OptionWidget()
        dateWidget.setValueType(QjsValueType.weekData.rawValue)
        dateWidget.setLocation(getLocation())
        dateWidget.setSize(getSize())
        dateWidget.setImages(bitmapMap)
        widgetList.append(dateWidget)

        return widgetList
    }

}

