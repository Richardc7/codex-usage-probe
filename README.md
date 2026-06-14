# Codex Usage Probe

[中文说明](README.zh-CN.md)

Codex Usage Probe is a lightweight macOS menu bar app and Swift command-line probe for viewing your Codex usage limits.

It reads your local Codex ChatGPT auth token from `~/.codex/auth.json`, calls the same Codex usage endpoint used by similar community tools, and shows the 5-hour and weekly usage windows in the macOS status bar.

## Features

- macOS menu bar app with no Dock icon
- Shows 5-hour and weekly Codex usage
- Toggle between remaining and used percentages
- Full and compact status bar formats
- Optional reset-credit indicator, for example `R1`
- Low-usage warning when a window has less than 20% remaining
- Manual refresh and configurable refresh intervals: `30s`, `1min`, `3min`, `5min`, or custom `30-3600s`
- English and Chinese menu language options
- Swift CLI probe for debugging and automation
- Redacted raw JSON output for endpoint inspection

## Status Bar Examples

```text
5h 61% · W 88%
5h 61% · W 88% · R1
61/88
!5h 18% · W 88%
```

## Requirements

- macOS 13 or later
- Xcode command line tools with Swift 6 support
- Codex authenticated with ChatGPT credentials

If you have not signed in to Codex yet:

```bash
codex login
```

## Build the Menu Bar App

```bash
./build-app.sh
open .build/CodexUsage.app
```

The generated app bundle is:

```text
.build/CodexUsage.app
```

## Run the CLI Probe

Human-readable output:

```bash
swift run codex-usage-probe
```

JSON output:

```bash
swift run codex-usage-probe --json
```

Redacted raw endpoint response:

```bash
swift run codex-usage-probe --raw
```

Use a custom auth file:

```bash
swift run codex-usage-probe --auth /path/to/auth.json
```

## Development

Run tests:

```bash
swift test
```

Build both products:

```bash
swift build --product codex-usage-probe
swift build --product CodexUsageMenuBar
```

## Project Structure

```text
Sources/
  CodexUsageCore/       Shared usage client, parser, formatter, and menu text
  CodexUsageProbe/      CLI entry point
  CodexUsageMenuBar/    AppKit menu bar app
Tests/
  CodexUsageCoreTests/  Parser, formatting, redaction, and localization tests
```

## Privacy

The app reads `~/.codex/auth.json` locally to get your Codex ChatGPT access token. The token is used only to call the Codex usage endpoint. It is not printed, stored elsewhere, or sent to any third-party service.

The `--raw` command redacts account identifiers such as `email`, `account_id`, and `user_id`.

## Important Caveat

This project depends on an undocumented ChatGPT/Codex backend endpoint:

```text
https://chatgpt.com/backend-api/wham/usage
```

Because the endpoint is not a public API, its schema, availability, or authentication behavior may change without notice.

## License

MIT. See [LICENSE](LICENSE).
