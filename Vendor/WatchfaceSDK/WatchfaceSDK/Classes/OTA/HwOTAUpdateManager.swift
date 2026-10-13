//
//  HwOTAUpdateManager.swift
//  iOS_TADemo
//
//  Created by huawo01 on 2024/8/16.
//

import UIKit
import SifliOTAManagerSDK
import SSZipArchive

public enum FirmwareUpdateState: Int {
    case progress // 进度(Progress)
    case success  // 成功(Success)
    case failure  // 失败(Failure)
}

public typealias HwFirmwareUpdateBlock = (FirmwareUpdateState, Int, Int, String) -> ()

public class HwOTAUpdateManager: NSObject, SFOTAManagerDelegate {
    
    public static let shared = HwOTAUpdateManager()
    
    var firmwarePath: String?
    var resourcePath: String?
    var progress: Int = 0
    var firmwareUpdateBlock: HwFirmwareUpdateBlock?
    
    var imageFileInfoArray: [SFNandImageFileInfo] = []
    
    private var manager = SFOTAManager.share
    private var hadInit = false
    
    private override init() {
        super.init()
    }
    
    public func initSDK() {
        hadInit = true
        self.manager = SFOTAManager.share
    }
    
    public func stopFirmwareUpgrade() {
        manager.stop()
    }
    
    public func startFirmwareUpgrade(devIdentifier: String,firmwarePath: String, differencePath: String, callback: @escaping HwFirmwareUpdateBlock) {
        assert(hadInit, "Please call HwOTAUpdateManager.shared.initSDK(application: UIApplication) before using any API")
        self.firmwareUpdateBlock = callback
        self.firmwarePath = firmwarePath
        self.resourcePath = differencePath
        if let firmwarePath = self.firmwarePath, let resourcePath = self.resourcePath {
            if let scZipPath = scZipPath(handleZipFile: firmwarePath) {
                scOTA(devIdentifier: devIdentifier, scZipPath: scZipPath)
            } else {
                firmwareUpdateBlock?(.failure, 0, 0, "固件解压失败")
                print("scZipPath == nil 固件解压失败")
            }
        } else {
            firmwareUpdateBlock?(.failure, 0, 0, "固件解压失败")
            print("Please pass in the firmware package path and differential resource path")
        }
    }
    
    func scOTA(devIdentifier: String,scZipPath: String) {
        guard let subDirs = QjsStorageUtils.getFiles(atDirectory: scZipPath) else {
            firmwareUpdateBlock?(.failure, 0, 0, "固件解压失败")
            print("subDirs == nil 固件解压为空")
            return
        }
        
        imageFileInfoArray.removeAll()
        var ctrlPath: URL?
        var diffCtrlPath: URL?
        
        for fp in subDirs {
            let name = (fp as NSString).lastPathComponent
            let path = (scZipPath as NSString).appendingPathComponent(fp)
            
            if name.hasPrefix("ctrl") && name.hasSuffix(".bin") {
                ctrlPath = URL(fileURLWithPath: path)
            }
            
            if name.hasPrefix("diff_ctrl") && name.hasSuffix(".bin") {
                diffCtrlPath = URL(fileURLWithPath: path)
            }
            
            let pathUrl = URL(fileURLWithPath: path)
            var imageFileInfo: SFNandImageFileInfo? = nil
            if name.hasPrefix("hcpu") && name.hasSuffix(".bin") {
                imageFileInfo = SFNandImageFileInfo.init(path: pathUrl , imageID: .HCPU)
                imageFileInfoArray.append(imageFileInfo!)
            } else if name.hasPrefix("patch_lcpu") && name.hasSuffix(".bin") {
                imageFileInfo = SFNandImageFileInfo.init(path: pathUrl, imageID: .LCPU_PATCH)
                imageFileInfoArray.append(imageFileInfo!)
            } else if name.hasPrefix("lcpu") && name.hasSuffix(".bin")  {
                imageFileInfo = SFNandImageFileInfo.init(path: pathUrl, imageID: .LCPU)
                imageFileInfoArray.append(imageFileInfo!)
            }
        }
        
        manager.delegate = self
        progress = 0
        
        manager.startOTANand(targetDeviceIdentifier: devIdentifier, resourcePath: URL(fileURLWithPath: resourcePath!), controlImageFilePath: diffCtrlPath, imageFileInfos: imageFileInfoArray, tryResume: true, imageResponseFrequnecy: 4)
    }
    
    func scZipPath(handleZipFile zipFilePath: String) -> String? {
        let unzipPath = (QjsStorageUtils.getCahcePath() as NSString).appendingPathComponent("TA")
        if !QjsStorageUtils.isFileExits(atPath: unzipPath) {
            QjsStorageUtils.createPath(path: unzipPath)
        } else {
            QjsStorageUtils.deleteFiles(atPath: unzipPath)
        }
        
        let result = SSZipArchive.unzipFile(atPath: zipFilePath, toDestination: unzipPath)
        if !result {
            print("解压文件失败。下载文件可能出错。请重新下载")
            return nil
        }
        
        guard let subDirs = QjsStorageUtils.getFiles(atDirectory: unzipPath) else {
            print("ZIP解压后为空")
            return nil
        }
        
        var isSC = false
        for fp in subDirs {
            if (fp as NSString).hasSuffix("Ota") {
                isSC = true
            }
        }
        
        if isSC {
            return unzipPath
        } else {
            print("不是思澈的固件包")
            return nil
        }
    }
    
    // MARK: - SFOTAManagerDelegate
    
    public func otaManager(manager: SFOTAManager, updateBleState state: BleCoreManagerState) {
        print("蓝牙状态改变: \(state.rawValue)")
    }
    
    public func otaManager(manager: SFOTAManager, stage: SFOTAProgressStage, totalBytes: Int, completedBytes: Int) {
        DispatchQueue.main.async {
            if stage == .nand_res {
                self.progress = Int(Float(completedBytes) / Float(totalBytes) * 100 * 0.5)
            } else if stage == .nand_image {
                self.progress = 50 + Int(Float(completedBytes) / Float(totalBytes) * 100 * 0.5)
            }
        
            self.firmwareUpdateBlock?(.progress, self.progress, 0, "")
        }
    }
    
    public func otaManager(manager: SFOTAManager, complete error: SFOTAError?) {
        if let error = error {
            print("升级失败：\(error.errorDes)")
            firmwareUpdateBlock?(.failure, self.progress, error.errorType.rawValue, error.errorDes)
        } else {
            print("升级成功")
            firmwareUpdateBlock?(.success, self.progress, 0, "")
        }
    }
}

