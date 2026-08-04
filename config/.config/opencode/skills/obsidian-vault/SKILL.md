---
name: obsidian-vault
description: >
  Use this skill when the user asks to search, read, create, update, or delete markdown notes in an
  Obsidian vault — including querying tags, properties, tasks, daily notes, backlinks, links,
  orphans, templates, and bookmarks. Trigger even if the user says "笔记", "知识库", "第二大脑",
  "日记", "标签", "待办", "引用", "链接", "backlinks", "孤立笔记", "vault", "wikilink",
  or describes note-taking without mentioning "obsidian". 适用：搜索/阅读/创建/更新/删除 Obsidian
  笔记、查标签/属性/任务/日记、分析链接关系、模板和书签操作。优先使用 obsidian CLI，CLI 不支持的操作
  可使用文件系统工具。Do NOT use for: managing plugins/themes/sync/export, or non-Obsidian note apps
  (Notion, Bear, Apple Notes). 不适用：插件/主题/同步/导出管理、非 Obsidian 笔记应用。
tags: obsidian,cli,vault,search,write,notes
---

# obsidian-vault

通过 `obsidian` CLI 与 Obsidian vault 交互，搜索文档、读写笔记、管理元数据。具体命令参数用 `obsidian --help` 或 `obsidian help <command>` 查询，不在此文件中展开。

## 适用场景

- 搜索文档 / 阅读笔记 / 查看大纲与元数据
- 创建笔记 / 追加或前置内容 / 更新或删除笔记 / 移动或重命名
- 查询标签、属性、任务、链接关系
- 日记读写
- 模板插入、书签管理、历史版本查看、数据库表查询
- 模板读取、从模板创建笔记

## 核心原则

1. **搜索优先** — 不确定文件位置时先 `search`，找到路径后再 `read`；写操作前先搜索确认文件不存在
2. **优先 CLI，允许 fallback** — 优先使用 obsidian CLI 操作 vault；CLI 不支持的操作（如更新已有笔记内容）可使用文件系统工具（edit、write）作为补充。允许 `delete` 操作。
3. **不碰插件主题** — 禁止 `plugin:*`、`theme:*`、`snippet:*`；`sync:*` 仅允许 `sync:status`
4. **不执行危险操作** — 禁止 `reload`、`restart`、`eval`、`dev:*`、`devtools`
5. **写后验证** — 任何写操作后，用 `read` 或 `property:read` 确认内容落盘正确
6. **标签与链接优先** — 创建或更新笔记（含日记）时，优先设置 tags 并添加 Markdown 链接（`[显示文本](相对路径.md)` 格式）。tags 位于文档开头 YAML frontmatter（通过 `property:set`），链接位于内容末尾。
7. **Plan Mode 只读** — 当前处于 Plan Mode 时，Vault 只允许读取和分析。允许 `search`、`search:context`、`read`、`outline`、`tags`、`property:read`、`tasks`、`backlinks`、`links`、`history:read`、`diff` 等只读操作；禁止 `create`、`append`、`prepend`、`move`、`rename`、`delete`、`property:set`、`property:remove`、`task`、`template:insert`、`history:restore`、`base:create` 等写操作。不得通过 Bash、PTY、文件编辑工具、脚本或其他 Agent 绕过限制。写操作被拒绝后必须立即停止；用户要求修改笔记时，只输出拟修改路径、位置和内容，退出 Plan Mode 后才能落盘。

## 工作流程

进度：
- [ ] Step 1: 确定意图，选择路径：
  - 读写笔记 → 走「笔记操作」
  - 管理标签/属性/任务 → 走「元数据管理」
  - 分析链接关系 → 走「链接分析」
  - 使用模板 → 走「模板操作」

### 笔记操作
- [ ] Step 2a: 写操作前 `search` 确认文件是否存在；读操作不确定路径时先 `search`
- [ ] Step 3a: 按操作类型选择路径：
  - **新建** → 先 `templates` 检查是否有可用模板 → 有则 `create` + `template=<name>`，无则 `create` + `content=...` → `search` 相关笔记 → `property:set` tags（开头）→ 内容末尾补充 `[显示文本](相对路径.md)`
  - **追加/前置** → `append` / `prepend` / `daily:append` / `daily:prepend`
  - **更新已有内容** → 先 `read` + `outline` 了解结构与标题层级，确定插入位置（对应标题下/段落间），再 edit 局部修改或 `read` → `create overwrite`。禁止无视结构盲目追加到末尾。更新后检查 tags（开头）和链接（末尾）是否完整。
  - **删除** → `delete`
