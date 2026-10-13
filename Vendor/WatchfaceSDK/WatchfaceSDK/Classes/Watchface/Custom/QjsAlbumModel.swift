//
//  QjsAlbumModel.swift
//  WatchfaceSDK
//
//  Created by huawo01 on 2024/8/9.
//

import UIKit

@objc public class QjsAlbumModel: NSObject {
    //pictures
    @objc public var image: UIImage?
    //Image name (named from 1... 50, the current firmware supports 50 pictures)
    @objc public var name: String?
   
    func getAlbumSelectTempPath() -> String {
        let path = NSTemporaryDirectory().appending("qjs_albums/selectTemp/music/photo")
        let url = URL(fileURLWithPath: path)

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        return path
    }

}

