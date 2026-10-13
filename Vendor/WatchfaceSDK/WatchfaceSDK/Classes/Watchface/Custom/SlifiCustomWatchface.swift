
import UIKit

public typealias WatchfaceCallback = (URL?, QjsError?) ->()

@objc public class SlifiCustomWatchface: NSObject {
    @objc public var name: String = "custom"
    @objc public var width: Int
    @objc public var height: Int
    @objc public var backgroundImage: UIImage?
    @objc public var thumbnailImage: UIImage?
    @objc public var backgroundGif: URL?
    @objc public var widgetList: [QjsWidget] = []
    public var callback: WatchfaceCallback!
    
    private var qjsWf: SifliQjsWatchface?

    @objc public init(width: Int = 0, height: Int = 0) {
        self.width = width
        self.height = height
    }

    @objc public func addWidget(_ widget: QjsWidget) {
        widgetList.append(widget)
    }

    @objc public func removeWidget(_ widget: QjsWidget) {
        if let index = widgetList.firstIndex(where: { $0.id == widget.id }) {
            widgetList.remove(at: index)
        }
    }

    @objc public func removeWidgetById(_ id: Int) {
        if let index = widgetList.firstIndex(where: { $0.id == id }) {
            widgetList.remove(at: index)
        }
    }

    @objc public func removeAllWidgets() {
        widgetList.removeAll()
    }

    func syncToWatch(devIdentifier: String, callback: QjsCallback) {
//        WatchfaceSDK.getInstance().setCustomWatchface(devIdentifier: devIdentifier, watchface: self, callback: callback)
    }

    public func makeZip(callback: @escaping WatchfaceCallback) {
        let watchface = SifliQjsWatchface(name: "Ta")
        watchface.name = getName()
        watchface.width = getWidth()
        watchface.height = getHeight()
        var qjsWidgets: [Widget] = []

        for widget in widgetList {
            qjsWidgets.append(contentsOf: widget.qjsWidgets())
        }
        watchface.widgetList = qjsWidgets

        let aod: SifliQjsWatchface = watchface.copy()
        aod.isAOD = true

        if let backgroundGif = backgroundGif {
            let gifWidget = GifWidget()
            gifWidget.setGifPath("bg_gif.gif")
            gifWidget.setName("BackgroundGif")
            gifWidget.size = Size(width: getWidth(), height: getHeight())
            gifWidget.location = Point(x: 0, y: 0)
            gifWidget.gif = backgroundGif
            if let ff = QjsFileUtils.getFirstFrameBitmapOfGif(gif: backgroundGif) {
                gifWidget.gifPreview = ff
            }
            qjsWidgets.insert(gifWidget, at: 0)
        } else if let backgroundImage = backgroundImage {
            let imageWidget = SingleImageWidget()
            imageWidget.image = backgroundImage
            imageWidget.setImagePath("bg.png")
            imageWidget.setName("Background")
            imageWidget.location = Point(x: 0, y: 0)
            imageWidget.size = Size(width: getWidth(), height: getHeight())
            qjsWidgets.insert(imageWidget, at: 0)
        }
        watchface.thumbnail = thumbnailImage
        watchface.widgetList = qjsWidgets
        watchface.aod = aod
        self.qjsWf = watchface;
        self.qjsWf?.makeZip(callback: {[weak self] url, err in
            callback(url, err)
            self?.qjsWf = nil;
        })
    }

    func getName() -> String {
        return name
    }

    func setName(_ name: String) {
        self.name = name
    }

    func getWidth() -> Int {
        return width
    }

    func setWidth(_ width: Int) {
        self.width = width
    }

    func getHeight() -> Int {
        return height
    }

    func setHeight(_ height: Int) {
        self.height = height
    }

    func getBackgroundImage() -> UIImage? {
        return backgroundImage
    }

    func setBackgroundImage(_ backgroundImage: UIImage?) {
        self.backgroundImage = backgroundImage
    }

    func getThumbnailImage() -> UIImage? {
        return thumbnailImage
    }

    func setThumbnailImage(_ thumbnailImage: UIImage?) {
        self.thumbnailImage = thumbnailImage
    }

    func getBackgroundGif() -> URL? {
        return backgroundGif
    }

    func setBackgroundGif(_ backgroundGif: URL?) {
        self.backgroundGif = backgroundGif
    }

    func getWidgetList() -> [QjsWidget] {
        return widgetList
    }

    func setWidgetList(_ widgetList: [QjsWidget]) {
        self.widgetList = widgetList
    }
}
