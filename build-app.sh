#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/.build/CodexUsage.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT"
swift build -c release --product CodexUsageMenuBar

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$ROOT/.build/release/CodexUsageMenuBar" "$MACOS_DIR/CodexUsageMenuBar"
cp "$ROOT/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/CodexUsageMenuBar"

echo "Built $APP_DIR"
