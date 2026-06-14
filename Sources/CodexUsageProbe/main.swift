import CodexUsageCore
import Foundation

struct CLIOptions {
    var json = false
    var raw = false
    var authPath: String?
}

enum OutputFormat {
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let resetFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

@main
struct CodexUsageProbe {
    static func main() async {
        do {
            let options = try parseOptions(CommandLine.arguments.dropFirst())
            let client = CodexUsageClient(authPath: options.authPath)

            if options.raw {
                let raw = try await client.fetchRawRedactedJSON()
                print(raw)
                return
            }

            let usage = try await client.fetchUsage()
            if options.json {
                let data = try OutputFormat.jsonEncoder.encode(usage)
                print(String(decoding: data, as: UTF8.self))
            } else {
                printHumanReadable(usage)
            }
        } catch {
            fputs("codex-usage-probe: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func parseOptions(_ args: ArraySlice<String>) throws -> CLIOptions {
        var options = CLIOptions()
        var iterator = args.makeIterator()

        while let arg = iterator.next() {
            switch arg {
            case "--json":
                options.json = true
            case "--raw":
                options.raw = true
            case "--auth":
                guard let path = iterator.next() else {
                    throw CodexUsageError.parseError("missing value after --auth")
                }
                options.authPath = path
            case "-h", "--help":
                printHelp()
                Foundation.exit(0)
            default:
                throw CodexUsageError.parseError("unknown argument: \(arg)")
            }
        }

        return options
    }

    private static func printHelp() {
        print("""
        Usage: codex-usage-probe [--json] [--raw] [--auth PATH]

        Reads Codex ChatGPT auth from ~/.codex/auth.json, calls the Codex usage endpoint,
        and prints 5-hour plus weekly rate-limit windows.

        Options:
          --json       Print parsed usage as JSON.
          --raw        Print a redacted raw endpoint response.
          --auth PATH  Use a custom Codex auth.json path.
          -h, --help   Show this help.
        """)
    }

    private static func printHumanReadable(_ usage: CodexUsage) {
        let plan = usage.planType ?? "unknown"
        print("Codex usage")
        print("Plan: \(plan)")
        if let resetCredits = usage.resetCreditsAvailable {
            print("Reset credits: \(resetCredits)")
        }
        print("Fetched: \(OutputFormat.resetFormatter.string(from: usage.fetchedAt))")
        print("")
        printWindow("5h", usage.fiveHour)
        printWindow("Week", usage.weekly)
    }

    private static func printWindow(_ label: String, _ window: WindowUsage) {
        let used = window.usedPercent.map { formatPercent($0) } ?? "unknown"
        let remaining = window.remainingPercent.map { formatPercent($0) } ?? "unknown"
        let reset = window.resetAt.map { OutputFormat.resetFormatter.string(from: $0) } ?? "unknown"

        print("\(label): used \(used), remaining \(remaining), resets \(reset)")
    }

    private static func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
}
