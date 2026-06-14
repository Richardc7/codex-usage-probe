# Codex Usage Probe

[English README](README.md)

Codex Usage Probe 是一个轻量级 macOS 菜单栏应用，同时也提供 Swift 命令行探针，用来查看 Codex 使用额度。

它会读取本机 `~/.codex/auth.json` 中的 Codex ChatGPT 登录凭据，请求 Codex 用量接口，并在 macOS 状态栏显示 5 小时窗口和周窗口的用量。

## 功能

- macOS 菜单栏应用，无 Dock 图标
- 显示 Codex 5 小时额度和周额度
- 可切换显示剩余百分比或已用百分比
- 支持完整和简单两种状态栏格式
- 可选显示重置次数，例如 `R1`
- 当任一额度窗口剩余低于 20% 时显示低额度提示
- 支持手动刷新和刷新间隔设置：`30s`、`1min`、`3min`、`5min`，或自定义 `30-3600s`
- 菜单支持英文和中文
- 提供 Swift CLI，方便调试和自动化
- 支持脱敏原始 JSON 输出，方便检查接口结构

## 状态栏示例

```text
5h 61% · W 88%
5h 61% · W 88% · R1
61/88
!5h 18% · W 88%
```

## 环境要求

- macOS 13 或更高版本
- 安装带 Swift 6 支持的 Xcode Command Line Tools
- 已使用 ChatGPT 账号登录 Codex

如果还没有登录 Codex：

```bash
codex login
```

## 构建菜单栏 App

```bash
./build-app.sh
open .build/CodexUsage.app
```

生成的 App 位于：

```text
.build/CodexUsage.app
```

## 运行命令行探针

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

应用会在本机读取 `~/.codex/auth.json`，以获取 Codex ChatGPT access token。该 token 只用于请求 Codex 用量接口，不会被打印、另存或发送给任何第三方服务。

`--raw` 命令会对 `email`、`account_id`、`user_id` 等账号标识做脱敏处理。

## 重要说明

本项目依赖一个未公开的 ChatGPT/Codex 后端接口：

```text
https://chatgpt.com/backend-api/wham/usage
```

由于该接口不是公开 API，其字段结构、可用性或认证行为都可能在没有通知的情况下发生变化。

## 许可证

MIT。详见 [LICENSE](LICENSE)。
