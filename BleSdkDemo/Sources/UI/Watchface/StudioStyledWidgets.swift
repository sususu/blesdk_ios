import UIKit
import WatchfaceSDK

/// Studio-only QJS widgets that paint TTF glyphs (Android `QjsFontDigitBitmaps` path).

final class StudioDateWidget: QjsWidget {
    var glyphFont: UIFont
    var fontSizePx: Int

    init(tintColor: UIColor, font: UIFont, fontSizePx: Int) {
        self.glyphFont = font
        self.fontSizePx = fontSizePx
        super.init()
        self.tintColor = tintColor
        self.name = "StudioDate"
        let (_, h) = QjsFontGlyphRenderer.dateCell(fontSizePx: fontSizePx)
        self.width = QjsFontGlyphRenderer.dateWidgetWidth(fontSizePx: fontSizePx)
        self.height = h
        self.valueType = QjsValueType.dateNum.rawValue
    }

    override func qjsWidgets() -> [Widget] {
        let tint = tintColor ?? .white
        let images = QjsFontGlyphRenderer.renderDateDigits(font: glyphFont, tint: tint, fontSizePx: fontSizePx)
        guard !images.isEmpty else { return [] }
        let g = GroupWidget()
        g.setValueType(QjsValueType.dateNum.rawValue)
        g.setLocation(Point(x: x, y: y))
        g.setSize(Size(width: width, height: height))
        g.setImages(images)
        return [g]
    }
}

final class StudioWeekWidget: QjsWidget {
    var glyphFont: UIFont
    var fontSizePx: Int

    init(tintColor: UIColor, font: UIFont, fontSizePx: Int) {
        self.glyphFont = font
        self.fontSizePx = fontSizePx
        super.init()
        self.tintColor = tintColor
        self.name = "StudioWeek"
        let (w, h) = QjsFontGlyphRenderer.weekCell(fontSizePx: fontSizePx)
        self.width = w
        self.height = h
        self.valueType = QjsValueType.weekData.rawValue
    }

    override func qjsWidgets() -> [Widget] {
        let tint = tintColor ?? .white
        let images = QjsFontGlyphRenderer.renderWeekLabels(font: glyphFont, tint: tint, fontSizePx: fontSizePx)
        guard !images.isEmpty else { return [] }
        let opt = OptionWidget()
        opt.setValueType(QjsValueType.weekData.rawValue)
        opt.setLocation(Point(x: x, y: y))
        opt.setSize(Size(width: width, height: height))
        opt.setImages(images)
        return [opt]
    }
}

final class StudioIconDataWidget: QjsWidget {
    enum Kind {
        case step, distance, calorie, battery, heartrate
        var icon: String {
            switch self {
            case .step: return "icon_steps.png"
            case .distance: return "icon_distance.png"
            case .calorie: return "icon_kcal.png"
            case .battery: return "icon_battery.png"
            case .heartrate: return "icon_heart.png"
            }
        }
        var valueType: Int {
            switch self {
            case .step: return QjsValueType.stepsNum.rawValue
            case .distance: return QjsValueType.distanceNum.rawValue
            case .calorie: return QjsValueType.calorieNum.rawValue
            case .battery: return QjsValueType.batteryNum.rawValue
            case .heartrate: return QjsValueType.heartrateNum.rawValue
            }
        }
        var digitSlots: Int {
            switch self {
            case .step: return 5
            case .calorie: return 4
            case .distance, .battery, .heartrate: return 3
            }
        }
    }

    let kind: Kind
    var glyphFont: UIFont
    var fontSizePx: Int

    init(kind: Kind, tintColor: UIColor, font: UIFont, fontSizePx: Int) {
        self.kind = kind
        self.glyphFont = font
        self.fontSizePx = fontSizePx
        super.init()
        self.tintColor = tintColor
        self.name = "Studio\(kind)"
        self.valueType = kind.valueType
        let (digitW, digitH) = QjsFontGlyphRenderer.dataCell(fontSizePx: fontSizePx)
        let ratio = CGFloat(fontSizePx) / CGFloat(QjsFontGlyphRenderer.dataDigitH)
        let iconBox = max(20, Int((40 * min(max(ratio, 0.5), 3)).rounded()))
        self.width = digitW * kind.digitSlots + iconBox
        self.height = digitH
    }

    override func qjsWidgets() -> [Widget] {
        let tint = tintColor ?? .white
        let digits = QjsFontGlyphRenderer.renderDataDigits(font: glyphFont, tint: tint, fontSizePx: fontSizePx)
        guard !digits.isEmpty else { return [] }
        guard var icon = UIImage.loadImage(named: kind.icon) else { return [] }
        if let tinted = QjsFileUtils.changeBitmapColor(originalBitmap: icon, color: tint) {
            icon = tinted
        }
        let ratio = CGFloat(fontSizePx) / CGFloat(QjsFontGlyphRenderer.dataDigitH)
        let iconBox = max(20, Int((40 * min(max(ratio, 0.5), 3)).rounded()))
        let iconSize = CGSize(width: iconBox, height: iconBox)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let scaledIcon = UIGraphicsImageRenderer(size: iconSize, format: format).image { _ in
            icon.draw(in: CGRect(origin: .zero, size: iconSize))
        }

        let iconWidget = SingleImageWidget()
        iconWidget.setImage(scaledIcon)
        iconWidget.setSize(Size(width: iconBox, height: iconBox))
        let dataH = digits.values.first.map { Int($0.size.height) } ?? height
        let iconOffset = (iconBox - dataH) / 2
        iconWidget.setLocation(Point(x: x, y: y - iconOffset))

        let data = GroupWidget()
        data.setValueType(kind.valueType)
        data.setAlignment(.center)
        data.setImages(digits)
        data.setLocation(Point(x: x + iconBox, y: y))
        data.setSize(Size(width: max(0, width - iconBox), height: height))
        return [iconWidget, data]
    }
}
