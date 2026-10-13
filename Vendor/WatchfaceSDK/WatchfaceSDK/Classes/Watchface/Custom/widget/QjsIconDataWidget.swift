import UIKit

@objc public enum QjsAlignment: Int {
    case Top
    case Right
    case Bottom
    case Left
}

public class QjsIconDataWidget: QjsWidget {
    var icon: String?
    var images: [Int: String] = [:]
    var iconOffset: Int = 0
    var iconAlign: QjsAlignment = .Top

    public override init() {
        super.init()
    }
    
    @objc public init(tintColor: UIColor) {
        super.init()
        // 20 x 26
        images[0x2d] = "data_num_2d.png"
        images[0x2e] = "data_num_2e.png"
        images[0x25] = "data_num_25.png"
        images[0x30] = "data_num_30.png"
        images[0x31] = "data_num_31.png"
        images[0x32] = "data_num_32.png"
        images[0x33] = "data_num_33.png"
        images[0x34] = "data_num_34.png"
        images[0x35] = "data_num_35.png"
        images[0x36] = "data_num_36.png"
        images[0x37] = "data_num_37.png"
        images[0x38] = "data_num_38.png"
        images[0x39] = "data_num_39.png"
        self.tintColor = tintColor
        height = 26
    }

    open override func qjsWidgets() -> [Widget] {
        var bitmapMap: [Int: UIImage] = [:]
        var iconBitmap: UIImage!
        
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
        
        if bitmapMap.count != images.count {
            return []
        }
        
        guard let iconImg = UIImage.loadImage(named: icon!) else {
            return []
        }
        if let color = getTintColor() {
            iconBitmap = QjsFileUtils.changeBitmapColor(originalBitmap: iconImg, color: color)
        } else {
            iconBitmap = iconImg
        }
        
        iconOffset = Int((Int(iconBitmap.size.height) - dataImgHeight) / 2)
        

        var widgetList: [Widget] = []

        let imageWidget = SingleImageWidget()
        imageWidget.setImage(iconBitmap!)

        let dataGroupWidget = GroupWidget()
        dataGroupWidget.setValueType(getValueType())
        dataGroupWidget.setAlignment(.center)
        dataGroupWidget.setImages(bitmapMap)
        
        switch iconAlign {
            case .Left: do {
                imageWidget.setLocation(Point(x: getLocation().x, y: getLocation().y - iconOffset))
                if let iconBitmap = iconBitmap {
                    imageWidget.setSize(Size(width: Int(iconBitmap.size.width), height: Int(iconBitmap.size.height)))
                }
                let newX = getLocation().x + imageWidget.getSize().width
                let newY = getLocation().y
                var newWidth = getSize().width - imageWidget.getSize().width
                if newWidth < 0 { newWidth = 0 }
                let newHeight = getSize().height
                
                dataGroupWidget.setLocation(Point(x: newX, y: newY))
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                break
            }
            case .Right: do {
                if let iconBitmap = iconBitmap {
                    imageWidget.setSize(Size(width: Int(iconBitmap.size.width), height: Int(iconBitmap.size.height)))
                }
                imageWidget.setLocation(Point(x: getLocation().x + getSize().width - imageWidget.getSize().width, y: getLocation().y - iconOffset))
                
                var newWidth = getSize().width - imageWidget.getSize().width
                if newWidth < 0 { newWidth = 0 }
                let newHeight = getSize().height
                
                dataGroupWidget.setLocation(getLocation())
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                break
            }
            case .Bottom: do {
                dataGroupWidget.setLocation(getLocation())
                var newHeight = 0
                if let iconBitmap = iconBitmap {
                    imageWidget.setSize(Size(width: Int(iconBitmap.size.width), height: Int(iconBitmap.size.height)))
                    newHeight = getSize().height - imageWidget.getSize().height
                } else {
                    newHeight = getSize().height
                }
                let newWidth = getSize().width
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                let newX = getLocation().x + (getSize().width - imageWidget.getSize().width) / 2
                let newY = getLocation().y + getSize().height - imageWidget.getSize().height
                imageWidget.setLocation(Point(x: newX, y: newY))
            }
            case .Top: do {
                
                var newHeight = 0
                var newY = getLocation().y
                if let iconBitmap = iconBitmap {
                    imageWidget.setSize(Size(width: Int(iconBitmap.size.width), height: Int(iconBitmap.size.height)))
                    newHeight = getSize().height - imageWidget.getSize().height
                    newY += imageWidget.getSize().height
                } else {
                    newHeight = getSize().height
                }
                
                let newX = getLocation().x + (getSize().width - imageWidget.getSize().width) / 2
                
                imageWidget.setLocation(Point(x: newX, y: getLocation().y))
                    
                var newWidth = getSize().width
                if newWidth < 0 {
                    newWidth = 0
                }
                dataGroupWidget.setLocation(Point(x: getLocation().x, y: newY))
                dataGroupWidget.setSize(Size(width: newWidth, height: newHeight))
                
                break
            }
        }
        widgetList.append(imageWidget)
        widgetList.append(dataGroupWidget)
        return widgetList
    }

    func getIcon() -> String? {
        return icon
    }

    func setIcon(_ icon: String) {
        self.icon = icon
    }

    func getImages() -> [Int: String] {
        return images
    }
                                        
    public func setIconAlign(_ align: QjsAlignment) {
        self.iconAlign = align
    }
}
