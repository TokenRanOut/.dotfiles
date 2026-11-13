# Obsidian CLI reference

Read when selecting commands, handling parameter edge cases, or consulting examples. Follow the safety boundaries in [SKILL.md](../SKILL.md); this catalog is not an authorization list. Check local parameters with `obsidian help <command>` as needed before execution.

## Version and sources

- Parameters were checked against local `obsidian help` for Obsidian 1.15.0 (installer 1.15.0). `heading=` requires 1.15+; check `obsidian version` and the corresponding command help before use.
- Official references: [Obsidian CLI](https://obsidian.md/help/cli) and [1.15 changelog](https://obsidian.md/changelog/2026-11-02-desktop-v1.15.0/). Local help takes precedence; some documented commands may be TUI-only or unavailable locally.

## Command catalog

### General
Help and version information.
`help` `version`

### Search
Find notes, return matching files or matching lines with context, and open search views.
`search` `search:context` `search:open`

### File operations
Read, create, and modify notes (`create overwrite` can update existing notes).
`read` `create` `append` `prepend` `move` `rename` `open` `delete`

The official documentation also lists `unique`, but local 1.15.0 help does not; do not assume availability.

### Daily notes
Read and write daily notes.
`daily` `daily:read` `daily:path` `daily:append` `daily:prepend`

`daily:path` returns the expected path, not proof that the note exists. `daily:append` / `daily:prepend` support `heading=`.

### Metadata and properties
Manage tags, properties, tasks, and aliases.
`tags` `tag` `properties` `property:read` `property:set` `property:remove` `tasks` `task` `aliases`

### Links and relationships
Analyze references between notes.
`backlinks` `links` `unresolved` `orphans` `deadends`

### Outline and word count
Inspect document structure, count words, and access random notes.
`outline` `wordcount` `random` `random:read`

### Templates and bookmarks
Insert templates and manage bookmarks.
`templates` `template:read` `template:insert` `bookmarks` `bookmark`

### Workspaces and tabs
Manage workspaces, tabs, and recent files.
`workspace` `workspaces` `workspace:save` `workspace:load` `workspace:delete` `tabs` `tab:open` `recents`

### Command palette
List and execute Obsidian commands and inspect hotkeys.
`commands` `command` `hotkeys` `hotkey`

### File and directory information
Inspect file/directory structures and vault information.
`file` `files` `folder` `folders` `vault` `vaults`

`vault:open` is TUI-only; select a vault for a single command with `obsidian vault=<name> <command>`.

### History
Inspect and compare file history; `history:restore` is a write operation.
`history` `history:list` `history:read` `history:restore` `history:open` `diff`

### Bases
Query and create Obsidian Base records.
`bases` `base:views` `base:query` `base:create`

### Web Viewer
Open URLs in the web viewer.
The official documentation lists `web`, but local 1.15.0 help does not; confirm availability before use.

## Option conventions

- `vault=<name>` — Place before the command, for example `obsidian vault="我的笔记" read path="子目录/文件.md"`. The official documentation also supports vault IDs; use an actually verified identifier. Without this option, the current working directory is used if it is a vault; otherwise the active vault is used.
- `file=<name>` — Resolve names using wikilink rules without requiring the full path or extension.
- `path=<path>` — An exact path relative to the vault root, including directories and extension, such as `子目录/文件.md`.
- `heading=<name>` — Target section for `append` / `prepend` / `daily:append` / `daily:prepend`.
- `--copy` — Global flag appended to any command to copy output to the clipboard.
- In content, `\n` means newline and `\t` means tab. Quote values containing spaces. Use **single quotes** for values containing shell special characters such as `$`, `{}`, or backticks to prevent expansion.
- Use `obsidian help <command>` for detailed parameters and `obsidian help` for the command overview.

## Gotchas

- **`file` vs `path`**: `file=<name>` matches a wikilink name without its path; `path=<path>` matches an exact path. Prefer `path` for same-named files to avoid ambiguity.
- **Default active file**: most commands act on the currently open Obsidian file when `file`/`path` is omitted. Always specify targets in batch scripts.
- **Quoting**: quote values containing spaces, such as `name="My Note"`. In content parameters, `\n` means newline and `\t` means tab.
- **`search` vs `search:context`**: `search` returns matching files; `search:context` returns matching lines with context. Use the former to locate files and the latter for content previews.
- **`format` options**: choices and defaults vary. `search`/`search:context`: `text|json`, default text; `tags`/`backlinks`/`hotkeys`/`bookmarks`: `json|tsv|csv`, default tsv; `tasks`: optional `json|tsv|csv`, default text output; `base:query`: `json|csv|tsv|md|paths`, default json; `outline`: `tree|md|json`, default tree; `properties`: `yaml|json|tsv`, default yaml. Set `format=json` for structured parsing.
- **CLI requires running Obsidian**: the CLI connects to a running instance; the first command starts it automatically if needed.
- **Updating**: Obsidian CLI has no standalone `update`, but `create overwrite` can overwrite an existing note. To update existing content:
  1. Read the structure and heading hierarchy using `read` + `outline`.
  2. Determine the insertion point; append within a section using `append` / `prepend` with `heading=`. Do not ignore structure and blindly append to the end.
  3. Use precise file-tool edits for replacements, insertion between specified paragraphs, or ambiguous headings. For a full rewrite use `read` → edit → `create overwrite`.
  4. Check surrounding continuity, tags in the opening frontmatter, and links at the end after the operation.
- **Prefer CLI, do not mandate it**: prefer CLI whenever it supports the task, including section-level insertion. Use file tools for unsupported content replacements. Verify every target and result in batch work.
- **Prioritize tags and links**: set tags and links when creating or updating notes. Write tags to the opening YAML frontmatter through `property:set`; put links (`[显示文本](相对路径.md)`) at the end of the document. After creation, use `search` to find related notes and establish references.
- **`template:insert` requires the active file**: it inserts only into the currently open file. Activate and verify the target with `open path=...` first. Local help lists only `name=`; do not pass `resolve`. Use `template:read resolve` for an explicitly resolved preview.
- **Template variable resolution**: preview variables such as `{{title}}` and `{{date}}` with `template:read resolve title="xxx"`. Obsidian resolves current-context variables automatically for `template:insert` and `create template=<name>`.
- **`counts` support**: `tags`, `backlinks`, `unresolved`, and `properties` support `counts`. `links`, `orphans`, and `deadends` do not list it; use their `total` flag for counts.
- **Section insertion (1.15+)**: `append` / `prepend` / `daily:append` / `daily:prepend` support `heading=<name>`. Read the target and verify the heading text and uniqueness first. `append` inserts at the section end; `prepend` at its beginning. If the heading is missing, establish the structure as required by the task or ask the user. Do not remove `heading=` and write at the file end. If a daily note does not yet exist, inspect the intended template for the heading first.
- **Newline control**: all four commands above support the bare flag `inline`, which adds no extra newline. Without `heading=`, `prepend` inserts after frontmatter by default, preserving the YAML header. CLI newline control uses `inline`; do not mix in the Obsidian URI parameter `spacing=`.
- **Write results**: inspect command output and reread the entire affected section with adjacent headings. An exit code or the first few file lines alone does not prove successful insertion.
- **`delete` uses trash by default**: the `permanent` flag bypasses trash and deletes permanently; use cautiously.
- **`rename` preserves extensions**: omitting the extension in a new name preserves the original extension automatically.
- **`diff` parameters**: `from=<n>` and `to=<n>` select the version range; `filter=local|sync` distinguishes local File recovery from Sync versions.
- **`create` flags**: supports `open` (open after creation), `newtab` (open in a new tab), and `overwrite` (overwrite an existing file).
- **`daily` paneType**: `daily`, `daily:append`, and `daily:prepend` support `paneType=tab|split|window`; the latter two use `open` to request opening. `daily:path` / `daily:read` do not list these parameters.
- **`task` parameters**: supports `ref=<path:line>`, `line=<n>`, `status=<char>`, `toggle`, `daily`, `done`, `todo`, and more; see `obsidian help task`.
- **`tags`/`properties` sorting**: `tags` supports `sort=count` and defaults to name order. `properties` defaults to `format=yaml`, with `json|tsv` alternatives.
- **Special characters and template variables in content**: account for the following when passing `content=...` to `create`/`append`/`prepend`/`daily:append`/`daily:prepend`:
  1. **Shell expansion**: double quotes allow shell interpretation of `$VAR`, `${VAR}`, backtick command substitutions, and `$(cmd)`. `${expr}` can be substituted or fail, changing content; unquoted `{a,b}` can undergo brace expansion. **Solution**: single-quote all content containing these characters. Single quotes cannot be embedded inside `'…'`; concatenate with `'"'"'` or write through file tools instead.
  2. **Obsidian template variables**: the official CLI resolves `{{date}}`, `{{time}}`, and `{{title}}` only with `template=<name>` through the Templates plugin; plain `content=` does not substitute them. **Avoid `template=`** when content contains literal `{{...}}`. `template:insert` resolves these variables by default. To preserve literals, preview raw template text using `template:read` without `resolve`, or write a temporary file, `open` it, and edit manually.
  3. **Community plugins**: plugins such as Templater determine behavior for non-official syntax such as `<% ... %>`. `template:read` checks only preview content and does not prove that plugins will not process saved content. Confirm existing plugin conventions first when literal syntax must be preserved and behavior is unclear.

## Examples

These examples omit vault selection. Confirm the target vault before execution and use verified exact `path` values for file operations. Verify daily-note targets with `daily:path`. Example headings must exist and be unambiguous; do not assume they do. Reread all affected content after writing. Check absence of the original path after deletion and both paths after moving.

```bash
# Search and read documents
obsidian search query="部署流程" limit=5
obsidian read path="文档/部署指南.md"

# Create a note, set properties, and verify
obsidian search query="React 笔记"               # Confirm absence first
obsidian create path="笔记/React 笔记.md" content="内容"
obsidian property:set name="tags" value="react,frontend" type=list path="笔记/React 笔记.md"
obsidian property:read name="tags" path="笔记/React 笔记.md"  # Verify the property

# Append within a daily-note section and verify (check existence or inspect the template first)
obsidian daily:path
obsidian daily:read
obsidian daily:append heading="今日任务" content='- [ ] 完成部署文档'
obsidian daily:read                               # Reread the entire affected section and adjacent headings

# Analyze links
obsidian backlinks path="文档/部署指南.md" counts    # Inspect references to the deployment guide
obsidian unresolved total                          # Count unresolved links

# Update an existing note: inspect structure, then locate the edit
obsidian outline path="文档/部署指南.md"            # Inspect heading hierarchy
obsidian read path="文档/部署指南.md"               # Read the complete content
# Append to the verified "Docker 部署" section; use prepend for its beginning
obsidian append path="文档/部署指南.md" heading="Docker 部署" content='- 部署前检查镜像版本'
obsidian read path="文档/部署指南.md"
# Use file tools for replacements or insertion between paragraphs; check tags, links, and continuity

# Create a note with tags in opening frontmatter and links at the end
obsidian search query="Docker" limit=5             # Find related notes for links
obsidian create path="笔记/Docker 笔记.md" content="# Docker\n\n内容...\n\n## 相关笔记\n[部署指南](../文档/部署指南.md)"
obsidian property:set name="tags" value="docker,devops" type=list path="笔记/Docker 笔记.md"
obsidian property:read name="tags" path="笔记/Docker 笔记.md"   # Verify opening tags

# Delete a note
obsidian delete path="文档/过时文档.md"

# Templates: inspect before creating a note
obsidian templates                                  # Check available templates
obsidian create path="会议/项目周会 2026-07-02.md" template="会议纪要"  # Use a matching template when available
obsidian property:set name="tags" value="meeting,project" type=list path="会议/项目周会 2026-07-02.md"

# Insert a template into an open note
obsidian open path="日记/2026-07-02.md"             # Activate the file first
obsidian template:insert name="每日回顾"

# Preview template content
obsidian template:read name="会议纪要" resolve title="项目周会"

# Overwrite an existing note with create overwrite
obsidian read path="笔记/旧文档.md"                     # Read the original first
obsidian create path="笔记/旧文档.md" content="新内容" overwrite

# Single-quote content containing shell special characters such as ${...} (JS template string)
obsidian create path="笔记/代码笔记.md" content='const f = ({x}) => `${x}`;'

# Avoid template= to preserve literal {{...}} in content
obsidian templates
obsidian create path="笔记/示例.md" content='{{date}} 字面量'  # Without template=, CLI does not resolve template variables

# Global --copy flag: copy search results to the clipboard
obsidian search query="部署" format=json --copy
```

> Consult `obsidian help` or `obsidian help <command>` for more commands and parameters.