- [ ] Step 4a: 验证 — 写操作后用 `read` 确认内容落盘

### 模板操作
- [ ] Step 2d: `templates` 列出可用模板，选定目标模板
- [ ] Step 3d: 按操作类型选择路径：
  - **从模板创建新笔记** → 按新建流程，`create` + `template=<name>`
  - **插入模板到当前笔记** → `template:insert name=<name>`（⚠️ 需要文件在 Obsidian 中已打开为 active）
  - **预览模板内容** → `template:read name=<name>`（可选 `resolve` 解析变量，`title` 指定标题）
- [ ] Step 4d: 验证 — `read` 确认模板内容已正确写入/插入

### 元数据管理
- [ ] Step 2b: `search` 找到目标笔记
- [ ] Step 3b: 执行 `property:set` / `tags` / `tasks` / `task` 等
- [ ] Step 4b: 验证 — `property:read` 或 `tags file=...` 确认

### 链接分析
- [ ] Step 2c: 确定分析范围（单文件用 `file=<name>`，全库省略）
- [ ] Step 3c: 执行 `backlinks` / `links` / `orphans` / `unresolved` / `deadends`
- [ ] Step 4c: 验证 — 检查输出条目数是否合理，必要时用 `counts` 选项

## 可用命令

### 通用命令
帮助与版本信息。
`help` `version`

### 搜索
查找笔记、返回匹配文件列表或带上下文的匹配行、打开搜索视图。
`search` `search:context` `search:open`

### 文件操作
读取、创建和修改笔记（`create overwrite` 可用于更新已有笔记）。
`read` `create` `append` `prepend` `move` `rename` `open` `delete` `unique`

### 日记
日记读写。
`daily` `daily:read` `daily:path` `daily:append` `daily:prepend`

### 元数据与属性
标签、属性、任务、别名管理。
`tags` `tag` `properties` `property:read` `property:set` `property:remove` `tasks` `task` `aliases`

### 链接与关系
分析笔记间的引用关系。
`backlinks` `links` `unresolved` `orphans` `deadends`

### 大纲与字数
查看文档结构、统计字数、随机笔记。
`outline` `wordcount` `random` `random:read`

### 模板与书签
模板插入、书签管理。
`templates` `template:read` `template:insert` `bookmarks` `bookmark`

### 工作区与标签页
工作区管理、标签页操作、最近文件。
`workspace` `workspaces` `workspace:save` `workspace:load` `workspace:delete` `tabs` `tab:open` `recents`

### 命令面板
查看和执行 Obsidian 命令、快捷键查询。
`commands` `command` `hotkeys` `hotkey`

### 文件与目录信息
查看文件/目录结构、vault 信息与切换。
`file` `files` `folder` `folders` `vault` `vaults` `vault:open`

### 历史版本
查看、对比、恢复文件历史版本（只读）。
`history` `history:list` `history:read` `history:restore` `history:open` `diff`

### 数据库表（Base）
查询和创建 Obsidian Base 记录。
`bases` `base:views` `base:query` `base:create`

### Web Viewer
在 web viewer 中打开 URL。
`web`

## 选项约定

