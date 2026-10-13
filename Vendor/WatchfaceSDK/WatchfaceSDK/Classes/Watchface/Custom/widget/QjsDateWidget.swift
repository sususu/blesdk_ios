
import UIKit

@objc public class QjsDateWidget: QjsWidget {
    var images: [Int: String] = [:]

    public override init() {
        super.init()
        initDate()
    }

    @objc public init(tintColor: UIColor) {
        super.init()
        self.tintColor = tintColor
        initDate()
    }

    private func initDate() {
        images[0x30] = "date_num_30.png"
        images[0x31] = "date_num_31.png"
        images[0x32] = "date_num_32.png"
        images[0x33] = "date_num_33.png"
        images[0x34] = "date_num_34.png"
        images[0x35] = "date_num_35.png"
        images[0x36] = "date_num_36.png"
        images[0x37] = "date_num_37.png"
        images[0x38] = "date_num_38.png"
        images[0x39] = "date_num_39.png"
        width = 56
        height = 40
        name = "Date"
    }

    open override func qjsWidgets() -> [Widget] {
        var bitmapMap: [Int: UIImage] = [:]

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

        var widgetList: [Widget] = []

        let dateGroupWidget = GroupWidget()
        dateGroupWidget.setValueType(QjsValueType.dateNum.rawValue)
        dateGroupWidget.setLocation(getLocation())
        dateGroupWidget.setSize(getSize())
        dateGroupWidget.setImages(bitmapMap)
        widgetList.append(dateGroupWidget)

        return widgetList
    }
}
