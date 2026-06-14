import Foundation

public enum CodexUsageParser {
    public static func parse(_ data: Data, fetchedAt: Date = Date()) throws -> CodexUsage {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw CodexUsageError.parseError(error.localizedDescription)
        }

        guard let root = json as? [String: Any] else {
            throw CodexUsageError.parseError("top-level JSON is not an object")
        }

        guard let rateLimit = root["rate_limit"] as? [String: Any] else {
            throw CodexUsageError.parseError("missing rate_limit object")
        }

        return CodexUsage(
            planType: root["plan_type"] as? String,
            resetCreditsAvailable: parseResetCredits(root["rate_limit_reset_credits"]),
            fiveHour: parseWindow(rateLimit["primary_window"]),
            weekly: parseWindow(rateLimit["secondary_window"]),
            fetchedAt: fetchedAt
        )
    }

    private static func parseResetCredits(_ value: Any?) -> Int? {
        guard let object = value as? [String: Any] else {
            return nil
        }

        if let count = object["available_count"] as? Int {
            return count
        }

        if let count = object["available_count"] as? NSNumber {
            return count.intValue
        }

        if let count = object["available_count"] as? String {
            return Int(count)
        }

        return nil
    }

    private static func parseWindow(_ value: Any?) -> WindowUsage {
        guard let object = value as? [String: Any] else {
            return WindowUsage(usedPercent: nil, remainingPercent: nil, resetAt: nil)
        }

        let usedPercent = number(object["used_percent"])
        let remainingPercent = usedPercent.map { max(0, 100 - $0) }
        let resetAt = number(object["reset_at"]).map { Date(timeIntervalSince1970: $0) }

        return WindowUsage(
            usedPercent: usedPercent,
            remainingPercent: remainingPercent,
            resetAt: resetAt
        )
    }

    private static func number(_ value: Any?) -> Double? {
        switch value {
        case let number as Double:
            return number
        case let number as Int:
            return Double(number)
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }
}
