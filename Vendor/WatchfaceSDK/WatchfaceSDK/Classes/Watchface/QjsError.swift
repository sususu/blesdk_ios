
import Foundation

@objc public enum QjsError: Int {
    case none = 0
    case unknownError = 4000
    case createDirError = 4100
    case saveBinFileError = 4102
    case zipError = 4200
    case exportBinError = 4300
    case saveQjsFileError = 4400
    case qjsFileEmpty = 4440
    case saveAodQjsFileError = 4401
    case missingThumbnail = 4501
    case missingWidgetImages = 4504
    case manualStop = 4766

    static func valueOf(_ value: Int) -> QjsError {
        switch value {
            case 0: return .none
            case 4000: return .unknownError
            case 4100: return .createDirError
            case 4102: return .saveBinFileError
            case 4200: return .zipError
            case 4300: return .exportBinError
            case 4400: return .saveQjsFileError
            case 4401: return .saveAodQjsFileError
            case 4440: return .qjsFileEmpty
            case 4501: return .missingThumbnail
            case 4504: return .missingWidgetImages
            case 4766: return .manualStop
            default: return .unknownError
        }
    }

    func getValue() -> Int {
        return self.rawValue
    }
}
