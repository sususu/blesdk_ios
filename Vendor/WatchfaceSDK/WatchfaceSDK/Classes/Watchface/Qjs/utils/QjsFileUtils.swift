
import UIKit
import ImageIO
import Zip
import eZIPSDK
import SSZipArchive

@objc public class QjsFileUtils : NSObject {
    static let TAG = "FileUtils"

    /**
     * 获取qjs表盘本地存储目录（iOS可以使用cache或者document目录
     *
     * @param context android上下文，iOS没有
     * @return 目录
     */
    private static func getCacheDir() -> URL? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        if let cacheDir = cacheDir {
            do {
                try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
                print("Directory path: \(cacheDir.path)")
            } catch {
                print("Failed to create directory: \(error.localizedDescription)")
            }
        } else {
            print("Failed to create directory")
        }
        return cacheDir
    }

    /**
     * 用来打包zip包的目录
     *
     * @param watchfaceName 表盘名称
     * @return 目录
     */
    static func qjsToZipFolder(watchfaceName: String) -> URL {
        let dir = getCacheDir()!
        return dir.appendingPathComponent("qjs_temp/dyn")
    }

    static func qjsOutputPath(watchfaceName: String) -> URL {
        let dir = getCacheDir()!
        let tempDir = dir.appendingPathComponent("qjs_temp/output")
        if !FileManager.default.fileExists(atPath: tempDir.path) {
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("qjs_temp/output/JW_\(watchfaceName).zip")
    }
    
    static func dynPath() -> String {
        return "qjs_temp/dyn/dynamic_app";
    }

    static func jwPath(watchfaceName: String) -> String {
        return "qjs_temp/dyn/dynamic_app/qjs_wf/JW_\(watchfaceName)"
    }

    static func aodPath(watchfaceName: String) -> String {
        return "qjs_temp/dyn/dynamic_app/qjs_aod/AOD_\(watchfaceName)"
    }

    static func jwAbsolutePathD(watchfaceName: String) -> URL {
        let jwTmpDir = "qjs_temp/dyn/dynamic_app/qjs_wf/JW_\(watchfaceName)"
        let cacheDir = getCacheDir()!
        return cacheDir.appendingPathComponent(jwTmpDir)
    }

    static func aodAbsolutePath(watchfaceName: String) -> URL {
        let aodTmpDir = "qjs_temp/dyn/dynamic_app/qjs_aod/AOD_\(watchfaceName)"
        let cacheDir = getCacheDir()!
        return cacheDir.appendingPathComponent(aodTmpDir)
    }

    static func cleanUpHistory() {
        guard let cacheDir = getCacheDir() else { return }
        let dynDir = cacheDir.appendingPathComponent(dynPath())
        clearDirectory(dir: dynDir)
    }
    
    static func createQjsTmpDir(watchfaceName: String) -> Bool {
        guard let cacheDir = getCacheDir() else { return false }
        let jwTmpDir = cacheDir.appendingPathComponent(jwPath(watchfaceName: watchfaceName))
        let aodTmpDir = cacheDir.appendingPathComponent(aodPath(watchfaceName: watchfaceName))

        deleteDirectory(directory: jwTmpDir)
        deleteDirectory(directory: aodTmpDir)

        do {
            try FileManager.default.createDirectory(at: jwTmpDir, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: aodTmpDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error.localizedDescription)")
            return false
        }

        print("createQjsTmpDir: \(aodTmpDir.path)")
        return true
    }

    static func deleteDirectory(directory: URL) {
        if FileManager.default.fileExists(atPath: directory.path) {
            if let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path) {
                for file in files {
                    let fileURL = directory.appendingPathComponent(file)
                    if (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                        // 递归删除子目录
                        deleteDirectory(directory: fileURL)
                    } else {
                        // 删除文件
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }
            }
        }
    }
    
    @objc public static func exportBin(source: UIImage, color: UIColor?) -> Data? {
        guard let sourceBytes = bitmapToByteArray(bitmap: source) else { return nil }
        print("exportBin: start, file size: \(sourceBytes.count)")
        let binType: UInt8 = 1
        guard let pngData = source.pngData() else {
            return nil
        }
        guard let data = ImageConvertor.eBin(fromPNGData: pngData, eColor: "rgb565", eType: 0, binType: binType, boardType: SFBoardType.type56X) else {
            return nil
        }
        return data
    }

    static func exportBin(source: UIImage, color: UIColor?, isAOD: Bool, isTimeHand: Bool, fileName: String, watchfaceName: String) -> Bool {
        var image: UIImage? = source
        if let tintColor = color {
            image = changeImageColor(source: source, color: tintColor)!
        }
        if image == nil {
            return false
        }
        return exportBin(source: image!, isAOD: isAOD, isTimeHand: isTimeHand, fileName: fileName, watchfaceName: watchfaceName)
    }

    static func exportBin(source: UIImage, isAOD: Bool, isTimeHand: Bool, fileName: String, watchfaceName: String) -> Bool {
        guard let sourceBytes = bitmapToByteArray(bitmap: source) else { return false }
        print("exportBin: start, file size: \(sourceBytes.count)")
        let binType: UInt8 = isTimeHand ? 0 : 1
        guard let pngData = source.pngData() else {
            return false
        }
        guard let data = ImageConvertor.eBin(fromPNGData: pngData, eColor: "rgb565", eType: 0, binType: binType, boardType: SFBoardType.type56X) else {
            return false
        }
        return writeByteArray(bytes: data, fileName: fileName, isAOD: isAOD, watchfaceName: watchfaceName)
//        return writeByteArray(bytes: pngData, fileName: fileName, isAOD: isAOD, watchfaceName: watchfaceName)
    }
    
    static func exportAlbumBin(source: UIImage, isTimeHand: Bool, fileName: String, folderURL: URL, isPng: Bool) -> Bool {
        var image: UIImage?
        image = source
        if image == nil  {
            return false
        }
        
        let binType: UInt8 = isTimeHand ? 0 : 1
        guard let pngData = image!.pngData() else {
            return false
        }
        let data = ImageConvertor.eBin(fromPNGData: pngData, eColor: "rgb565", eType: 0, binType: binType, boardType: SFBoardType.type56X)!
        return writeAlbumByteArray(bytes: data, fileName: fileName, folderURL: folderURL, isPng: isPng)
    }
    
    static func writeAlbumByteArray(bytes: Data, fileName: String, folderURL: URL, isPng: Bool) -> Bool {
        
        let namePrefix = isPng ? "PNG_\(fileName).bin" : "PRE_\(fileName).bin"
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error.localizedDescription)")
            }
        }

        var flag = true
        let fileURL = folderURL.appendingPathComponent("\(namePrefix)")
        do {
            try bytes.write(to: fileURL)
        } catch {
            print("Error writing data to file: \(error.localizedDescription)")
            flag = false
        }

        return flag
    }
    
    public typealias QjsCompressCallback = (Bool) -> ()
    
    static func getAlbumOutputPath() -> URL {
        let path = NSTemporaryDirectory().appending("output")
        let url = URL(fileURLWithPath: path)

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        return url.appendingPathComponent("photo.zip")
    }
    
    static func getMapFilesOutputZipFilePath() -> URL {
        let path = NSTemporaryDirectory().appending("offline_map")
        let url = URL(fileURLWithPath: path)
        deleteDirectory(directory: url)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        return url.appendingPathComponent("map.zip")
    }
    
    static func getMapFilesUnzipPath() -> URL {
        let path = NSTemporaryDirectory().appending("offline_map_unzip")
        let url = URL(fileURLWithPath: path)

        deleteDirectory(directory: url)
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        return url
    }
    
    
    //压缩mp3文件
    @objc static func packageQjsMp3(mp3FilePath: URL, completion: @escaping QjsCompressCallback) {
        // 移除 mp3FilePath 的最后一个路径组件
        let mp3DirectoryPath = mp3FilePath.deletingLastPathComponent()
        
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let outputDirectoryURL = tempDirectoryURL.appendingPathComponent("output")
        let outputFilePath = outputDirectoryURL.appendingPathComponent("beinvited.zip")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating output directory: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        do {
            try Zip.zipFiles(paths: [mp3DirectoryPath], zipFilePath: outputFilePath, password: nil, progress: { progress in
                DispatchQueue.main.async {
                    print("mp3压缩进度：\(progress)")
                    if progress >= 1.0 {
                        print("mp3压缩完成 Zip file path: \(outputFilePath.path)")
                        completion(true)
                    }
                }
            })
        } catch {
            DispatchQueue.main.async {
                print("Error mp3 zipping files: \(error.localizedDescription)")
                completion(false)
            }
        }
        
    }
    
    //压缩相册文件
    static func packageQjsAlbum(completion: @escaping QjsCompressCallback) {
        let zipFilePath: URL = getAlbumOutputPath()
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let folderPath = tempDirectoryURL.appendingPathComponent("qjs_albums/selectTemp/music")
        
        do {
            try Zip.zipFiles(paths: [folderPath], zipFilePath: zipFilePath, password: nil, progress: { progress in
                print("mp3压缩进度：\(progress)")
                DispatchQueue.main.async {
                    if progress >= 1.0 {
                        print("mp3压缩完成 Zip file path: \(zipFilePath.path)")
                        completion(true)
                    }
                }
            })
        } catch {
            print("Error mp3 zipping files: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    static func packageMapFilesZip(type: Int, mapPath: URL) -> String? {
        let fileManager = FileManager.default
        let zipFilePath = getMapFilesOutputZipFilePath()
        let unzipPath = getMapFilesUnzipPath()
        
        let baseMapPath = unzipPath.appendingPathComponent("music/MAP/map")
        
        let subfolderName = type == 1 ? "nanshan" : "nanshan-cm"
        let folderPath = baseMapPath.appendingPathComponent(subfolderName)
        
        // 确保目标目录存在
        do {
            try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error)")
            return nil
        }
        
        // 解压文件到目标目录
        let result = SSZipArchive.unzipFile(atPath: mapPath.path, toDestination: folderPath.path)
        if !result {
            print("解压失败：文件可能损坏或路径错误")
            return nil
        }
        
        // 重新生成 ZIP 文件（包含整个解压后的目录结构）
        let zipResult = SSZipArchive.createZipFile(atPath: zipFilePath.path, withContentsOfDirectory: unzipPath.path)
        if !zipResult {
            print("创建 ZIP 文件失败")
            return nil
        }
        
        return zipFilePath.path
    }
    
    static func changeImageColor(source: UIImage, color: UIColor) -> UIImage? {
        // 创建一个新的图片，与原始图片尺寸相同
        return source.imageByTintColor(color: color);
    }

    /**
     * GIF byte写入压缩包
     */
    static func exportGifBin(source: Data, isAOD: Bool, isTimeHand: Bool, fileName: String, watchfaceName: String) -> Bool {
        let binType: UInt8 = isTimeHand ? 0 : 1
        
        let data = ImageConvertor.eBin(fromPNGData: source, eColor: "rgb565", eType: 0, binType: binType, boardType: SFBoardType.type56X)!
        return writeByteArray(bytes: data, fileName: fileName, isAOD: isAOD, watchfaceName: watchfaceName)
    }

    static func writeMainJS(content: String, isAOD: Bool, watchfaceName: String) -> Bool {
        let folderURL = isAOD ? aodAbsolutePath(watchfaceName: watchfaceName) : jwAbsolutePathD(watchfaceName: watchfaceName)
        let name = isAOD ? "AOD_\(watchfaceName)_main.js" : "JW_\(watchfaceName)_main.js"
        let fileURL = folderURL.appendingPathComponent(name)
        
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Error removing item: \(error.localizedDescription)")
                return false
            }
        }

        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error.localizedDescription)")
                return false
            }
        }

        do {
            try content.write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {
            print("\(TAG) writeMainJS \(error.localizedDescription)")
            return false
        }
        return true
    }

