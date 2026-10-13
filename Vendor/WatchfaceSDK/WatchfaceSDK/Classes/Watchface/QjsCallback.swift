
import Foundation

@objc public protocol QjsCallback {
    /**
     * zip file will be deleted, if return true, if you don't want it to be deleted, override callback return false, or you can save the file before returning true
     * @param zip
     */
    func onZipCompleted(zip: URL)
    func onError(code: Int)
    func onQjsSaved()
    func onProgress(current: Int64, total: Int64)
    func onSuccess()
}

extension QjsCallback {
    func onZipCompleted(zip: URL) {
        // Default implementation
    }
    
    func onQjsSaved() {
        // Default implementation
    }
    
    func onProgress(current: Int64, total: Int64) {
        // Default implementation
    }
}
