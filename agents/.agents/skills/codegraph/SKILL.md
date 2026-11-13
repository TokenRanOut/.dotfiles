---
name: codegraph
description: >
  Analyze callers, callees, module relationships, business implementation flows, or change impacts in local code.
  Excludes ordinary file discovery, local reading of known files, and index management.
---

# codegraph

## Scope

- Understand module relationships or cross-file business flows.
- Query symbol callers, callees, or change impacts.
- Obtain structured evidence separately for each project in a cross-project task.

`code-explore` owns general exploration scope and evidence conventions. This skill owns query-tool selection and usage; it does not replace domain analysis or source verification.

## Core principles

1. **Call directly from the current agent** — Run the `codegraph` CLI through the shell; do not delegate to an OpenCode `explore` subagent solely to run CodeGraph.
2. **Query one project at a time** — Identify the project root containing the nearest `.codegraph/`; pass an explicit absolute `--path` for each query command.
3. **Obtain minimal sufficient output** — Scope queries to the question and retrieve only supporting source. Start call queries at 20 results or impact queries at depth 2 when useful; continue targeted queries if evidence is insufficient, without treating initial limits as complete coverage.
4. **Prioritize evidence** — Source and line numbers from `explore` or `node` may be cited directly; names or statistics alone do not prove implementation behavior.
5. **Keep queries read-only** — Do not initialize, rebuild, synchronize, install, or uninstall CodeGraph without an explicit user request.

## Workflow

- [ ] Identify the project root for the target file or symbol. Locate `.codegraph/` within the authorized project scope; for nested repositories, choose the nearest parent containing `.codegraph/` without scanning unrelated directories.
- [ ] Fall back directly to source search if `.codegraph/` is absent. Otherwise check CLI availability, then inspect index status with `codegraph status <project-root> --json`.
- [ ] With an available index, choose the smallest suitable structured query: `node`, call queries, or impact queries for known symbols; `explore` for module relationships and cross-file business flows.
- [ ] If the index or CLI is unavailable, or results are insufficient, fall back to `glob`, `grep`, and targeted reads for that project only.
- [ ] Include project roots, file paths, symbols, and line numbers in conclusions. Establish each project's evidence before connecting cross-project conclusions.

## Query commands

```bash
# Business flows or module relationships
codegraph explore --path /absolute/project "Order creation flow"

# Source and relationships for known symbols or files
codegraph node --path /absolute/project OrderService
codegraph node --path /absolute/project --file src/main/java/example/OrderService.java

# Call relationships and change impacts
codegraph callers --path /absolute/project --limit 20 createOrder
codegraph callees --path /absolute/project --limit 20 createOrder
codegraph impact --path /absolute/project --depth 2 OrderService
```

## Fallbacks and boundaries

- If `.codegraph/` is absent or `status` reports an uninitialized index, use ordinary source tools rather than `codegraph init`.
- Report anomalous directories, duplicate symbols, or relationships in index results; do not modify ignore configuration without a user request.
- Same-named symbols and separate project results do not establish cross-project calls. Find interface contracts, dependency declarations, call sites, or configuration links.
- Indexes may lag behind recent writes; when warned of stale results, read only the affected files directly.

## Prohibited actions

- Do not omit `--path` from queries or pass a source file or `.codegraph/` directory as the project root.
- Do not mix projects in one command or describe separate query results as automatically discovered cross-project call edges.
- Do not create or delegate an `explore` subagent solely to run CodeGraph.
- Do not automatically execute `codegraph init`, `index`, `sync`, `install`, `uninstall`, or `serve --mcp`.
- Do not repeat equivalent reads of line-numbered source already returned by CodeGraph.
