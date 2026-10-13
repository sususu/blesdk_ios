
import UIKit

@objc public class QjsTimeWidget: QjsWidget {
    private var images: [Int: String] = [:]
    private var colonImageName: String = "time_b_25.png"
    private var hourNumbersSize: Size
    private var minuteNumberSize: Size
    private var colonSize: Size

    override init(id: Int = 0, width: Int = 0, height: Int = 0, x: Int = 0, y: Int = 0, valueType: Int = 0, name: String = "") {
        self.hourNumbersSize = Size(width: 124, height: 96)
        self.minuteNumberSize = Size(width: 124, height: 96)
        self.colonSize = Size(width: 40, height: 96)
        super.init(id: id, width: width, height: height, x: x, y: y, valueType: valueType, name: name)
        initTime()
    }

    @objc public init(tintColor: UIColor) {
        self.hourNumbersSize = Size(width: 124, height: 96)
        self.minuteNumberSize = Size(width: 124, height: 96)
        self.colonSize = Size(width: 40, height: 96)
        super.init(id: 0, width: 0, height: 0, x: 0, y: 0, valueType: 0, name: "")
        self.tintColor = tintColor
        initTime()
    }

    private func initTime() {
        setName("Time")
        images[0x30] = "time_b_30.png"
        images[0x31] = "time_b_31.png"
        images[0x32] = "time_b_32.png"
        images[0x33] = "time_b_33.png"
        images[0x34] = "time_b_34.png"
        images[0x35] = "time_b_35.png"
        images[0x36] = "time_b_36.png"
        images[0x37] = "time_b_37.png"
        images[0x38] = "time_b_38.png"
        images[0x39] = "time_b_39.png"

        width = Int(hourNumbersSize.width + minuteNumberSize.width + colonSize.width)
        height = 96
        
        name = "Time"
    }

    open override func qjsWidgets() -> [Widget] {
        var bitmapMap: [Int: UIImage] = [:]
        var colonImg: UIImage!
        
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
        
        if bitmapMap.count != images.count {
            return []
        }
                
        if let img = UIImage.loadImage(named: colonImageName) {
            if let color = getTintColor() {
                colonImg = QjsFileUtils.changeBitmapColor(originalBitmap: img, color: color)
            } else {
                colonImg = img
            }
        } else {
            return []
        }

        var widgetList: [Widget] = []

        let hourGroupWidget = GroupWidget()
        hourGroupWidget.setValueType(QjsValueType.hourNum.rawValue)
        hourGroupWidget.setLocation(getLocation())
        hourGroupWidget.setAlignment(.center)
        hourGroupWidget.setSize(hourNumbersSize)
        hourGroupWidget.setImages(bitmapMap)
        widgetList.append(hourGroupWidget)

        let colonLocation = Point(x: getX() + Int(hourNumbersSize.width), y: getY())
        let minuteLocation = Point(x: Int(colonLocation.x) + Int(colonSize.width), y: getY())

        if let colonImg = colonImg {
            let colonWidget = SingleImageWidget()
            colonWidget.setLocation(colonLocation)
            colonWidget.setSize(colonSize)
            colonWidget.setImage(colonImg)
            widgetList.append(colonWidget)
        }

        let minuteGroupWidget = GroupWidget()
        minuteGroupWidget.setValueType(QjsValueType.minuteNum.rawValue)
        minuteGroupWidget.setLocation(minuteLocation)
        minuteGroupWidget.setAlignment(.center)
        minuteGroupWidget.setSize(minuteNumberSize)
        minuteGroupWidget.setImages(bitmapMap)
        widgetList.append(minuteGroupWidget)

        return widgetList
    }
}
