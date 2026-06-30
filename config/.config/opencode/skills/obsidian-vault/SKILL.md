---
name: obsidian-vault
description: 适用：通过 obsidian CLI 搜索/阅读/写入/更新 Obsidian vault 中的笔记文档，不得直接操作文档。不适用：用户要求删除笔记或插件/主题管理。Use when: searching documentation, reading notes, creating/updating notes, querying tags/properties/tasks. Do NOT use for: deleting notes, managing plugins/themes, sync operations (except status).
tags: obsidian,cli,vault,search,write,notes
---

# Obsidian Vault CLI

通过 `obsidian` CLI 与 Obsidian vault 交互，搜索文档、读写笔记、管理元数据。具体命令参数用 `obsidian --help` 或 `obsidian help <command>` 查询，不在此文件中展开。

## 适用场景
- 搜索文档 / 阅读笔记 / 查看大纲与元数据
- 创建笔记 / 追加或前置内容 / 移动或重命名
- 查询标签、属性、任务、链接关系
- 日记读写

## 核心原则

1. **搜索优先** — 不确定文件位置时先 `search`，找到路径后再 `read`
2. **可写禁删** — 允许 `create`、`append`、`prepend`、`property:set`、`property:remove`、`move`、`rename`；禁止 `delete`、`permanent`
3. **不碰插件主题** — 禁止 `plugin:*`、`theme:*`、`snippet:*`、`sync:*`（`sync:status` 除外）
4. **不执行危险操作** — 禁止 `reload`、`restart`、`eval`、`dev:*`、`devtools`

## 可用命令

### 搜索与阅读
`search` `search:context` `read` `files` `folders` `outline` `wordcount` `aliases`

### 文件写入
`create` `append` `prepend` `move` `rename` `template:insert`

### 日记
`daily:read` `daily:path` `daily:append` `daily:prepend`

### 元数据
`tags` `properties` `property:read` `property:set` `property:remove` `tasks` `task`

### 关系与链接
`backlinks` `links` `unresolved` `orphans` `deadends`

### 其他查询
`recents` `random` `random:read` `templates` `template:read` `bookmarks` `file` `vault` `version`

## 选项约定

- `vault=<name>` — 指定目标 vault（多 vault 时使用）
- `file=<name>` — 按名称引用（wikilink 风格，不含路径）
- `path=<path>` — 按路径引用（含目录，如 `子目录/文件.md`）
- content 中 `\n` 表示换行、`\t` 表示制表符；含空格的值必须加引号
- 需要详细参数说明时用 `obsidian help <command>` 或 `obsidian --help`

## 禁止行为

- ❌ 删除笔记（`delete` / `permanent`）
- ❌ 管理插件、主题、CSS snippets（`plugin:*` / `theme:*` / `snippet:*`）
- ❌ 同步操作（`sync` 除 `sync:status` 外）
- ❌ `reload`、`restart`、`eval`、`dev:*`、`devtools`
- ❌ 直接操作 vault 文件系统（必须通过 CLI）
- ❌ 创建笔记前未先搜索确认文件不存在

## 示例

```bash
# 搜索文档并阅读
obsidian search query="部署流程" limit=5
obsidian read path="文档/部署指南.md"

# 创建笔记并设置属性
obsidian create name="React 笔记" content="内容"
obsidian property:set name="tags" value="react,frontend" type=list file="React 笔记"
```

> 更多命令和参数请用 `obsidian --help` 查看。
