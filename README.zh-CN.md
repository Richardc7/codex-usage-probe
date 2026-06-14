<div align="center">

# Codex Usage Probe

轻量级 macOS 菜单栏 Codex 用量监控工具。

[![Swift](https://img.shields.io/badge/Swift-6-orange.svg)](https://www.swift.org/)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-8%20passing-brightgreen.svg)](#开发)

[English README](README.md) · [许可证](LICENSE)

</div>

## 概览

Codex Usage Probe 是一个小型原生 macOS 工具，用于在状态栏显示 Codex 使用额度。项目同时包含菜单栏 App 和 Swift 命令行探针，方便日常查看、调试和自动化。

应用会读取本机 `~/.codex/auth.json` 中的 Codex ChatGPT 登录凭据，请求 Codex 用量接口，并显示 5 小时窗口和周窗口的用量。

## 功能亮点

| 分类 | 说明 |
| --- | --- |
| 菜单栏 App | 原生 AppKit 状态栏应用，无 Dock 图标 |
| 用量窗口 | 5 小时额度和周额度 |
| 显示模式 | 剩余百分比或已用百分比 |
| 显示格式 | 完整格式和简单格式 |
| 重置次数 | 可选 `R1` 样式指示 |
| 刷新 | 手动、`30s`、`1min`、`3min`、`5min`，或自定义 `30-3600s` |
| 语言 | 英文和中文菜单 |
| CLI | 普通文本、JSON、脱敏原始接口输出 |

## 状态栏示例

```text
5h 61% · W 88%
5h 61% · W 88% · R1
61/88
!5h 18% · W 88%
```

当任一用量窗口剩余低于 20% 时，会显示低额度提示。该提示可以在菜单中关闭。

## 环境要求

- macOS 13 或更高版本
- 带 Swift 6 支持的 Xcode Command Line Tools
- 已使用 ChatGPT 账号登录 Codex

如果还没有登录 Codex：

```bash
codex login
```

## 快速开始

克隆仓库：

```bash
git clone https://github.com/Richardc7/codex-usage-probe.git
cd codex-usage-probe
```

构建并打开菜单栏 App：

```bash
./build-app.sh
open .build/CodexUsage.app
```

生成的 App 位于：

```text
.build/CodexUsage.app
```

## CLI 用法

普通文本输出：

```bash
swift run codex-usage-probe
```

JSON 输出：

```bash
swift run codex-usage-probe --json
```

脱敏原始接口响应：

```bash
swift run codex-usage-probe --raw
```

指定自定义 auth 文件：

```bash
swift run codex-usage-probe --auth /path/to/auth.json
```

## 菜单选项

| 菜单 | 选项 |
| --- | --- |
| 用量显示 | 剩余、已用 |
| 格式 | 完整、简单 |
| 语言 | 英文、中文 |
| 刷新 | 30 sec、1 min、3 min、5 min、自定义 |
| 开关 | 显示重置次数、显示低用量提示 |

## 开发

运行测试：

```bash
swift test
```

构建两个 product：

```bash
swift build --product codex-usage-probe
swift build --product CodexUsageMenuBar
```

构建 release App bundle：

```bash
./build-app.sh
```

## 项目结构

```text
Sources/
  CodexUsageCore/       共享用量客户端、解析器、格式化器和菜单文案
  CodexUsageProbe/      CLI 入口
  CodexUsageMenuBar/    AppKit 菜单栏应用
Tests/
  CodexUsageCoreTests/  解析、格式化、脱敏和本地化测试
```

## 隐私说明

Codex Usage Probe 会在本机读取 `~/.codex/auth.json`，以获取 Codex ChatGPT access token。该 token 只用于向 ChatGPT 请求 Codex 用量数据，不会被打印、另存或发送给任何第三方服务。

`--raw` 命令会对 `email`、`account_id`、`user_id` 等账号标识做脱敏处理。

## 重要说明

本项目依赖一个未公开的 ChatGPT/Codex 后端接口：

```text
https://chatgpt.com/backend-api/wham/usage
```

由于该接口不是公开 API，其字段结构、可用性或认证行为都可能在没有通知的情况下发生变化。

## 许可证

MIT。详见 [LICENSE](LICENSE)。
