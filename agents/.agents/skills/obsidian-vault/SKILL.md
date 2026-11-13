---
name: obsidian-vault
description: >
  Use this skill when the user wants to search, read, or modify notes and metadata in an Obsidian vault, explicitly named or established by context. Includes vault daily notes, tasks, links, and templates. Do NOT use for generic notes, links, tags, Markdown files outside a confirmed vault, other note apps, or plugin/theme/sync/export management.
tags: obsidian,cli,vault,search,write,notes
---

# obsidian-vault

Prefer Obsidian CLI for operations in a confirmed vault. Use file tools for localized content edits unsupported by the CLI.

## Execution routing

1. Confirm the target vault and operation scope. Use `search` first when the path is unknown. Specify an exact `path` for file operations; select the target among multiple vaults with `obsidian vault=<name> <command>`. For file tools, use the verified vault root and target path rather than relying on the default active file.
2. Choose the route for the task:
   - **Search/read**: `search` / `search:context` → `read`; use `outline` when structure is needed.
   - **Create**: check whether the target exists → inspect available templates with `templates` → `create`. Avoid accidental overwrites.
   - **Append/update**: locate headings or paragraphs with `read` + `outline` first. Use `append` / `prepend`; prefer `heading=<name>` for insertion into a named section (Obsidian 1.15+; first verify local help support and an existing, unambiguous heading). Use file tools to replace existing paragraphs or insert between specific paragraphs. Reserve `create overwrite` for whole-document rewrites. Do not blindly append structural updates to the end.
   - **Metadata/tasks/links**: establish single-file or vault-wide scope before selecting property, task, or link commands.
   - **Daily notes/templates**: use `daily:path` to confirm the expected path, then check existence. `daily:append` / `daily:prepend` also support `heading=`; verify the heading in the daily note or intended template before use. Preview templates with `template:read`; activate and verify the target with `open path=...` before insertion.
   - **Delete/move/rename**: verify the exact path first; use the trash by default for deletion.
3. Reread affected content with `read` / `property:read` after writing. After deletion, check that the original path is absent; after moving or renaming, check both old and new paths. Check frontmatter, links, and continuity with surrounding content.

## Safety boundaries

- **Plan Mode is read-only**: only read and analyze the vault. Do not create, append, overwrite, move, delete, modify properties or tasks, insert templates, restore history, or perform other writes. Do not bypass this through file tools, scripts, or other agents. Provide only proposed paths, locations, and content; save after switching modes. Stop when write permission is denied.
- Do not use `plugin:*`, `theme:*`, `snippet:*`, `publish:*`, `reload`, `restart`, `eval`, `dev:*`, or `devtools`. For sync, only `sync:status` is allowed.
- The command catalog does not grant permission. Recovery operations such as `history:restore` are writes; do not use the command palette to bypass these boundaries.

## Read references as needed

Before a specific CLI operation, read the relevant sections of [cli-guide.md](references/cli-guide.md): command catalog, parameter format, gotchas, and detailed examples. Read its gotchas first for shell special characters, template variables, batch operations, or active-file commands. Treat local `obsidian help <command>` as authoritative for parameters.
