# Script Design Reference

## 何时读取本文件

当需要为 skill 创建 `scripts/` 下的可执行脚本时读取。

## 一站式命令（无 `scripts/` 目录）

当已有工具就能完成任务时，直接在 SKILL.md 中引用命令，无需打包脚本：

```bash
# Python 生态
uvx ruff@0.8.0 check .
uvx black@24.10.0 .

# Node.js 生态（npx 随 Node.js 发货）
npx eslint@9 --fix .
npx create-vite@6 my-app

# Bun 生态
bunx eslint@9 --fix .

# Deno 生态
deno run npm:create-vite@6 my-app
deno run --allow-read npm:eslint@9 -- --fix .

# Go 生态
go run golang.org/x/tools/cmd/goimports@v0.28.0 .
```

- **必须固定版本**（`@0.8.0` 而非 `@latest`）
- **声明前置依赖**（如 "需要 Node.js 18+"）

## 自包含脚本（语言模板）

### Python (PEP 723)

```python
# /// script
# dependencies = [
#   "beautifulsoup4>=4.12,<5",
# ]
# requires-python = ">=3.10"
# ///

from bs4 import BeautifulSoup

html = '<html><body><h1>Welcome</h1><p class="info">This is a test.</p></body></html>'
print(BeautifulSoup(html, "html.parser").select_one("p.info").get_text())
```

运行：`uv run scripts/extract.py`

- 用 PEP 508 规格固定版本：`"beautifulsoup4>=4.12,<5"`
- 用 `requires-python` 限制 Python 版本
- 用 `uv lock --script` 生成 lockfile 获得完整可复现性

### Deno

```typescript
#!/usr/bin/env -S deno run

import * as cheerio from "npm:cheerio@1.0.0";

const html = `<html><body><h1>Welcome</h1><p class="info">This is a test.</p></body></html>`;
const $ = cheerio.load(html);
console.log($("p.info").text());
```

运行：`deno run scripts/extract.ts`

- `npm:` 前缀用于 npm 包，`jsr:` 用于 Deno 原生包
- 版本号支持 semver：`@1.0.0`（精确）、`@^1.0.0`（兼容）
- 依赖全局缓存，用 `--reload` 强制重新获取

### Bun

```typescript
#!/usr/bin/env bun

import * as cheerio from "cheerio@1.0.0";

const html = `<html><body><h1>Welcome</h1><p class="info">This is a test.</p></body></html>`;
const $ = cheerio.load(html);
console.log($("p.info").text());
```

运行：`bun run scripts/extract.ts`

- 无需 `package.json` 或 `node_modules`，TypeScript 原生支持
- 如果目录树中任何位置存在 `node_modules`，自动安装被禁用，退回到标准 Node.js 解析

### Ruby

```ruby
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'nokogiri', '~> 1.16'
end

html = '<html><body><h1>Welcome</h1><p class="info">This is a test.</p></body></html>'
doc = Nokogiri::HTML(html)
puts doc.at_css('p.info').text
```

运行：`ruby scripts/extract.rb`

- 显式固定版本（`'~> 1.16'`），因为没有 lockfile
- 注意：工作目录中的 `Gemfile` 或 `BUNDLE_GEMFILE` 环境变量可能干扰

## Agent 友好设计原则

### 1. 禁止交互式提示

agent 操作在非交互 shell 中 —— 无法响应 TTY prompt、密码对话框或确认菜单。阻塞在交互输入上的脚本会永久挂起。

```bash
# Bad — 挂起等待输入
$ python scripts/deploy.py
Target environment: _

# Good — 明确报错并指引
$ python scripts/deploy.py
Error: --env is required. Options: development, staging, production.
Usage: python scripts/deploy.py --env staging --tag v1.2.3
```

### 2. --help 输出规范

`--help` 是 agent 了解脚本接口的主要途径：

```
Usage: scripts/process.py [OPTIONS] INPUT_FILE

Process input data and produce a summary report.

Options:
  --format FORMAT    Output format: json, csv, table (default: json)
  --output FILE      Write output to FILE instead of stdout
  --verbose          Print progress to stderr

Examples:
  scripts/process.py data.csv
  scripts/process.py --format csv --output report.csv data.csv
```

保持简洁 —— help 输出会进入 agent 的上下文窗口。

### 3. 错误信息要有用

说清什么错了、期望什么、如何修正：

```
Error: --format must be one of: json, csv, table.
       Received: "xml"
```

而非：`Error: invalid input`

### 4. stdout=数据, stderr=诊断

```python
# 结构化数据 → stdout
print(json.dumps(result))

# 进度、警告 → stderr
print("Processing row 10 of 100...", file=sys.stderr)
```

这样 agent 可以捕获干净的、可解析的输出，同时仍能访问诊断信息。

### 5. 幂等性

agent 可能重试命令。"不存在则创建" 优于 "创建，重名则失败"。

### 6. 输入约束

拒绝模糊输入并给出明确错误，而非猜测意图。尽量使用枚举和封闭集合。

### 7. --dry-run 支持

对破坏性或状态变更操作，提供 `--dry-run` 让 agent 预览将发生什么。

### 8. 有意义的退出码

不同失败类型用不同退出码，在 `--help` 中注明：

```
Exit codes:
  0 - Success
  1 - General error
  2 - Input file not found
  3 - Invalid arguments
  4 - Authentication failed
```

### 9. 安全默认值

考虑破坏性操作是否需要显式确认标志（`--confirm`、`--force`）。

### 10. 可预测的输出大小

许多 agent harness 会自动截断超过阈值（如 10K-30K 字符）的工具输出，可能丢失关键信息。如果脚本可能产生大量输出：

- 默认输出摘要或合理限制
- 支持 `--offset` 让 agent 翻页
- 支持 `--output FILE` 写文件，或 `--output -` 显式输出到 stdout