- `vault=<name>` 或 `vault=<id>` — 指定目标 vault（多 vault 时使用）
- `file=<name>` — 按名称引用（wikilink 风格，不含路径）
- `path=<path>` — 按路径引用（含目录，如 `子目录/文件.md`）
- `--copy` — 全局标志，可加到任意命令末尾，将输出复制到剪贴板
- content 中 `\n` 表示换行、`\t` 表示制表符；含空格的值必须加引号；含 `$`、`{}`、`` ` `` 等 shell 特殊字符的值务必用**单引号**包裹避免展开
- 需要详细参数说明时用 `obsidian help <command>` 或 `obsidian --help`

## Gotchas

- **`file` vs `path`**: `file=<name>` 按 wikilink 名称匹配（不含路径），`path=<path>` 按精确路径匹配。同名文件优先用 `path` 避免歧义。
- **默认 active file**: 多数命令省略 `file`/`path` 时作用于 Obsidian 当前打开的文件。批量脚本务必显式指定目标。
- **引号规则**: 含空格的值必须加引号，如 `name="My Note"`。content 参数中 `\n` 表示换行、`\t` 表示制表符。
- **`search` vs `search:context`**: `search` 返回匹配文件列表，`search:context` 返回匹配行及上下文。不确定文件时用前者，需要内容预览时用后者。
- **`format` 选项**: 各命令 format 可选值与默认值不同：`search`/`search:context` 仅 `text|json`（默认 text）；`tags`/`tasks`/`backlinks`/`hotkeys` 为 `tsv|json|csv`（默认 tsv）；`bookmarks` 默认 tsv；`base:query` 为 `json|csv|tsv|md|paths`（默认 json）；`outline` 为 `tree|md|json`（默认 tree）；`properties` 为 `yaml|json|tsv`（默认 yaml）。需要结构化解析时指定 `format=json`。
- **CLI 依赖 Obsidian 运行**: obsidian CLI 通过本地 HTTP 与 Obsidian 通信。若 Obsidian 未运行，首条命令会自动启动它；无需手动启动。
- **更新原则**: obsidian CLI 无独立 `update` 命令，但 `create overwrite` 可覆盖更新已有笔记。更新已有笔记内容时：
  1. 先用 `read` + `outline` 了解文档结构与标题层级
  2. 确定插入位置（对应标题下、段落间），禁止无视结构盲目追加到末尾
  3. 局部修改用 edit 工具精确替换；整篇重写用 `read` → 修改 → `create overwrite`
  4. 操作后检查上下文衔接、tags（开头 frontmatter）和链接（末尾）是否完整
- **优选 CLI，不强制**: 当 CLI 能完成任务时优先使用；CLI 不支持时（如更新内容、批量修改）使用系统文件工具。
- **标签与链接优先**: 创建或更新笔记时优先设置 tags 和链接。tags 通过 `property:set` 写入文档开头 YAML frontmatter；链接（`[显示文本](相对路径.md)` 格式）放置在文档内容末尾。新建后用 `search` 找同主题笔记建立引用。
- **`template:insert` 需要 active file**: `template:insert` 只能插入到 Obsidian 当前打开（active）的文件中。若文件未打开，先 `open path=...` 激活该文件。`template:insert` 还支持 `resolve` 选项显式解析模板变量。
- **模板变量解析**: 模板中 `{{title}}`、`{{date}}` 等变量可通过 `template:read resolve title="xxx"` 预览解析结果；`template:insert` 和 `create template=<name>` 时 Obsidian 自动解析当前上下文变量。
- **`counts` 适用范围**: `counts` 标志仅 `backlinks`、`unresolved`、`properties` 支持；`links`、`orphans`、`deadends` 不支持，调用会报错。
- **`append`/`prepend` inline**: 两者均支持 `inline` 标志（不额外添加换行）。`prepend` 默认在 frontmatter 之后插入，保留 YAML 头不动。
- **`delete` 默认回收站**: `delete` 默认移到回收站；加 `permanent` 标志跳过回收站永久删除，慎用。
- **`rename` 保留扩展名**: `rename` 时若新名省略扩展名，自动保留原扩展名。
- **`diff` 参数**: 支持 `from=<n>`、`to=<n>` 指定版本范围，`filter=local|sync` 区分本地 File recovery 与 Sync 版本。
- **`create` 标志**: `create` 支持 `open`（创建后打开）、`newtab`（在新标签页打开）、`overwrite`（覆盖已有文件）。
- **`daily` paneType**: `daily` 及其子命令支持 `paneType=tab|split|window` 控制打开位置。
- **`task` 参数丰富**: `task` 支持 `ref=<path:line>`、`line=<n>`、`status=<char>`、`toggle`、`daily`、`done`、`todo` 等，详见 `obsidian help task`。
- **`tags`/`properties` 排序**: `tags` 支持 `sort=count`（默认按名称排序）；`properties` 默认 format=yaml，可切 `json|tsv`。
- **content 特殊字符与模板变量**: 向 `create`/`append`/`prepend`/`daily:append`/`daily:prepend` 传 `content=...` 时，注意两类替换：
  1. **Shell 展开**: 在双引号下 `$VAR`、`${VAR}`、`` `cmd` ``、`$(cmd)` 会被 shell 解释；特别是 JavaScript 风格的 `${expr}` 会被 shell 当作变量展开为空字符串，造成**静默数据丢失**。`{a,b}` 列表花括号会被展开为 `a b`（单元素 `{x}` 保留字面）。**解决**: 含上述字符的 content 一律用**单引号**包裹（单引号内 `'…'` 无法嵌入单引号，需用 `'"'"'` 拼接，或改用文件方式写入）。
  2. **Obsidian 模板变量**: 官方 CLI 仅在 `template=<name>` 参数下触发 `{{date}}`、`{{time}}`、`{{title}}` 解析（由 Templates 插件处理）；纯 `content=` 不做替换。若 content 含字面 `{{...}}` 必须**避免使用 `template=`**。`template:insert` 默认会解析这些变量，需保留字面时改用 `template:read`（不加 `resolve`）预览模板原文，或写入临时文件后 `open` 再手动编辑。
  3. **社区插件**: 启用 Templater 等插件时，`<% ... %>` 等非官方语法可能被插件解析，行为不在 CLI 文档覆盖范围，调用前用 `template:read` 验证占位符是否被处理。

