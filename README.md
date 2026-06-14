<div align="center">

# Codex Usage Probe

Lightweight macOS menu bar usage monitor for Codex.

[![Swift](https://img.shields.io/badge/Swift-6-orange.svg)](https://www.swift.org/)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-8%20passing-brightgreen.svg)](#development)

[中文说明](README.zh-CN.md) · [License](LICENSE)

</div>

## Overview

Codex Usage Probe is a small native macOS utility that shows your Codex usage in the status bar. It includes both a menu bar app and a Swift command-line probe for debugging or automation.

The app reads your local Codex ChatGPT auth token from `~/.codex/auth.json`, calls the Codex usage endpoint, and displays both the 5-hour and weekly usage windows.

## Highlights

| Area | Details |
| --- | --- |
| Menu bar app | Native AppKit status item, no Dock icon |
| Usage windows | 5-hour and weekly Codex limits |
| Display modes | Remaining or used percentage |
| Layouts | Full format and compact format |
| Reset credits | Optional `R1` style indicator |
| Refresh | Manual, `30s`, `1min`, `3min`, `5min`, or custom `30-3600s` |
| Language | English and Chinese menu text |
| CLI | Human-readable, JSON, and redacted raw endpoint output |

## Status Bar Examples

```text
5h 61% · W 88%
5h 61% · W 88% · R1
61/88
!5h 18% · W 88%
```

Low-usage warnings are shown when any usage window has less than 20% remaining. Warnings can be disabled from the menu.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools with Swift 6 support
- Codex signed in with ChatGPT credentials

Sign in to Codex first if needed:

```bash
codex login
```

## Quick Start

Clone the repository:

```bash
git clone https://github.com/Richardc7/codex-usage-probe.git
cd codex-usage-probe
```

Build and open the menu bar app:

```bash
./build-app.sh
open .build/CodexUsage.app
```

The generated app bundle is:

```text
.build/CodexUsage.app
```

## CLI Usage

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

## Menu Options

| Menu | Options |
| --- | --- |
| Usage Display | Remaining, Used |
| Format | Full, Compact |
| Language | English, Chinese |
| Refresh | 30 sec, 1 min, 3 min, 5 min, Custom |
| Toggles | Show reset credits, show low-usage warning |

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

Build the release app bundle:

```bash
./build-app.sh
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

Codex Usage Probe reads `~/.codex/auth.json` locally to get your Codex ChatGPT access token. The token is used only to request your Codex usage data from ChatGPT. It is not printed, stored elsewhere, or sent to any third-party service.

The `--raw` command redacts account identifiers such as `email`, `account_id`, and `user_id`.

## Important Caveat

This project depends on an undocumented ChatGPT/Codex backend endpoint:

```text
https://chatgpt.com/backend-api/wham/usage
```

Because this is not a public API, the endpoint schema, availability, or authentication behavior may change without notice.

## License

MIT. See [LICENSE](LICENSE).
