import UIKit

/// Renders TTF / system glyphs into QJS `GroupWidget` / `OptionWidget` image atlases.
///
/// Mirrors Android demo `QjsFontDigitBitmaps`: QJS digit widgets take only
/// `[code: UIImage]` maps, so Studio changes size/color by painting cells.
@objc public final class QjsFontGlyphRenderer: NSObject {
    public static let dataDigitW = 20
    public static let dataDigitH = 26
    public static let dataDotW = 8
    public static let dateDigitW = 28
    public static let dateDigitH = 40
    public static let weekW = 114
    public static let weekH = 40

    private static let weekLabels = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    public static func dataCell(fontSizePx: Int) -> (Int, Int) {
        let h = max(8, min(120, fontSizePx))
        let w = max(4, Int((CGFloat(h) * CGFloat(dataDigitW) / CGFloat(dataDigitH)).rounded()))
        return (w, h)
    }

    public static func dateCell(fontSizePx: Int) -> (Int, Int) {
        let h = max(8, min(120, fontSizePx))
        let w = max(6, Int((CGFloat(h) * CGFloat(dateDigitW) / CGFloat(dateDigitH)).rounded()))
        return (w, h)
    }

    public static func weekCell(fontSizePx: Int) -> (Int, Int) {
        let h = max(10, min(120, fontSizePx))
        let w = max(24, Int((CGFloat(h) * CGFloat(weekW) / CGFloat(weekH)).rounded()))
        return (w, h)
    }

    public static func dateWidgetWidth(fontSizePx: Int) -> Int {
        let (digitW, digitH) = dateCell(fontSizePx: fontSizePx)
        let sepW = max(6, Int((CGFloat(digitH) * 20 / CGFloat(dateDigitH)).rounded()))
        return digitW * 4 + sepW
    }

    public static func renderDataDigits(font: UIFont, tint: UIColor, fontSizePx: Int = dataDigitH) -> [Int: UIImage] {
        let (digitW, digitH) = dataCell(fontSizePx: fontSizePx)
        let dotW = max(3, Int((CGFloat(digitH) * CGFloat(dataDotW) / CGFloat(dataDigitH)).rounded()))
        var map: [Int: UIImage] = [:]
        for code in 0x30...0x39 {
            let s = String(UnicodeScalar(code)!)
            if let img = renderGlyph(font: font, text: s, tint: tint, cellW: digitW, cellH: digitH) {
                map[code] = img
            }
        }
        map[0x2d] = renderGlyph(font: font, text: "-", tint: tint, cellW: digitW, cellH: digitH)
        map[0x2e] = renderGlyph(font: font, text: ".", tint: tint, cellW: dotW, cellH: digitH)
        map[0x25] = renderGlyph(font: font, text: "%", tint: tint, cellW: digitW, cellH: digitH)
        return map.compactMapValues { $0 }
    }

    public static func renderDateDigits(font: UIFont, tint: UIColor, fontSizePx: Int = dateDigitH) -> [Int: UIImage] {
        let (digitW, digitH) = dateCell(fontSizePx: fontSizePx)
        let sepW = max(6, Int((CGFloat(digitH) * 20 / CGFloat(dateDigitH)).rounded()))
        var map: [Int: UIImage] = [:]
        for code in 0x30...0x39 {
            let s = String(UnicodeScalar(code)!)
            if let img = renderGlyph(font: font, text: s, tint: tint, cellW: digitW, cellH: digitH) {
                map[code] = img
            }
        }
        map[0x2f] = renderGlyph(font: font, text: "/", tint: tint, cellW: sepW, cellH: digitH)
        return map.compactMapValues { $0 }
    }

    public static func renderWeekLabels(font: UIFont, tint: UIColor, fontSizePx: Int = weekH) -> [String: UIImage] {
        let (w, h) = weekCell(fontSizePx: fontSizePx)
        var map: [String: UIImage] = [:]
        for (i, label) in weekLabels.enumerated() {
            let key = String(format: "%02d", i)
            if let img = renderGlyph(font: font, text: label, tint: tint, cellW: w, cellH: h, fitWidth: true) {
                map[key] = img
            }
        }
        return map
    }

    public static func renderGlyph(
        font: UIFont,
        text: String,
        tint: UIColor,
        cellW: Int,
        cellH: Int,
        fitWidth: Bool = false
    ) -> UIImage? {
        guard cellW > 0, cellH > 0 else { return nil }
        var pointSize = CGFloat(cellH) * 0.82
        var working = font.withSize(pointSize)
        let maxW = CGFloat(cellW) * (fitWidth ? 0.92 : 0.95)
        for _ in 0..<24 {
            let attrs: [NSAttributedString.Key: Any] = [.font: working, .foregroundColor: tint]
            let size = (text as NSString).size(withAttributes: attrs)
            if size.width <= maxW || pointSize <= 6 { break }
            pointSize *= fitWidth ? 0.92 : 0.9
            working = font.withSize(pointSize)
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cellW, height: cellH), format: format)
        return renderer.image { _ in
            let attrs: [NSAttributedString.Key: Any] = [.font: working, .foregroundColor: tint]
            let size = (text as NSString).size(withAttributes: attrs)
            let origin = CGPoint(
                x: (CGFloat(cellW) - size.width) / 2,
                y: (CGFloat(cellH) - size.height) / 2
            )
            (text as NSString).draw(at: origin, withAttributes: attrs)
        }
    }
}
