# Technical design workflow

Create or update one technical design document in the current session for an independent requirement item or a complete requirement, according to the user's scope. Write for direct implementation, focusing on processing logic, interface fields, data access, and actual code rather than industry introductions, progress reports, or project governance.

## Inputs

```text
需求=<body, URL, local path, or Obsidian note> 范围=<自动|单需求点|完整需求; optional, default 自动> 需求点=<optional for a single item> 项目=<optional> 全局职责矩阵=<optional> 技术锚点=<optional> 已有方案=<optional> 输出=<optional> 交付方式=<保存|预览; optional, default 预览>
```

- Require locatable requirements from the current input or a confirmed summary in the current session. Other inputs only help locate scope and code. A global responsibility matrix is optional; do not require creating one first. Verify responsibilities and call evidence separately for each project in cross-project work.
- For `范围=单需求点`, handle only the user-specified item. If none is specified and several candidates exist, return the candidates instead of choosing one.
- For `范围=完整需求`, cover all content intended for this implementation in the requirements document. Multiple related items, business scenarios, projects, and interfaces may share one What/Why/How/Example document organized by scenario; do not force a split.
- For `范围=自动`, use single-item scope when the user names an item; use complete scope when they request “整份、全部、完整需求”. If they provide complete requirements without narrowing scope, cover them in full by default.
- Ask only when scope cannot be determined or unrelated content cannot form one implementation design. Do not force a split merely because there is more than one item, or merge unrelated requirements without authorization.
- `输出` must be a locatable absolute local path or vault-relative Obsidian path. Saving to Obsidian requires a supplied or uniquely determined vault-relative path that includes its directory; never save by filename alone. Stop saving and explain when rules are missing, the template is unreadable, or candidates are ambiguous.
- Follow an explicit `交付方式`. Otherwise default to preview; enter save mode only for explicit write requests such as “保存”, “落盘”, or “直接更新已有方案文档”. “生成方案”, “看看怎么设计”, and “调整这部分设计” do not authorize saving; neither does supplying only `输出` or `已有方案`.
- Save mode creates or updates the design document. Preview mode writes no deliverable, project code, or configuration; perform the same code verification and return the complete body with a suggested path. Mark an unresolved path as undetermined rather than interrupting the preview. Handle temporary web-verification snapshots and screenshots according to the browser skill and current mode.
- When the user confirms a preview and requests saving, reuse the confirmed body. Change affected content only for confirmed changes to requirements, final design, or key contracts; do not regenerate without reason.
- Modify only the technical design document, not business code, configuration, databases, PRDs, or responsibility matrices.
- In read-only or planning mode, or without write permission, analyze and preview only. A user request to save does not mean the runtime permits writing. Save only with both explicit user authorization and runtime permission; do not bypass restrictions through Shell, scripts, or delegation.

## Scope and evidence boundaries

1. The user's latest explicit confirmations, exclusions, and priority adjustments supersede earlier analysis. Excluded content must not appear in goals, scope, flows, code changes, examples, or acceptance criteria.
2. State current facts, risk conclusions, or optimization items only when supported by requirements, project code, configuration, or confirmed external contracts. Put unverifiable implementation blockers only in “待确认事项” with their specific impact; remove unknowns that do not block this implementation.
3. Expand only the content of this implementation. State necessary scope boundaries as final conditions rather than recording rejected alternatives from the discussion. Create a separate future-optimization design only if explicitly requested.
4. Before updating an existing design, search for all documents with the same name. Compare paths and contents when multiple candidates exist; do not select one independently or create a numbered duplicate.

## Writing rules and template

Before writing or updating the body, read the [writing rules](writing-rules.md) and [technical design template](../templates/technical-design.md). Follow their structure, length guidance, representations, metadata, How/Example requirements, and self-checks.

## Updating an existing design

- Read the complete existing document before planning local edits. Establish its goals, scope, section responsibilities, and relationships among flows, rules, contracts, code changes, and examples. Use this whole-document understanding to determine content ownership and necessary edit locations; a local change does not limit comprehension or final checking to the edited passage. Keep edits within the user's authorized scope rather than rewriting unrelated content for uniformity.
- Maintain the complete target design within the confirmed requirements scope, not a record of development progress or production implementation status. Partial implementation or early release does not change scope. Preserve all still-valid design content rather than converting it into a remaining-work list.
- Distinguish implementation deviations from design changes first. Intermediate implementations, temporary solutions, unfinished code, or code that does not yet match the design are not automatic grounds for rewriting it. Synchronize only confirmed changes to requirements, final design, or key contracts. Ask the user when it is unclear whether a code change represents a final design change; do not insert it directly into the body.
- Do not replace each “拟新增” with “已实现” because code was implemented or released, or require post-implementation source citations. Source evidence supports the design rather than representing current production status. Preserve valid original evidence; verify only affected content when evidence genuinely needs adding or replacing.
- Before updating, distinguish pre-existing capabilities from those introduced by this requirement using the confirmed requirements and design. Do not reclassify already-implemented requirement code as pre-existing foundations. Continue verifying facts and feasibility without automatically treating the current workspace as the target design. Integrate confirmed changes across affected rules, flows, interfaces, code changes, and examples; preserve other valid content and omit development or release histories.