//    static func packageQjs(_ watchfaceName: String) -> URL? {
//
//        let zipFilePath = qjsOutputPath(watchfaceName: watchfaceName)
//        let folderURL = qjsToZipFolder(watchfaceName: watchfaceName)
//        let targetFilePath = folderURL.appendingPathComponent("dynamic_app/qjs_wf/JW_diy/JW_diy_gif0.agif")
//
//        if let gifFilePath = Bundle.main.path(forResource: "JW_diy_gif0", ofType: "agif") {
//            do {
//                // Replace the file
//                try FileManager.default.removeItem(atPath: targetFilePath.path)
//                try FileManager.default.copyItem(atPath: gifFilePath, toPath: targetFilePath.path)
//            } catch {
//                print("Error replacing file: \(error.localizedDescription)")
//                return nil
//            }
//        }
//
//        do {
//            try Zip.zipFiles(paths: [folderURL], zipFilePath: zipFilePath, password: nil, progress: { progress in
//                print("压缩进度：\(progress)")
//                if progress >= 1.0 {
//                    print("压缩完成 Zip file path: \(zipFilePath.path)")
//                }
//            })
//        } catch {
//            print("Error zipping files: \(error.localizedDescription)")
//            return nil
//        }
//
//        return zipFilePath
//    }

    
    static func packageQjs(_ watchfaceName: String) -> URL? {
        
        let zipFilePath = qjsOutputPath(watchfaceName: watchfaceName)
        let folderURL = qjsToZipFolder(watchfaceName: watchfaceName)

        // 删除目录下所有的文件
        deleteDirectory(directory: zipFilePath)
        
        do {
            try Zip.zipFiles(paths: [folderURL], zipFilePath: zipFilePath, password: nil, progress: { progress in
                print("压缩进度：\(progress)")
                if progress >= 1.0 {
                    print("压缩完成 Zip file path: \(zipFilePath.path)")
                }
            })
        } catch {
            print("Error zipping files: \(error.localizedDescription)")
            return nil
        }
        
        return zipFilePath
    }
    
    public static func changeBitmapColor(originalBitmap: UIImage, color: UIColor) -> UIImage? {
        let rect = CGRect(origin: .zero, size: originalBitmap.size)
        UIGraphicsBeginImageContextWithOptions(originalBitmap.size, false, originalBitmap.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: 0, y: originalBitmap.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        context.clip(to: rect, mask: originalBitmap.cgImage!)
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let coloredBitmap = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return coloredBitmap
    }

    static func writeByteArray(bytes: Data, fileName: String, isAOD: Bool, watchfaceName: String) -> Bool {
        
        let folderURL = isAOD ? aodAbsolutePath(watchfaceName: watchfaceName) : jwAbsolutePathD(watchfaceName: watchfaceName)
        let namePrefix = isAOD ? "AOD_\(watchfaceName)_" : "JW_\(watchfaceName)_"
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating folder: \(error.localizedDescription)")
            }
        }

        var flag = true
        let fileURL = folderURL.appendingPathComponent("\(namePrefix)\(fileName)")
