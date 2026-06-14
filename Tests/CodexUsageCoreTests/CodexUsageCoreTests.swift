import XCTest
@testable import CodexUsageCore

final class CodexUsageCoreTests: XCTestCase {
    func testParserReadsRateLimitWindowsAndResetCredits() throws {
        let json = """
        {
          "plan_type": "plus",
          "rate_limit": {
            "primary_window": {
              "limit_window_seconds": 18000,
              "reset_at": 1781424525,
              "used_percent": 37
            },
            "secondary_window": {
              "limit_window_seconds": 604800,
              "reset_at": 1781919199,
              "used_percent": 12
            }
          },
          "rate_limit_reset_credits": {
            "available_count": 1
          }
        }
        """

        let fetchedAt = Date(timeIntervalSince1970: 1_781_400_000)
        let usage = try CodexUsageParser.parse(Data(json.utf8), fetchedAt: fetchedAt)

        XCTAssertEqual(usage.planType, "plus")
        XCTAssertEqual(usage.resetCreditsAvailable, 1)
        XCTAssertEqual(usage.fiveHour.usedPercent, 37)
        XCTAssertEqual(usage.fiveHour.remainingPercent, 63)
        XCTAssertEqual(usage.fiveHour.resetAt, Date(timeIntervalSince1970: 1_781_424_525))
        XCTAssertEqual(usage.weekly.usedPercent, 12)
        XCTAssertEqual(usage.weekly.remainingPercent, 88)
        XCTAssertEqual(usage.weekly.resetAt, Date(timeIntervalSince1970: 1_781_919_199))
        XCTAssertEqual(usage.fetchedAt, fetchedAt)
    }

    func testHttpErrorDescriptionDoesNotExposeResponseBody() {
        let error = CodexUsageError.httpStatus(500, #"{"email":"person@example.com","user_id":"user-secret"}"#)

        XCTAssertEqual(error.description, "HTTP 500")
        XCTAssertFalse(error.description.contains("person@example.com"))
        XCTAssertFalse(error.description.contains("user-secret"))
    }

    func testStatusTitleDefaultsToRemainingFullFormat() {
        let usage = sampleUsage(fiveHourRemaining: 61, weeklyRemaining: 88, resetCredits: 1)
        let formatter = StatusTitleFormatter(
            metric: .remaining,
            density: .full,
            showsResetCredits: false,
            showsLowUsageWarning: true
        )

        XCTAssertEqual(formatter.title(for: usage), "5h 61% · W 88%")
    }

    func testStatusTitleCanShowUsedAndResetCredits() {
        let usage = sampleUsage(fiveHourRemaining: 61, weeklyRemaining: 88, resetCredits: 1)
        let formatter = StatusTitleFormatter(
            metric: .used,
            density: .full,
            showsResetCredits: true,
            showsLowUsageWarning: true
        )

        XCTAssertEqual(formatter.title(for: usage), "5h 39% · W 12% · R1")
    }

    func testStatusTitleMarksOnlyLowRemainingWindowEvenWhenDisplayingUsed() {
        let usage = sampleUsage(fiveHourRemaining: 18, weeklyRemaining: 88, resetCredits: nil)
        let formatter = StatusTitleFormatter(
            metric: .used,
            density: .full,
            showsResetCredits: false,
            showsLowUsageWarning: true
        )

        XCTAssertEqual(formatter.title(for: usage), "!5h 82% · W 12%")
    }

    func testCompactStatusTitleSupportsResetCreditsAndWarnings() {
        let usage = sampleUsage(fiveHourRemaining: 18, weeklyRemaining: 9, resetCredits: 2)
        let formatter = StatusTitleFormatter(
            metric: .remaining,
            density: .compact,
            showsResetCredits: true,
            showsLowUsageWarning: true
        )

        XCTAssertEqual(formatter.title(for: usage), "!18/!9 R2")
    }

    func testMenuTextSupportsEnglishAndChineseLabels() {
        XCTAssertEqual(MenuText(language: .english).displayModeTitle, "Usage Display")
        XCTAssertEqual(MenuText(language: .english).remainingTitle, "Remaining")
        XCTAssertEqual(MenuText(language: .english).usedTitle, "Used")
        XCTAssertEqual(MenuText(language: .english).fullFormatTitle, "Full")
        XCTAssertEqual(MenuText(language: .english).compactFormatTitle, "Compact")

        XCTAssertEqual(MenuText(language: .chinese).displayModeTitle, "用量显示")
        XCTAssertEqual(MenuText(language: .chinese).remainingTitle, "剩余")
        XCTAssertEqual(MenuText(language: .chinese).usedTitle, "已用")
        XCTAssertEqual(MenuText(language: .chinese).fullFormatTitle, "完整")
        XCTAssertEqual(MenuText(language: .chinese).compactFormatTitle, "简单")
    }

    func testMenuTextKeepsStatusTitleStableAcrossLanguages() {
        let usage = sampleUsage(fiveHourRemaining: 61, weeklyRemaining: 88, resetCredits: 1)
        let formatter = StatusTitleFormatter(
            metric: .remaining,
            density: .full,
            showsResetCredits: true,
            showsLowUsageWarning: true
        )

        XCTAssertEqual(formatter.title(for: usage), "5h 61% · W 88% · R1")
    }

    private func sampleUsage(
        fiveHourRemaining: Double,
        weeklyRemaining: Double,
        resetCredits: Int?
    ) -> CodexUsage {
        CodexUsage(
            planType: "plus",
            resetCreditsAvailable: resetCredits,
            fiveHour: WindowUsage(
                usedPercent: 100 - fiveHourRemaining,
                remainingPercent: fiveHourRemaining,
                resetAt: nil
            ),
            weekly: WindowUsage(
                usedPercent: 100 - weeklyRemaining,
                remainingPercent: weeklyRemaining,
                resetAt: nil
            ),
            fetchedAt: Date(timeIntervalSince1970: 1_781_400_000)
        )
    }
}
