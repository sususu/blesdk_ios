import Foundation

class QjsFunction: Qjs {
    private var name: String
    private var body: String?
    private var arguments: [String]?

    init(name: String) {
        self.name = name
    }

    func toQjs(_ isAOD: Bool) -> String {
        var result = "\(name)("
        if let args = arguments, !args.isEmpty {
            result += args.joined(separator: ",")
        }
        result += ") {"
        if let body = body {
            result += "\n\(body)"
        }
        result += "\n\t}"
        return result
    }

    func getName() -> String {
        return name
    }

    func setName(_ name: String) {
        self.name = name
    }

    func getBody() -> String? {
        return body
    }

    func setBody(_ body: String?) {
        self.body = body
    }

    func getArguments() -> [String]? {
        return arguments
    }

    func setArguments(_ arguments: [String]?) {
        self.arguments = arguments
    }
}
