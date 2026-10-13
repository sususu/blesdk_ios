
import UIKit

@objc public extension UIImage {
    @objc func imageByTintColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        color.setFill()
        UIRectFill(rect)
        self.draw(at: CGPoint.zero, blendMode: .destinationIn, alpha: 1)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    @objc func resize(_ size: CGSize, cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let bounds = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).addClip()
        self.draw(in: bounds)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    @objc static func imageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        guard size.width > 0 && size.height > 0 else { return nil }
        
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc static func loadImage(named imgName: String) -> UIImage? {
        // 获取 WatchfaceSDK.framework 的路径
        if let frameworkPath = Bundle.main.path(forResource: "Frameworks/WatchfaceSDK", ofType: "framework"),
           let frameworkBundle = Bundle(path: frameworkPath) {
            
            // 获取图片路径
            let imagePath = (frameworkPath as NSString).appendingPathComponent("\(imgName).png")
            
            // 加载图片并返回
            if let image = UIImage(contentsOfFile: imagePath) {
                return image
            } else {
                print("图片路径获取失败")
                return nil
            }
        } else {
            print("Framework 加载失败")
            return nil
        }
    }

}
