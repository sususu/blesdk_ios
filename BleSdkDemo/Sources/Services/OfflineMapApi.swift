import CryptoKit
import Foundation

/// PiMap cloud package metadata (aligned with Android `PiMapInfo`).
struct PiMapInfo {
    let downloadUrl: String
    let md5: String
    /// Uncompressed size in **bytes** (API historically swaps compressed/uncompressed keys).
    let uncompressedSize: Int64?
    let compressedSize: Int64?
}

/// Direct PiMap HTTP APIs (same as Android `OfflineMapApi`, not HaWoFit app proxy).
///
/// - Login: `POST {base}user/login`
/// - Auth: `POST {base}auth/getAuthInfo?type=0001&deviceId={uuid}`
/// - Package: `POST {base}optionalMap/generateFile`
enum OfflineMapApi {
    static let baseURL = "https://map-global.iipii.net/"

    private static let loginPhone = "919654481080"
    /// RSA ciphertext expected by the server (demo account; same as Android).
    private static let loginPwd =
        "di0RwD38AEQglZEByPNErjdWyMTmN8QK/Z04gMIm09h7HKx/z8z0Zf0mwwmc8pC7tJ/UFPiTxrn7vcuTtn4EUKNaKqAJxj7KtF/NoFDlPvMXNhMBRTVMRLkvA6nzq9EZo6qLeED9/QCQWLMm3uEbWoVHPpuraI9o/6iR/VXCe00="

    private static let prefsKey = "offline_map_api"
    private static let keyUserId = "userId"
    private static let keyToken = "token"

    private static let sessionLock = NSLock()
    private static var cachedUserId: String?
    private static var cachedToken: String?

    // MARK: - Public

    static func fetchAuthCode(mapUuid: String) throws -> String {
        let enc = mapUuid.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mapUuid
        let url = baseURL + "auth/getAuthInfo?type=0001&deviceId=" + enc
        let body: [String: Any] = ["type": "0001", "deviceId": mapUuid]
        let raw = try httpPostJSON(urlString: url, body: body)
        let data = try requireSuccessData(raw, api: "getAuthInfo")
        let code = (data["authCode"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty else { throw SdkError(code: -1, message: "authCode empty") }
        return code
    }

    static func requestOfflinePackage(
        mapUuid: String,
        productCode: String,
        minLon: Double,
        minLat: Double,
        maxLon: Double,
        maxLat: Double,
        centerLat: Double,
        centerLon: Double
    ) throws -> PiMapInfo {
        let body: [String: Any] = [
            "type": 1,
            "minLongitude": minLon,
            "minLatitude": minLat,
            "maxLongitude": maxLon,
            "maxLatitude": maxLat,
            "deviceUuid": mapUuid,
            "manufacturer": "Huawo",
            "model": productCode,
            "reservedStorage": 52048,
            "locationLat": centerLat,
            "locationLon": centerLon
        ]
        let raw = try httpPostJSON(urlString: baseURL + "optionalMap/generateFile", body: body)
        let data = try requireSuccessData(raw, api: "generateFile")
        let url = (data["downloadUrl"] as? String) ?? ""
        let md5 = (data["md5"] as? String) ?? ""
        guard !url.isEmpty, !md5.isEmpty else {
            throw SdkError(code: -1, message: "downloadUrl/md5 missing")
        }
        // Same field swap as Android / HaWoFit (API keys are historically inverted).
        let uncompressed = int64(data["compressedSize"])
        let compressed = int64(data["uncompressedSize"])
        return PiMapInfo(
            downloadUrl: resolveFileURL(url),
            md5: md5,
            uncompressedSize: uncompressed,
            compressedSize: compressed
        )
    }

    static func downloadToCache(
        urlString: String,
        onProgress: @escaping (Float) -> Void
    ) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw SdkError(code: -1, message: "bad download url")
        }
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("device/offlinemap", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let out = dir.appendingPathComponent("map.zip")
        if FileManager.default.fileExists(atPath: out.path) {
            try? FileManager.default.removeItem(at: out)
        }

        let sem = DispatchSemaphore(value: 0)
        var resultURL: URL?
        var resultError: Error?
        let task = URLSession.shared.downloadTask(with: url) { tmp, response, error in
            defer { sem.signal() }
            if let error = error { resultError = error; return }
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...299).contains(code), let tmp = tmp else {
                resultError = SdkError(code: code, message: "HTTP \(code)")
                return
            }
            do {
                try FileManager.default.moveItem(at: tmp, to: out)
                resultURL = out
                onProgress(1)
            } catch {
                resultError = error
            }
        }
        // Approximate download progress via KVO on countOfBytesReceived when total is known.
        let progressObs = task.progress.observe(\.fractionCompleted, options: [.new]) { prog, _ in
            onProgress(Float(prog.fractionCompleted).clamped(to: 0...1))
        }
        task.resume()
        _ = sem.wait(timeout: .now() + 180)
        progressObs.invalidate()
        if let resultError = resultError { throw resultError }
        guard let resultURL = resultURL else {
            throw SdkError(code: -1, message: "download failed")
        }
        return resultURL
    }