//        let fileURL = folderURL.appendingPathComponent("\(namePrefix)\(fileName).png")
        do {
            try bytes.write(to: fileURL)
        } catch {
            print("Error writing data to file: \(error.localizedDescription)")
            flag = false
        }

        return flag
    }

    static func copyFile(oldPathName: String, newPathName: String) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(atPath: oldPathName, toPath: newPathName)
            return true
        } catch {
            print("Failed to copy file: \(error.localizedDescription)")
            return false
        }
    }

    static func bitmapToByteArray(bitmap: UIImage) -> Data? {
        guard let data = bitmap.pngData() else { return nil }
        return data
    }

    static func bytesFromAsset(name: String) -> NSDataAsset? {
        guard let asset = NSDataAsset(name: name) else { return nil }
        return asset
    }

    static func getCrc(pSrc: [UInt8]) -> Int {
        var crc = 0xffffffff
        for byte in pSrc {
            crc ^= Int(byte) << 24
            for _ in 0..<8 {
                if (crc & 0x80000000) != 0 {
                    crc = (crc << 1) ^ 0x04c11db7
                } else {
                    crc <<= 1
                }
            }
        }
        return crc
    }

    static func addCrc2Bytes(fileName: String, bytes: [UInt8]) -> [UInt8] {
        var result = bytes
        let length = bytes.count
        let reminder = length % 4
        if reminder > 0 {
            let paddingLen = 4 - reminder
            result.append(contentsOf: Array(repeating: fileName.lowercased().hasSuffix(".js") ? 0x20 : 0, count: paddingLen))
        }

        let crc = getCrc(pSrc: result)
        var crcBytes = withUnsafeBytes(of: crc.littleEndian, Array.init)
        result.append(contentsOf: crcBytes)

        return result
    }

    static func convertFileToByteArray(filePath: String) -> Data? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return data
        } catch {
            print("Failed to convert file to byte array: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func cropAndScaleImage(filePath: String, width: Int, height: Int) -> UIImage {
        var resultBitmap: UIImage?

        // 加载图片并获取原始大小
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, options) else { return UIImage() }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let imageWidth = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let imageHeight = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0

        // 计算缩放比例
        let scaleFactor = (imageWidth <= imageHeight) ? CGFloat(width) / CGFloat(imageWidth) : CGFloat(height) / CGFloat(imageHeight)

        // 设置缩放和旋转矩阵
        var transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)

        // 加载原图并按照计算后的比例进行缩放
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return UIImage() }
        let context = CGContext(data: nil, width: Int(CGFloat(imageWidth) * scaleFactor), height: Int(CGFloat(imageHeight) * scaleFactor), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
        context?.concatenate(transform)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        resultBitmap = context?.makeImage().flatMap { UIImage(cgImage: $0) }

        // 裁剪中心部分
        let x = (resultBitmap!.size.width - CGFloat(width)) / 2
        let y = (resultBitmap!.size.height - CGFloat(height)) / 2
        let cropRect = CGRect(x: x, y: y, width: CGFloat(width), height: CGFloat(height))
        if let croppedCgImage = resultBitmap?.cgImage?.cropping(to: cropRect) {
            resultBitmap = UIImage(cgImage: croppedCgImage)
        }

        return resultBitmap!
    }
    
    static func cropAndScaleImage1(filePath: String, width: Int, height: Int) -> UIImage? {
        var resultBitmap: UIImage?

        // 加载图片并获取原始大小
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, options) else { return nil }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let imageWidth = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let imageHeight = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0

        // 读取图片的Exif信息，以判断是否需要旋转
        var rotation: CGFloat = 0
        if let exif = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let orientation = exif[kCGImagePropertyOrientation] as? Int {
            switch orientation {
            case 1:
                rotation = 0
            case 3:
                rotation = 180
            case 6:
                rotation = 90
            case 8:
                rotation = -90
            default:
                rotation = 0
            }
        }

        // 根据旋转角度调整宽高
        var transform = CGAffineTransform(rotationAngle: rotation * .pi / 180)
        if rotation == 90 || rotation == -90 {
            transform = transform.concatenating(CGAffineTransform(scaleX: CGFloat(height) / CGFloat(imageWidth), y: CGFloat(width) / CGFloat(imageHeight)))
        } else {
            transform = transform.concatenating(CGAffineTransform(scaleX: CGFloat(width) / CGFloat(imageWidth), y: CGFloat(height) / CGFloat(imageHeight)))
        }

        // 加载原图并按照计算后的比例进行缩放
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let context = CGContext(data: nil, width: Int(CGFloat(imageWidth) * transform.a), height: Int(CGFloat(imageHeight) * transform.d), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
        context?.concatenate(transform)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        resultBitmap = context?.makeImage().flatMap { UIImage(cgImage: $0) }

        // 根据缩放后的宽高进行裁剪
        let cropWidth = resultBitmap!.size.width
        let cropHeight = resultBitmap!.size.height
        if cropWidth > CGFloat(width) || cropHeight > CGFloat(height) {
            let x = (cropWidth - CGFloat(width)) / 2
            let y = (cropHeight - CGFloat(height)) / 2
            let cropRect = CGRect(x: x, y: y, width: CGFloat(width), height: CGFloat(height))
            if let croppedCgImage = resultBitmap?.cgImage?.cropping(to: cropRect) {
                resultBitmap = UIImage(cgImage: croppedCgImage)
            }
        }

        return resultBitmap
    }

    private static func calculateInSampleSize(options: [CFString: Any], reqWidth: Int, reqHeight: Int) -> Int {
        // 源图片的高度和宽度
        let height = options[kCGImagePropertyPixelHeight] as? Int ?? 0
        let width = options[kCGImagePropertyPixelWidth] as? Int ?? 0
        var inSampleSize = 1

        if height > reqHeight || width > reqWidth {
            let halfHeight = height / 2
            let halfWidth = width / 2

            // 计算最大的inSampleSize值，这是一个2的幂，并且是保持图片大小在请求大小之上的最大值
            while (halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }
   
    static func clearDirectory(dir: URL) {
        if FileManager.default.fileExists(atPath: dir.path) {
            if let children = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
                for child in children {
                    let temp = dir.appendingPathComponent(child)
                    if temp.hasDirectoryPath {
                        clearDirectory(dir: temp)
                        try? FileManager.default.removeItem(at: temp)
                    } else {
                        try? FileManager.default.removeItem(at: temp)
                    }
                }
            }
        } else if FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    public static func getFirstFrameBitmapOfGif(gif: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(gif as CFURL, nil) else {
            print("Failed to create image source")
            return nil
        }
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("Failed to create CGImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
