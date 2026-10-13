
import UIKit

@objc public class QjsHourPointerWidget: QjsPointerWidget {
    private var imageName: String = "pointer_hour.png"

    public override init(watchfaceSize: Size) {
        super.init(watchfaceSize: watchfaceSize)
        initHourPointer()
    }

    public init(_ watchfaceSize: Size, tintColor: UIColor) {
        super.init(watchfaceSize: watchfaceSize)
        self.tintColor = tintColor
        initHourPointer()
    }

    private func initHourPointer() {
        setName("HourPointer")
        self.width = 14
        self.height = 114
        self.x = 226
        self.y = 119
        self.rotationCenter = Point(x: 7, y: 114)
    }

    open override func qjsWidgets() -> [Widget] {
        
        guard let bitmap = UIImage.loadImage(named: self.imageName) else {
            return []
        }
        // Change color
        if let color = getTintColor() {
            self.image = QjsFileUtils.changeBitmapColor(originalBitmap: bitmap, color: color)
        } else {
            self.image = bitmap
        }

        var widgetList: [Widget] = []

        let pointerWidget = PointerWidget()
        pointerWidget.setValueType(QjsValueType.hourPointer.rawValue)
        pointerWidget.setCenterPoint(getCenter())
        pointerWidget.setRotationCenterPoint(getRotationCenter())
        pointerWidget.setImage(image!)
        widgetList.append(pointerWidget)

        return widgetList
    }
}
