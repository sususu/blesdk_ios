import Foundation

@objc public protocol QjsLifeCycle: Qjs {
    func start() -> String
    func refresh() -> String
    func resume() -> String
    func pause() -> String
    func stop() -> String
}
