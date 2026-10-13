import UIKit

/// Frame-sequence animation (low-level `SequenceImageWidget` / `seqframe.js`).
@objc public class QjsSequenceImageWidget: QjsWidget {
    @objc public var frames: [UIImage] = []
    @objc public var loop: Bool = true
    @objc public var intervalMs: Int = 80
    @objc public var startDelayMs: Int = 0

    @objc public override init() {
        super.init()
        self.name = "SequenceImage"
        self.width = 40
        self.height = 40
    }

    @objc public convenience init(frames: [UIImage], tintColor: UIColor? = nil) {
        self.init()
        if let tintColor {
            self.tintColor = tintColor
            self.frames = frames.compactMap { img in
                if let tinted = QjsFileUtils.changeBitmapColor(originalBitmap: img, color: tintColor) {
                    return tinted
                }
                return img
            }
        } else {
            self.frames = frames
        }
        if let first = frames.first {
            self.width = Int(first.size.width)
            self.height = Int(first.size.height)
        }
    }

    open override func qjsWidgets() -> [Widget] {
        guard !frames.isEmpty else { return [] }
        let widget = SequenceImageWidget()
        widget.setLocation(Point(x: x, y: y))
        widget.setSize(Size(width: width, height: height))
        widget.setImages(frames)
        widget.setResMode(loop ? "loop" : "once")
        widget.setResInterval(intervalMs)
        widget.setStartDelay(startDelayMs)
        return [widget]
    }
}
