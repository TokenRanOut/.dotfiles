---
name: obsidian-vault
description: >
  Use this skill when the user wants to search, read, or modify notes and metadata in an Obsidian vault, explicitly named or established by context. Includes vault daily notes, tasks, links, and templates. Do NOT use for generic notes, links, tags, Markdown files outside a confirmed vault, other note apps, or plugin/theme/sync/export management. 适用：明确或由上下文确认的 Obsidian vault 笔记及元数据操作；不因“笔记、链接、标签”等泛词触发，不适用其他笔记应用及插件、主题、同步、导出管理。
tags: obsidian,cli,vault,search,write,notes
---

# obsidian-vault

优先用 Obsidian CLI 操作已确认的 vault；CLI 不支持的局部内容编辑可用文件工具。

## 执行路由

1. 确认目标 vault 和操作范围。路径不明先 `search`；文件操作显式指定精确 `path`，多 vault 指定 `vault`。文件工具使用已核实的 vault 根目录及目标路径，不依赖默认 active file。
2. 根据任务选择路线：
   - **搜索 / 阅读**：`search` / `search:context` → `read`，需要结构时用 `outline`。
   - **新建**：检查目标是否已存在 → `templates` 查可用模板 → `create`；避免意外覆盖。
   - **追加 / 更新**：先 `read` + `outline` 定位标题或段落；追加用 `append` / `prepend`，局部更新用文件工具，整篇重写才用 `create overwrite`。不要把结构性更新盲目追加到末尾。
   - **元数据 / 任务 / 链接**：明确单文件或全库范围，再选属性、任务或链接命令。
   - **日记 / 模板**：日记先 `daily:path` 确认目标；模板预览用 `template:read`，插入前 `open path=...` 激活并核实目标。
   - **删除 / 移动 / 重命名**：先核实精确路径，删除默认走回收站。
3. 写后用 `read` / `property:read` 复读受影响内容；删除检查原路径不存在，移动或重命名检查新旧路径。检查 frontmatter、链接及上下文衔接。

## 安全边界

- **Plan Mode 只读**：只读取和分析 vault；创建、追加、覆盖、移动、删除、属性或任务修改、模板插入、历史恢复等写操作均禁止，也不得通过文件工具、脚本或其他 Agent 绕过。只给出拟改路径、位置、内容，切换模式后才能落盘；写权限被拒绝后停止。
- 禁止 `plugin:*`、`theme:*`、`snippet:*`、`publish:*`、`reload`、`restart`、`eval`、`dev:*`、`devtools`；同步仅允许 `sync:status`。
- 命令目录不代表权限；`history:restore` 等恢复操作属于写入，命令面板不得绕过上述边界。

## 按需参考

执行具体 CLI 操作前，按所需章节读取 [cli-guide.md](references/cli-guide.md)：命令目录、参数格式、Gotchas 和详细示例。含 shell 特殊字符、模板变量、批量操作或 active-file 命令时，先读其中 Gotchas。参数以本机 `obsidian help <command>` 为准。