## 禁止行为

以下命令在官方 CLI 中存在，但出于安全策略本 skill 禁止使用：

- ❌ 管理插件、主题、CSS snippets（`plugin:*` / `theme:*` / `snippet:*`）
- ❌ 同步操作（`sync` 除 `sync:status` 外）
- ❌ `reload`、`restart`、`eval`、`dev:*`、`devtools`
- ❌ Publish 命令（`publish:*`）
- ❌ Plan Mode 下创建、覆盖、追加、删除、移动或修改任何 Vault 内容
- ❌ Plan Mode 下通过其他工具绕过 Obsidian 写权限

## 示例

```bash
# 搜索文档并阅读
obsidian search query="部署流程" limit=5
obsidian read path="文档/部署指南.md"

# 创建笔记 → 设置属性 → 验证
obsidian search query="React 笔记"               # 先确认不存在
obsidian create name="React 笔记" content="内容"
obsidian property:set name="tags" value="react,frontend" type=list file="React 笔记"
obsidian property:read name="tags" file="React 笔记"  # 验证属性已设置

# 日记追加并验证
obsidian daily:append content="## 今日任务\n- [ ] 完成部署文档"
obsidian daily:read | head -5                      # 验证内容已写入

# 链接分析
obsidian backlinks file="部署指南" counts           # 查看哪些文档引用了部署指南
obsidian unresolved total                          # 统计待解决的链接数

# 更新已有笔记（结构感知：先了解结构，再定位修改）
obsidian outline path="文档/部署指南.md"            # 了解标题层级
obsidian read path="文档/部署指南.md"               # 阅读完整内容
# 定位到 "## Docker 部署" 标题下，用 edit 工具插入新内容
# 更新后检查：开头 tags、末尾链接、上下文衔接

# 创建笔记（tags 在开头 frontmatter，链接在末尾）
obsidian search query="Docker" limit=5             # 搜同主题笔记建立关联
obsidian create name="Docker 笔记" content="# Docker\n\n内容...\n\n## 相关笔记\n[部署指南](部署指南.md)"
obsidian property:set name="tags" value="docker,devops" type=list file="Docker 笔记"
obsidian property:read name="tags" file="Docker 笔记"   # 验证 tags 在开头已设置

# 删除笔记
obsidian delete path="文档/过时文档.md"

# 模板操作（创建笔记前先检查模板）
obsidian templates                                  # 检查可用模板
obsidian create name="项目周会 2026-07-02" template="会议纪要"  # 有匹配模板则使用
obsidian property:set name="tags" value="meeting,project" type=list file="项目周会 2026-07-02"

# 在已打开的笔记中插入模板
obsidian open path="日记/2026-07-02.md"             # 先激活文件
obsidian template:insert name="每日回顾"

# 预览模板内容
obsidian template:read name="会议纪要" resolve title="项目周会"

# 覆盖更新已有笔记（create overwrite）
obsidian read path="笔记/旧文档.md"                     # 先读原内容
obsidian create name="旧文档" path="笔记/旧文档.md" content="新内容" overwrite

# content 含 ${...} 等 shell 特殊字符：用单引号包裹（JS 模板字符串示例）
obsidian create name="代码笔记" content='const f = ({x}) => `${x}`;'

# 避免使用 template= 时 content 中的 {{...}} 被解析
obsidian templates
obsidian create name="示例" content='{{date}} 字面量'  # 无 template=，{{date}} 不会被替换

# --copy 全局标志：将搜索结果复制到剪贴板
obsidian search query="部署" format=json --copy
```

> 更多命令和参数请用 `obsidian --help` 查看。
