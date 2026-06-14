import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum CodexUsageError: Error, CustomStringConvertible {
    case noAuthFile(String)
    case invalidAuthFile(String)
    case missingAccessToken
    case authExpired
    case httpStatus(Int, String)
    case invalidResponse
    case parseError(String)

    public var description: String {
        switch self {
        case .noAuthFile(let path):
            return "no auth file at \(path). Run `codex login` first."
        case .invalidAuthFile(let detail):
            return "invalid auth file: \(detail)"
        case .missingAccessToken:
            return "no access token in ~/.codex/auth.json. Run `codex login` first."
        case .authExpired:
            return "auth expired. Run `codex login` to refresh credentials."
        case .httpStatus(let status, let body):
            _ = body
            return "HTTP \(status)"
        case .invalidResponse:
            return "invalid HTTP response"
        case .parseError(let detail):
            return "parse error: \(detail)"
        }
    }
}

public struct WindowUsage: Codable, Sendable {
    public let usedPercent: Double?
    public let remainingPercent: Double?
    public let resetAt: Date?

    public init(usedPercent: Double?, remainingPercent: Double?, resetAt: Date?) {
        self.usedPercent = usedPercent
        self.remainingPercent = remainingPercent
        self.resetAt = resetAt
    }
}

public struct CodexUsage: Codable, Sendable {
    public let planType: String?
    public let resetCreditsAvailable: Int?
    public let fiveHour: WindowUsage
    public let weekly: WindowUsage
    public let fetchedAt: Date

    public init(
        planType: String?,
        resetCreditsAvailable: Int?,
        fiveHour: WindowUsage,
        weekly: WindowUsage,
        fetchedAt: Date
    ) {
        self.planType = planType
        self.resetCreditsAvailable = resetCreditsAvailable
        self.fiveHour = fiveHour
        self.weekly = weekly
        self.fetchedAt = fetchedAt
    }
}

public final class CodexUsageClient: @unchecked Sendable {
    private let authPath: String?
    private let endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!
    private let session: URLSession

    public init(authPath: String? = nil) {
        self.authPath = authPath
        self.session = URLSession(configuration: .ephemeral)
    }

    public func fetchUsage() async throws -> CodexUsage {
        let data = try await fetchRawData()
        return try CodexUsageParser.parse(data)
    }

    public func fetchRawRedactedJSON() async throws -> String {
        let data = try await fetchRawData()
        let json = try JSONSerialization.jsonObject(with: data)
        let redacted = redact(json)
        let pretty = try JSONSerialization.data(withJSONObject: redacted, options: [.prettyPrinted, .sortedKeys])
        return String(decoding: pretty, as: UTF8.self)
    }

    private func fetchRawData() async throws -> Data {
        let token = try readAccessToken()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CodexUsageError.invalidResponse
        }

        if http.statusCode == 401 {
            throw CodexUsageError.authExpired
        }

        guard http.statusCode == 200 else {
            let body = String(decoding: data.prefix(500), as: UTF8.self)
            throw CodexUsageError.httpStatus(http.statusCode, body)
        }

        return data
    }

    private func readAccessToken() throws -> String {
        let path = expandedAuthPath()
        guard FileManager.default.fileExists(atPath: path) else {
            throw CodexUsageError.noAuthFile(path)
        }

        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            throw CodexUsageError.invalidAuthFile(error.localizedDescription)
        }

        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw CodexUsageError.invalidAuthFile(error.localizedDescription)
        }

        guard let root = json as? [String: Any] else {
            throw CodexUsageError.invalidAuthFile("top-level JSON is not an object")
        }

        let token = (root["tokens"] as? [String: Any])?["access_token"] as? String
            ?? root["access_token"] as? String

        guard let token, !token.isEmpty else {
            throw CodexUsageError.missingAccessToken
        }

        return token
    }

    private func expandedAuthPath() -> String {
        if let authPath {
            return NSString(string: authPath).expandingTildeInPath
        }
        return NSString(string: "~/.codex/auth.json").expandingTildeInPath
    }

    private func redact(_ value: Any) -> Any {
        if let object = value as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in object {
                if shouldRedact(key) {
                    result[key] = "<redacted>"
                } else {
                    result[key] = redact(value)
                }
            }
            return result
        }

        if let array = value as? [Any] {
            return array.map(redact)
        }

        return value
    }

    private func shouldRedact(_ key: String) -> Bool {
        let lowercased = key.lowercased()
        return lowercased.contains("token")
            || lowercased.contains("secret")
            || lowercased.contains("key")
            || lowercased.contains("authorization")
            || lowercased == "email"
            || lowercased == "account_id"
            || lowercased == "user_id"
    }
}