    static func md5Of(fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        return Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func clearSession() {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        cachedUserId = nil
        cachedToken = nil
        UserDefaults.standard.removeObject(forKey: prefsKey)
    }

    // MARK: - Session

    private static func ensureSession() throws -> (String, String) {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        if let u = cachedUserId, let t = cachedToken, !u.isEmpty, !t.isEmpty {
            return (u, t)
        }
        if let dict = UserDefaults.standard.dictionary(forKey: prefsKey),
           let u = dict[keyUserId] as? String, let t = dict[keyToken] as? String,
           !u.isEmpty, !t.isEmpty {
            cachedUserId = u
            cachedToken = t
            return (u, t)
        }
        return try loginAndCache()
    }

    private static func loginAndCache() throws -> (String, String) {
        let body: [String: Any] = ["phone": loginPhone, "pwd": loginPwd]
        let raw = try httpPostJSONRaw(
            urlString: baseURL + "user/login",
            body: body,
            userId: nil,
            token: nil
        )
        let data = try requireSuccessData(raw, api: "login")
        let userId = (data["userId"] as? String) ?? ""
        let token = (data["token"] as? String) ?? ""
        guard !userId.isEmpty, !token.isEmpty else {
            throw SdkError(code: -1, message: "login userId/token empty")
        }
        cachedUserId = userId
        cachedToken = token
        UserDefaults.standard.set([keyUserId: userId, keyToken: token], forKey: prefsKey)
        return (userId, token)
    }

    // MARK: - HTTP

    private static func httpPostJSON(urlString: String, body: [String: Any]) throws -> String {
        let (userId, token) = try ensureSession()
        return try httpPostJSONRaw(urlString: urlString, body: body, userId: userId, token: token)
    }

    private static func httpPostJSONRaw(
        urlString: String,
        body: [String: Any],
        userId: String?,
        token: String?
    ) throws -> String {
        guard let url = URL(string: urlString) else {
            throw SdkError(code: -1, message: "bad url")
        }
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let token = token, !token.isEmpty { req.setValue(token, forHTTPHeaderField: "token") }
        if let userId = userId, !userId.isEmpty { req.setValue(userId, forHTTPHeaderField: "userId") }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let sem = DispatchSemaphore(value: 0)
        var out: String?
        var err: Error?
        URLSession.shared.dataTask(with: req) { data, response, error in
            defer { sem.signal() }
            if let error = error { err = error; return }
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                err = SdkError(code: code, message: "empty response")
                return
            }
            if !(200...299).contains(code) {
                err = SdkError(code: code, message: text)
                return
            }
            out = text
        }.resume()
        _ = sem.wait(timeout: .now() + 90)
        if let err = err { throw err }
        guard let out = out else { throw SdkError(code: -1, message: "timeout") }
        return out
    }

    private static func requireSuccessData(_ raw: String, api: String) throws -> [String: Any] {
        guard let root = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
            throw SdkError(code: -1, message: "\(api) bad json")
        }
        guard isSuccessCode(root) else {
            let code = root["code"] ?? "?"
            let msg = (root["msg"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? raw
            throw SdkError(code: -1, message: "\(api) failed code=\(code) msg=\(msg)")
        }
        guard let data = root["data"] as? [String: Any] else {
            throw SdkError(code: -1, message: "\(api) data null")
        }
        return data
    }

    private static func isSuccessCode(_ root: [String: Any]) -> Bool {
        let code = root["code"]
        if let n = code as? NSNumber { return n.intValue == 0 }
        if let s = code as? String { return s == "0" }
        return false
    }

    private static func resolveFileURL(_ path: String) -> String {
        if path.lowercased().hasPrefix("http") { return path }
        return baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            + "/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private static func int64(_ any: Any?) -> Int64? {
        if let n = any as? NSNumber { return n.int64Value }
        if let s = any as? String, let v = Int64(s) { return v }
        return nil
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