## Workflow

1. Load `code-explore` as needed and `obsidian-vault` when Obsidian is involved. Reuse skills already loaded.
2. Read requirements, optional references, the complete existing design when present, writing rules, and template. Establish the document's overall structure and cross-section relationships before deciding local changes. When rendered web evidence is needed, load `playwright-cli` and execute in the current session; use its reference workflow for complete high-fidelity collection.
3. Determine implementation scenarios from the inputs and scope rules. For an existing design, first establish the confirmed design and change scope using “Updating an existing design”. Identify candidate projects, then verify entry points, call chains, data access, transactions, caches, messages, interfaces, and exception boundaries in code. For external configuration centers, verify the actual platform, owning service, configuration location and keys, reading code, default and exceptional behavior, and activation mechanism. Define the configuration contract using the writing rules; repository configuration changes do not substitute for configuration-center changes.
4. After identifying the code scope, read applicable project conventions and similar implementations. Load coding-convention skills according to the involved layers, components, and cross-cutting capabilities, not all conventions at once. Both pseudocode and real code in the design must follow applicable conventions.
5. Verify reusable classes, methods, interfaces, and components. Prefer reuse, then minimal extension; add capabilities only when existing ones are insufficient. Before pseudocode, determine the owning layer and class, method responsibilities, reused and new capabilities, dependency acquisition, and exception handling from project conventions, similar implementations, and applicable coding standards. Do not generate generic code and then substitute project names. Retain only implementation-relevant capability gaps and evidence in the body, following the writing rules.
6. Cite existing code as `ClassName.methodName() @ repository-relative-path:line`, preserving the complete directory hierarchy relative to its repository root, not a local absolute path. Identify the project for cross-repository citations. Give target repository-relative paths for proposed files without invented line numbers. Follow the writing rules for exact formatting.
7. For RPC public-contract changes, verify the Provider and affected Consumers' build manifests according to the interface-version requirements in the writing rules.
8. Keep only evidence directly affecting this requirement's implementation. Describe unchanged external capabilities in at most one sentence in a flow.
9. Group confirmed design information by scenario, rule topic, and contract before selecting representations using the writing rules: flowcharts for overall flows, preferably text trees for local branches, short numbered steps for simple linear logic, and code as needed for precise implementation. When updating, integrate information into its owning location and synchronize affected flows, trees, contracts, and examples rather than appending explanations by default. For presentation-only changes, preserve confirmed business rules and design scope. Do not duplicate logic. Start every flowchart independently at an explicit business entry and cover its complete flow; do not stitch charts together. Generate the body from the template and remove empty conditional subsections. Save mode requires a readable template and uniquely determined output path; otherwise stop saving and return missing information or candidate paths. Preview mode does not require a determined output path.
10. Write files only in save mode. For Obsidian, create or update using the complete `path`; verify the target directory and same-named files first. Never create by `name` alone.
11. After saving, reread to verify the actual path, title, frontmatter, tags, links, and content. Search for same-named files to ensure no root-level copy or numbered duplicate was created. In preview mode, return the complete body directly.

Independent source exploration may follow `code-explore`'s delegation contract. Pass the question, scope, current operating restrictions, necessary conventions, and evidence requirements; subagents do not make design decisions or save the design. Skill loading, query tools, and dependency access depend on actual runtime capabilities and valid authorization. Do not assume specific subagent names or capabilities, or automatic skill inheritance. Complete any verification a subagent cannot perform in the current session within its permissions. If verification remains impossible, state the reason, missing prerequisites, and design impact. By default, explore only project-maintained source, configuration, schemas, tests, and build manifests. For external dependencies, confirm only public signatures actually used by the project; do not read implementations or expand into unrelated symbols.

## Output self-check

Check and correct each item before saving or returning; do not put the checking process in the document:

- Read the complete resulting document and apply the writing rules' body self-check across all sections, not only edited passages or affected topics. Check content ownership, repetition, contradictions, references, preservation of valid rules and boundaries, and agreement among What, Why, How, and Example. Verify confirmed scope coverage and evidence. Check and correct target-language code blocks against project conventions and applicable coding skills; check text trees for conditions and behavior, not merely formal completeness. Correct issues within the authorized scope; report material issues outside it without silently expanding the task.
- Keep overall flows, local decisions, and precise mechanisms distinct. Text trees must state parent-child conditions and corresponding behavior without implying undefined execution order. Use only flowcharts for diagrams, each starting independently at an explicit business entry and showing its complete flow rather than attaching to another chart's end. Titles, nodes, and edges must convey the business topic and main flow without piles of implementation names. Keep flowcharts, rule trees, code, contracts, and examples consistent without duplicating logic.
- For saving, reread the target as specified in the workflow; confirm paths, metadata, links, and absence of duplicate documents.
- Check Mermaid compatibility against the writing rules: default `graph TD;`, one semicolon-terminated statement per line, simple node IDs, double-quoted text labels, and basic shapes and edges. Verify against the actual host version when known; distinguish static checks from actual rendering validation.

## Return

- Save mode: return only write status, document path, and unresolved questions; omit unresolved questions when none exist.
- Preview mode: return the suggested path and complete design body; mark the path as undetermined if necessary.
