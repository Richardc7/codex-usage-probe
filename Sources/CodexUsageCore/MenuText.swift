import Foundation

public enum AppLanguage: String, Sendable {
    case english
    case chinese
}

public struct MenuText: Sendable {
    public let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = language
    }

    public var appTitle: String {
        switch language {
        case .english: "Codex Usage"
        case .chinese: "Codex 用量"
        }
    }

    public var planTitle: String {
        switch language {
        case .english: "Plan"
        case .chinese: "套餐"
        }
    }

    public var resetCreditsTitle: String {
        switch language {
        case .english: "Reset credits"
        case .chinese: "重置次数"
        }
    }

    public var staleStatusTitle: String {
        switch language {
        case .english: "Status: stale"
        case .chinese: "状态：已过期"
        }
    }

    public var noUsageDataTitle: String {
        switch language {
        case .english: "No usage data yet"
        case .chinese: "暂无用量数据"
        }
    }

    public var errorTitle: String {
        switch language {
        case .english: "Error"
        case .chinese: "错误"
        }
    }

    public var displayTitle: String {
        switch language {
        case .english: "Display"
        case .chinese: "显示"
        }
    }

    public var displayModeTitle: String {
        switch language {
        case .english: "Usage Display"
        case .chinese: "用量显示"
        }
    }

    public var remainingTitle: String {
        switch language {
        case .english: "Remaining"
        case .chinese: "剩余"
        }
    }

    public var usedTitle: String {
        switch language {
        case .english: "Used"
        case .chinese: "已用"
        }
    }

    public var formatTitle: String {
        switch language {
        case .english: "Format"
        case .chinese: "格式"
        }
    }

    public var fullFormatTitle: String {
        switch language {
        case .english: "Full"
        case .chinese: "完整"
        }
    }

    public var compactFormatTitle: String {
        switch language {
        case .english: "Compact"
        case .chinese: "简单"
        }
    }

    public var languageTitle: String {
        switch language {
        case .english: "Language"
        case .chinese: "语言"
        }
    }

    public var englishTitle: String {
        switch language {
        case .english: "English"
        case .chinese: "英文"
        }
    }

    public var chineseTitle: String {
        switch language {
        case .english: "Chinese"
        case .chinese: "中文"
        }
    }

    public var showResetCreditsTitle: String {
        switch language {
        case .english: "Show Reset Credits"
        case .chinese: "状态栏显示重置次数"
        }
    }

    public var showLowUsageWarningTitle: String {
        switch language {
        case .english: "Show Low-Usage Warning"
        case .chinese: "显示低用量提示"
        }
    }

    public var refreshTitle: String {
        switch language {
        case .english: "Refresh"
        case .chinese: "刷新"
        }
    }

    public var customTitle: String {
        switch language {
        case .english: "Custom..."
        case .chinese: "自定义..."
        }
    }

    public var refreshNowTitle: String {
        switch language {
        case .english: "Refresh Now"
        case .chinese: "立即刷新"
        }
    }

    public var lastUpdatedTitle: String {
        switch language {
        case .english: "Last updated"
        case .chinese: "上次更新"
        }
    }

    public var refreshingTitle: String {
        switch language {
        case .english: "refreshing..."
        case .chinese: "刷新中..."
        }
    }

    public var neverTitle: String {
        switch language {
        case .english: "never"
        case .chinese: "从未"
        }
    }

    public var unknownTitle: String {
        switch language {
        case .english: "unknown"
        case .chinese: "未知"
        }
    }

    public var unavailableTitle: String {
        switch language {
        case .english: "unavailable"
        case .chinese: "不可用"
        }
    }

    public var remainingDetailTitle: String {
        switch language {
        case .english: "remaining"
        case .chinese: "剩余"
        }
    }

    public var usedDetailTitle: String {
        switch language {
        case .english: "used"
        case .chinese: "已用"
        }
    }

    public var resetsTitle: String {
        switch language {
        case .english: "resets"
        case .chinese: "重置"
        }
    }

    public var lowRemainingTitle: String {
        switch language {
        case .english: "Low remaining"
        case .chinese: "剩余额度低"
        }
    }

    public var customRefreshIntervalTitle: String {
        switch language {
        case .english: "Custom refresh interval"
        case .chinese: "自定义刷新间隔"
        }
    }

    public var customRefreshIntervalMessage: String {
        switch language {
        case .english: "Enter a value from 30 to 3600 seconds."
        case .chinese: "输入 30 到 3600 秒之间的数值。"
        }
    }

    public var saveTitle: String {
        switch language {
        case .english: "Save"
        case .chinese: "保存"
        }
    }

    public var cancelTitle: String {
        switch language {
        case .english: "Cancel"
        case .chinese: "取消"
        }
    }

    public var openCodexTitle: String {
        switch language {
        case .english: "Open Codex"
        case .chinese: "打开 Codex"
        }
    }

    public var quitTitle: String {
        switch language {
        case .english: "Quit"
        case .chinese: "退出"
        }
    }
}
