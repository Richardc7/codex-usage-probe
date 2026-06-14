import Foundation

public enum DisplayMetric: String, Sendable {
    case remaining
    case used
}

public enum DisplayDensity: String, Sendable {
    case full
    case compact
}

public struct StatusTitleFormatter: Sendable {
    public let metric: DisplayMetric
    public let density: DisplayDensity
    public let showsResetCredits: Bool
    public let showsLowUsageWarning: Bool
    public let lowRemainingThreshold: Double

    public init(
        metric: DisplayMetric,
        density: DisplayDensity,
        showsResetCredits: Bool,
        showsLowUsageWarning: Bool,
        lowRemainingThreshold: Double = 20
    ) {
        self.metric = metric
        self.density = density
        self.showsResetCredits = showsResetCredits
        self.showsLowUsageWarning = showsLowUsageWarning
        self.lowRemainingThreshold = lowRemainingThreshold
    }

    public func title(for usage: CodexUsage) -> String {
        let fiveHour = statusPart(label: "5h", window: usage.fiveHour)
        let weekly = statusPart(label: "W", window: usage.weekly)
        var title: String

        switch density {
        case .full:
            title = "\(fiveHour) · \(weekly)"
        case .compact:
            title = "\(compactPart(usage.fiveHour))/\(compactPart(usage.weekly))"
        }

        if showsResetCredits, let resetCredits = usage.resetCreditsAvailable {
            title += density == .full ? " · R\(resetCredits)" : " R\(resetCredits)"
        }

        return title
    }

    private func statusPart(label: String, window: WindowUsage) -> String {
        let warning = lowWarningPrefix(for: window)
        return "\(warning)\(label) \(integerPercent(displayPercent(for: window)))"
    }

    private func compactPart(_ window: WindowUsage) -> String {
        "\(lowWarningPrefix(for: window))\(integerPercent(displayPercent(for: window), includeSymbol: false))"
    }

    private func lowWarningPrefix(for window: WindowUsage) -> String {
        guard showsLowUsageWarning,
              let remaining = window.remainingPercent,
              remaining < lowRemainingThreshold else {
            return ""
        }
        return "!"
    }

    private func displayPercent(for window: WindowUsage) -> Double? {
        switch metric {
        case .remaining:
            return window.remainingPercent
        case .used:
            return window.usedPercent
        }
    }

    private func integerPercent(_ value: Double?, includeSymbol: Bool = true) -> String {
        guard let value else {
            return includeSymbol ? "--%" : "--"
        }
        let rounded = Int(value.rounded())
        return includeSymbol ? "\(rounded)%" : "\(rounded)"
    }
}
