---
name: code-explore
description: >
  Analyze implementations, symbol calls, or cross-project behavior in local codebases and provide locatable source evidence.
  Use for focused analysis or broad exploration, not file discovery alone, general programming questions, documentation-only editing, or mechanical changes that need no implementation understanding.
---

# code-explore

## Entry workflow

1. Identify the question, project root, and required conclusion. Inspect structure before locating symbols; do not assume layers or cross-project calls.
2. Load and follow `codegraph` for call relationships, module relationships, cross-file business flows, or change impacts; reuse it when already loaded. Read known files directly for local analysis.
3. Delegate broad, independently parallelizable, or noisy exploration by question when useful; do not divide work mechanically by file.
4. Follow relevant symbols to obtain supporting call sites, branches, and configuration. Stop once evidence is sufficient; do not transcribe entire sources.
5. Summarize conclusions, evidence, and unresolved questions. Collect evidence separately for each project before connecting them; similar names do not prove calls.

## Exploration scope and boundaries

By default, read first-party source, configuration, SQL, schemas, tests, documentation, and build manifests under the task's project root. Treat each additional repository explicitly named in the task as a separate root.

Exclude dependency source packages, archives, and binaries (such as `.jar`, `.class`, and `.so`), package-manager caches and third-party directories (such as `~/.m2/`, `~/.gradle/caches/`, `node_modules/`, `vendor/`, `.venv/`, and `site-packages/`), and compiled, generated, or decompiled output such as `target/`, `build/`, `out/`, and `dist/`. The minimal public-signature inspection and explicit exceptions below are permitted.

### External dependencies: public signatures only

To confirm contracts for dependencies actually referenced by the project, minimally locate the target public types, functions, methods, constructors, fields, or exports:

- Read public API declarations, type definitions, interfaces, headers, or signature sections of dependency sources. Record dependency identity, verifiable version, qualified symbol, signature, return type, and declaration source.
- Stop once signatures establish the contract. Do not read method bodies, analyze internals, decompile, or expand to unrelated symbols, transitive dependencies, or entire dependency directories.

### Explicit exceptions

When the user or caller requests dependency internals, compiled implementations, or other material beyond the default scope, establish the following in the current task and pass the effective authorization scope unchanged when delegating:

- Dependency name and package identifier, coordinates, or module identifier, plus version or exact path.
- The specific question and why project sources and public contracts cannot answer it.
- Permitted operations, such as reading specified sources, listing artifact contents, or inspecting specified compiled implementations.
- A stopping condition identifying target symbols or files; do not expand to unrelated types, transitive dependencies, entire caches, or subsequent tasks.

Mark external signatures and authorized implementation evidence as `[外部依赖证据]`, including identity, version, path or declaration source, and acquisition method. Separate them from project-source conclusions. Verify evidence paths and discard unauthorized method bodies, decompilation, or scope expansion.

## Delegation contract (only when delegating)

Use the runtime's delegation interface without assuming a particular API. Provide the following for each task rather than relying on automatic skill inheritance:

```text
Role: Source-analysis subagent; directly inspect the specified scope without further delegation.
Project root and scope: {root / files / symbols}
Question: {independent question; add domain dimensions as needed}
Boundaries: First-party project content only. For external dependencies actually referenced by the project, inspect only target public signatures and record identity, version, qualified symbols, signatures, and declaration sources. Stop at the signatures; do not read implementations, decompile, or expand to unrelated symbols.
Output: Conclusions, call relationships or relevant behavior, precise evidence, and unresolved questions; label external evidence separately. Include only the minimum excerpts supporting conclusions.
External-dependency exception (only if authorized): {identity; version or path; question and rationale; permitted operations; stopping condition}
```

Run independent tasks in parallel; the caller consolidates and verifies results. Leaf source-exploration agents must not delegate recursively; orchestration agents may assign independent exploration only within the task's allowed nesting depth. When summaries are insufficient, investigate specific symbols or lines rather than using subagents to transport files. Unless explicitly requested, do not return full files, near-complete line-by-line transcriptions, or large unrelated excerpts.

## Results

- Answer the question first, then provide key implementation details and evidence. Present call relationships, parameter handling, data operations, exceptions, or external calls as needed rather than filling mandatory tables.
- Cite `project-or-module.native-symbol @ path/to/file:start-end`; after a full location, same-file jumps may use `line → line`.
- Distinguish verified facts, inferences, and missing evidence. State when versions, implementations, or cross-project relationships cannot be confirmed.
