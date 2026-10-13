
import UIKit

@objc public class QjsMinutePointerWidget: QjsPointerWidget {
    private var imageName: String = "pointer_min.png"

    public override init(watchfaceSize: Size) {
        super.init(watchfaceSize: watchfaceSize)
        self.initMinutePointer()
    }

    public init(_ watchfaceSize: Size, tintColor: UIColor) {
        super.init(watchfaceSize: watchfaceSize)
        self.tintColor = tintColor
        self.initMinutePointer()
    }

    private func initMinutePointer() {
        setName("MinutePointer")
        self.width = 14
        self.height = 194
        self.x = 226
        self.y = 39
        self.rotationCenter = Point(x: 7, y: 194)
    }

    open override func qjsWidgets() -> [Widget] {
        
        guard let bitmap = UIImage.loadImage(named: self.imageName) else {
            return []
        }
        if let color = getTintColor() {
            self.image = QjsFileUtils.changeBitmapColor(originalBitmap: bitmap, color: color)
        } else {
            self.image = bitmap
        }

        var widgetList: [Widget] = []

        let pointerWidget = PointerWidget()
        pointerWidget.setValueType(QjsValueType.minutePointer.rawValue)
        pointerWidget.setCenterPoint(getCenter())
        pointerWidget.setRotationCenterPoint(getRotationCenter())
        pointerWidget.setImage(image!)
        widgetList.append(pointerWidget)

        return widgetList
    }
}
