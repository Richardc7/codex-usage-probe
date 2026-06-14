import AppKit
import CodexUsageCore
import Foundation

struct RefreshInterval: Equatable {
    let label: String
    let seconds: TimeInterval

    static let thirtySeconds = RefreshInterval(label: "30 sec", seconds: 30)
    static let oneMinute = RefreshInterval(label: "1 min", seconds: 60)
    static let threeMinutes = RefreshInterval(label: "3 min", seconds: 180)
    static let fiveMinutes = RefreshInterval(label: "5 min", seconds: 300)

    static let presets = [thirtySeconds, oneMinute, threeMinutes, fiveMinutes]
}

enum Preferences {
    private static let metricKey = "CodexUsageMenuBar.displayMetric"
    private static let densityKey = "CodexUsageMenuBar.displayDensity"
    private static let showResetCreditsKey = "CodexUsageMenuBar.showResetCredits"
    private static let showLowWarningKey = "CodexUsageMenuBar.showLowWarning"
    private static let refreshIntervalKey = "CodexUsageMenuBar.refreshIntervalSeconds"
    private static let customIntervalKey = "CodexUsageMenuBar.customIntervalSeconds"
    private static let languageKey = "CodexUsageMenuBar.language"

    static var displayMetric: DisplayMetric {
        get { DisplayMetric(rawValue: UserDefaults.standard.string(forKey: metricKey) ?? "") ?? .remaining }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: metricKey) }
    }

    static var displayDensity: DisplayDensity {
        get { DisplayDensity(rawValue: UserDefaults.standard.string(forKey: densityKey) ?? "") ?? .full }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: densityKey) }
    }

    static var showResetCredits: Bool {
        get { UserDefaults.standard.bool(forKey: showResetCreditsKey) }
        set { UserDefaults.standard.set(newValue, forKey: showResetCreditsKey) }
    }

    static var showLowWarning: Bool {
        get {
            if UserDefaults.standard.object(forKey: showLowWarningKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showLowWarningKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: showLowWarningKey) }
    }

    static var refreshIntervalSeconds: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: refreshIntervalKey)
            return stored >= 30 ? stored : RefreshInterval.fiveMinutes.seconds
        }
        set { UserDefaults.standard.set(max(30, min(3600, newValue)), forKey: refreshIntervalKey) }
    }

    static var customIntervalSeconds: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: customIntervalKey)
            return stored >= 30 ? stored : 30
        }
        set { UserDefaults.standard.set(max(30, min(3600, newValue)), forKey: customIntervalKey) }
    }

    static var language: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: languageKey) ?? "") ?? .english }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: languageKey) }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let client = CodexUsageClient()
    private var latestUsage: CodexUsage?
    private var lastError: Error?
    private var consecutiveFailures = 0
    private var timer: Timer?
    private var isRefreshing = false
    private let lowRemainingThreshold = 20.0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.button?.title = "Codex ..."
        refreshNow()
        scheduleTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func refreshNow() {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        rebuildMenu()

        Task {
            do {
                let usage = try await client.fetchUsage()
                await MainActor.run {
                    latestUsage = usage
                    lastError = nil
                    consecutiveFailures = 0
                    isRefreshing = false
                    updateStatusTitle()
                    rebuildMenu()
                    scheduleTimer()
                }
            } catch {
                await MainActor.run {
                    lastError = error
                    consecutiveFailures += 1
                    isRefreshing = false
                    if latestUsage == nil {
                        updateStatusTitle()
                    }
                    if consecutiveFailures >= 3 {
                        Preferences.refreshIntervalSeconds = RefreshInterval.fiveMinutes.seconds
                    }
                    rebuildMenu()
                    scheduleTimer()
                }
            }
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Preferences.refreshIntervalSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNow()
            }
        }
    }

    private func updateStatusTitle() {
        guard let button = statusItem.button else {
            return
        }

        if let usage = latestUsage {
            button.title = statusTitle(for: usage)
            return
        }

        if let error = lastError as? CodexUsageError {
            switch error {
            case .noAuthFile, .missingAccessToken:
                button.title = "Codex auth"
            case .authExpired:
                button.title = "Codex login"
            default:
                button.title = "Codex err"
            }
            return
        }

        button.title = lastError == nil ? "Codex ..." : "Codex err"
    }

    private func statusTitle(for usage: CodexUsage) -> String {
        StatusTitleFormatter(
            metric: Preferences.displayMetric,
            density: Preferences.displayDensity,
            showsResetCredits: Preferences.showResetCredits,
            showsLowUsageWarning: Preferences.showLowWarning,
            lowRemainingThreshold: lowRemainingThreshold
        ).title(for: usage)
    }

    private func detailPercent(_ value: Double?) -> String {
        guard let value else {
            return menuText.unknownTitle
        }
        return String(format: "%.1f%%", value)
    }

    private func rebuildMenu() {
        let text = menuText
        let menu = NSMenu()
        menu.addItem(disabledItem(text.appTitle))
        menu.addItem(NSMenuItem.separator())

        if let usage = latestUsage {
            menu.addItem(disabledItem("\(text.planTitle): \(usage.planType ?? text.unknownTitle)"))
            menu.addItem(disabledItem(windowDetail("5h", usage.fiveHour)))
            menu.addItem(disabledItem(windowDetail("Week", usage.weekly)))
            let resetCredits = usage.resetCreditsAvailable.map(String.init) ?? text.unavailableTitle
            menu.addItem(disabledItem("\(text.resetCreditsTitle): \(resetCredits)"))
            if lastError != nil {
                menu.addItem(disabledItem(text.staleStatusTitle))
            }
        } else {
            menu.addItem(disabledItem(text.noUsageDataTitle))
        }

        if let lastError {
            menu.addItem(disabledItem("\(text.errorTitle): \(lastError)"))
        }

        menu.addItem(NSMenuItem.separator())
        addDisplayMenu(to: menu)
        menu.addItem(NSMenuItem.separator())
        addRefreshMenu(to: menu)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(actionItem(text.refreshNowTitle, action: #selector(refreshNowAction)))
        menu.addItem(disabledItem("\(text.lastUpdatedTitle): \(lastUpdatedText())"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(actionItem(text.openCodexTitle, action: #selector(openCodex)))
        menu.addItem(actionItem(text.quitTitle, action: #selector(quit)))

        statusItem.menu = menu
        updateStatusTitle()
    }

    private func windowDetail(_ label: String, _ window: WindowUsage) -> String {
        let text = menuText
        let used = detailPercent(window.usedPercent)
        let remaining = detailPercent(window.remainingPercent)
        let reset = window.resetAt.map(shortDateTime) ?? text.unknownTitle
        var detail = "\(label): \(remaining) \(text.remainingDetailTitle), \(used) \(text.usedDetailTitle), \(text.resetsTitle) \(reset)"
        if Preferences.showLowWarning,
           let remainingPercent = window.remainingPercent,
           remainingPercent < lowRemainingThreshold {
            detail += " · \(text.lowRemainingTitle)"
        }
        return detail
    }

    private func addDisplayMenu(to menu: NSMenu) {
        let text = menuText
        menu.addItem(disabledItem(text.displayTitle))
        menu.addItem(submenuItem(
            "\(text.displayModeTitle): \(displayMetricTitle(Preferences.displayMetric))",
            items: [
                toggleItem(text.remainingTitle, checked: Preferences.displayMetric == .remaining, action: #selector(setRemaining)),
                toggleItem(text.usedTitle, checked: Preferences.displayMetric == .used, action: #selector(setUsed))
            ]
        ))
        menu.addItem(submenuItem(
            "\(text.formatTitle): \(displayDensityTitle(Preferences.displayDensity))",
            items: [
                toggleItem(text.fullFormatTitle, checked: Preferences.displayDensity == .full, action: #selector(setFullFormat)),
                toggleItem(text.compactFormatTitle, checked: Preferences.displayDensity == .compact, action: #selector(setCompactFormat))
            ]
        ))
        menu.addItem(submenuItem(
            "\(text.languageTitle): \(languageTitle(Preferences.language))",
            items: [
                toggleItem(text.englishTitle, checked: Preferences.language == .english, action: #selector(setEnglish)),
                toggleItem(text.chineseTitle, checked: Preferences.language == .chinese, action: #selector(setChinese))
            ]
        ))
        menu.addItem(toggleItem(text.showResetCreditsTitle, checked: Preferences.showResetCredits, action: #selector(toggleResetCredits)))
        menu.addItem(toggleItem(text.showLowUsageWarningTitle, checked: Preferences.showLowWarning, action: #selector(toggleLowWarning)))
    }

    private func addRefreshMenu(to menu: NSMenu) {
        let text = menuText
        menu.addItem(disabledItem(text.refreshTitle))
        for interval in RefreshInterval.presets {
            menu.addItem(toggleItem(
                interval.label,
                checked: Preferences.refreshIntervalSeconds == interval.seconds,
                action: #selector(setRefreshInterval(_:)),
                representedObject: interval.seconds
            ))
        }
        menu.addItem(toggleItem(
            "\(text.customTitle) (\(formatInterval(Preferences.customIntervalSeconds)))",
            checked: !RefreshInterval.presets.contains { $0.seconds == Preferences.refreshIntervalSeconds },
            action: #selector(setCustomInterval)
        ))
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func actionItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func toggleItem(
        _ title: String,
        checked: Bool,
        action: Selector,
        representedObject: Any? = nil
    ) -> NSMenuItem {
        let item = actionItem(title, action: action)
        item.state = checked ? .on : .off
        item.representedObject = representedObject
        return item
    }

    private func submenuItem(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        items.forEach(submenu.addItem)
        item.submenu = submenu
        return item
    }

    private func lastUpdatedText() -> String {
        if isRefreshing {
            return menuText.refreshingTitle
        }
        guard let fetchedAt = latestUsage?.fetchedAt else {
            return menuText.neverTitle
        }
        return shortDateTime(fetchedAt)
    }

    private func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatInterval(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        }
        let minutes = seconds / 60
        if minutes.rounded() == minutes {
            return "\(Int(minutes))min"
        }
        return "\(Int(seconds))s"
    }

    private var menuText: MenuText {
        MenuText(language: Preferences.language)
    }

    private func displayMetricTitle(_ metric: DisplayMetric) -> String {
        let text = menuText
        switch metric {
        case .remaining:
            return text.remainingTitle
        case .used:
            return text.usedTitle
        }
    }

    private func displayDensityTitle(_ density: DisplayDensity) -> String {
        let text = menuText
        switch density {
        case .full:
            return text.fullFormatTitle
        case .compact:
            return text.compactFormatTitle
        }
    }

    private func languageTitle(_ language: AppLanguage) -> String {
        let text = menuText
        switch language {
        case .english:
            return text.englishTitle
        case .chinese:
            return text.chineseTitle
        }
    }

    @objc private func refreshNowAction() {
        refreshNow()
    }

    @objc private func setRemaining() {
        Preferences.displayMetric = .remaining
        rebuildMenu()
    }

    @objc private func setUsed() {
        Preferences.displayMetric = .used
        rebuildMenu()
    }

    @objc private func setFullFormat() {
        Preferences.displayDensity = .full
        rebuildMenu()
    }

    @objc private func setCompactFormat() {
        Preferences.displayDensity = .compact
        rebuildMenu()
    }

    @objc private func setEnglish() {
        Preferences.language = .english
        rebuildMenu()
    }

    @objc private func setChinese() {
        Preferences.language = .chinese
        rebuildMenu()
    }

    @objc private func toggleResetCredits() {
        Preferences.showResetCredits.toggle()
        rebuildMenu()
    }

    @objc private func toggleLowWarning() {
        Preferences.showLowWarning.toggle()
        rebuildMenu()
    }

    @objc private func setRefreshInterval(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else {
            return
        }
        Preferences.refreshIntervalSeconds = seconds
        scheduleTimer()
        rebuildMenu()
    }

    @objc private func setCustomInterval() {
        let text = menuText
        let alert = NSAlert()
        alert.messageText = text.customRefreshIntervalTitle
        alert.informativeText = text.customRefreshIntervalMessage
        alert.addButton(withTitle: text.saveTitle)
        alert.addButton(withTitle: text.cancelTitle)

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        input.stringValue = String(Int(Preferences.customIntervalSeconds))
        alert.accessoryView = input

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let seconds = max(30, min(3600, TimeInterval(input.doubleValue)))
        Preferences.customIntervalSeconds = seconds
        Preferences.refreshIntervalSeconds = seconds
        scheduleTimer()
        rebuildMenu()
    }

    @objc private func openCodex() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Codex.app"))
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct CodexUsageMenuBarApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
