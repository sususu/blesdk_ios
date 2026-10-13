//
//  QjsStorageUtils.swift
//  BLE-Swift
//
//  Created by SuJiang on 2019/1/8.
//  Copyright © 2019 ss. All rights reserved.
//

import UIKit

public class QjsStorageUtils: NSObject {
    
    
    @objc public static func saveString(_ str: String, forKey key: String) {
        save(str, forKey: key)
    }
    
    @objc public static func getString(forKey key: String) -> String? {
        return get(forKey: key) as? String
    }
    
    @objc public static func getData(forKey key: String) -> Data? {
        return get(forKey: key) as? Data
    }
    
    @objc public static func save(_ v: Any, forKey key: String) {
        UserDefaults.standard.set(v, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    @objc public static func get(forKey key: String) -> Any? {
        return UserDefaults.standard.value(forKey: key)
    }
    
    @objc public static func saveAsFile(forString string: String, fileName: String) -> URL? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return saveAsFile(forData: data, fileName: fileName)
    }
    
    @objc public static func saveAsFile(forData data: Data, fileName: String) -> URL? {
        let filePath = (getDocPath() as NSString).appendingPathComponent(fileName)
        let url = URL(fileURLWithPath: filePath)
        if QjsStorageUtils.isFileExits(atPath: filePath) {
            _ = QjsStorageUtils.deleteFile(atPath: filePath)
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return nil
        }
        return url
    }
    
    

    @objc public static func getDocPath() -> String {
        let manager = FileManager.default
        let urls = manager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].path
    }
    
    @objc public static func getCahcePath() -> String {
        let manager = FileManager.default
        let urls = manager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].path
    }
    
    @objc public static func getTempPath() -> String {
//        let manager = FileManager.default
//        let urls = manager.urls(for: .cachesDirectory, in: .userDomainMask)
//        return urls[0].path
        let tmpDir = NSTemporaryDirectory()
        return tmpDir
    }
    
    @objc public static func isFileExits(atPath path: String) -> Bool {
        let manager = FileManager.default
        return manager.fileExists(atPath: path)
    }
    
    @objc public static func createPath(path: String) -> Bool {
        let manager = FileManager.default
        
        if isFileExits(atPath: path) {
            return true
        }
        
        do {
            try manager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }
    
    @objc public static func moveItem(fromPath: String, toPath: String) -> Bool {
        let manager = FileManager.default
        do {
            try manager.moveItem(atPath: fromPath, toPath: toPath)
            return true
        } catch {
            return false
        }
    }
    
    @objc public static func copyItem(fromPath: String, toPath: String) -> Bool {
        let manager = FileManager.default
        do {
            try manager.copyItem(atPath: fromPath, toPath: toPath)
            return true
        } catch {
            return false
        }
    }
    
    @objc public static func deleteFile(atPath path: String) -> Bool {
        let manager = FileManager.default
        do {
            try manager.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
    
    @objc public static func deleteFiles(atPath path: String) {
        let manager = FileManager.default
        do {
            try manager.removeItem(atPath: path)
        } catch {
            
        }
        _ = createPath(path: path)
    }
    
    @objc public static func getData(atPath path: String) -> Data? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return data
            
        } catch {
            return nil
        }
    }
    
    @objc public static func getFiles(atDirectory directory: String) -> Array<String>? {
        let manager = FileManager.default
        do {

            let result = try manager.subpathsOfDirectory(atPath: directory)
            return result

        } catch {
            return nil
        }
    }
}
