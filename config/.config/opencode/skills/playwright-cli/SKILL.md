---
name: playwright-cli
description: 使用 Playwright CLI 检查渲染后的网页、执行页面交互、截图或诊断 UI 与网络问题时使用。不用于无需浏览器的静态内容读取、其他浏览器工具或 Playwright 安装更新。
---

# playwright-cli

## 适用场景

- 浏览网页、检查渲染结果、执行 UI 操作或验证页面行为
- 读取无障碍快照、控制台日志、网络请求或截图
- 使用默认 storage state 启动独立浏览器完成受认证的网页分析

## 核心原则

1. **当前 Agent 直接调用** — 通过 Shell 执行 `playwright-cli`，不使用 Playwright MCP，也不为浏览操作创建子代理。
2. **按需启动、及时关闭** — 以任务专属 Session 启动独立 Headless 浏览器；完成后仅执行该 Session 的 `close`。不得执行 `close-all` 或 `kill-all`，以免影响其他任务。
3. **先快照、后交互** — 交互前执行 `snapshot` 或 `find` 获取当前元素引用；页面导航、提交或弹窗后重新获取引用。
4. **控制上下文与输出** — 优先 `find`、部分 `snapshot <target>` 或 `snapshot --depth <n>`；视觉核验需要时才截图。产物使用运行环境指定的临时根目录，未提供时使用系统临时目录，并创建任务唯一子目录，以下记为 `<证据目录>`。
5. **浏览器状态最小化** — 默认通过全局 Playwright CLI 配置加载 storage state，启动隔离浏览器；不读取或输出认证内容，不擅自保存、替换认证状态或修改网络路由。显式授权的状态保存和加载仅按下方“登录态与持久化”执行。

## 工作流程

- [ ] 选择唯一、任务相关的 Session 名，例如 `pw-order-review`；并发任务不得共用 Session 名。
- [ ] 启动浏览器：`playwright-cli -s=<session> open --idle-timeout=600000 <URL>`。全局配置会自动加载 storage state。
- [ ] 使用 `snapshot` 或 `find` 了解页面，必要时再导航、点击、输入或截屏。
- [ ] 报告 URL、关键页面状态和产物路径；不暴露 Cookie、授权头或页面中的敏感信息。
- [ ] 完成后执行 `playwright-cli -s=<session> close`。

## 常用命令

```bash
# 启动独立 Headless 浏览器（自动加载默认 storage state）
playwright-cli -s=pw-order-review open --idle-timeout=600000 https://example.com
playwright-cli -s=pw-order-review snapshot --depth 6
playwright-cli -s=pw-order-review find "提交"

# 基于最新快照中的元素引用交互
playwright-cli -s=pw-order-review click e12
playwright-cli -s=pw-order-review fill e8 "查询条件"
playwright-cli -s=pw-order-review press Enter

# 诊断与视觉核验
playwright-cli -s=pw-order-review console error
playwright-cli -s=pw-order-review requests
playwright-cli -s=pw-order-review screenshot --full-page --filename <证据目录>/order-review.png

# 完成后关闭本任务的浏览器
playwright-cli -s=pw-order-review close
```

## 登录态与持久化

- 全局配置 `~/.playwright/cli.config.json` 由安装脚本生成，默认加载当前用户的 `~/.local/state/opencode/playwright/storage-state.json`（配置内为展开后的绝对路径）；不得读取或展示其内容。
- 默认使用内存态的独立 Headless 浏览器；空闲十分钟后自动关闭。需要不同超时时间时使用 `open --idle-timeout=<毫秒>`，传 `0` 可禁用自动关闭。
- 只有用户明确要求保存或替换认证状态时，才使用 `state-save <文件>` 或 `state-load <文件>`；文件放在当前用户的 `~/.local/state/opencode/playwright/`，Shell 命令中使用 `"$HOME/.local/state/opencode/playwright/"` 展开路径，不得在回复中展示内容。

## 禁止行为

- ❌ 使用 `@playwright/mcp`、Playwright MCP 工具或 `playwright-cli install`
- ❌ 不带命名 Session 启动浏览器，或让并发任务共用 Session
- ❌ 直接猜测元素引用；导航、提交、弹窗后继续复用旧引用
- ❌ 执行 `close-all`、`kill-all`、`delete-data`，或擅自修改 Cookie、Storage、网络 Mock
- ❌ 未经明确授权保存认证状态；展示或泄露 Cookie、授权头、storage state、密码或页面敏感内容
