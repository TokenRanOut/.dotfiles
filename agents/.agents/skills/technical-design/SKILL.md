---
name: technical-design
description: Write, extend, update, or review implementation-ready What/Why/How/Example technical designs based on requirements and code. Default to a preview; save only on explicit request when the current mode permits writing. Reviews are read-only. Do not use for requirements decomposition, ordinary requirements summaries, reviews of other document types, or direct business-code implementation.
---

# technical-design

Complete design, preview, confirmation, and saving in the current session. Reuse the confirmed requirements scope and document body; do not create a dedicated design subsession. Write business deliverables in Chinese and retain the template's fixed Chinese headings and fields.

Choose the representation by content: flowcharts for overall flows, preferably text trees for local conditional branches, short numbered steps for simple linear logic, target-language code when precise implementation is needed, and tables or code for fields and contracts. Use one primary representation per piece of logic without repeating it. Use only flowcharts for diagrams; start each independently at an explicit business entry point and show its complete flow, rather than attaching its entry to another chart's end. Default Mermaid to `graph TD;`, with one semicolon-terminated statement per line; follow the writing rules for compatibility.

## Execution entry point

1. Distinguish writing, updating, and reviewing. Confirm the requirements or source document; do not request a source already established in the current session. Load `obsidian-vault` when Obsidian is involved.
2. **Write/update**: read the [design workflow](references/design-workflow.md), identify scope, verify code, and design the solution. Choose flowcharts, text trees, or code using the [writing rules](references/writing-rules.md), then organize the body using the [template](templates/technical-design.md). Load code-exploration and coding-convention skills as needed.
3. **Review**: read the original document, writing rules, and template. Verify requirements coverage, implementation evidence, and document consistency read-only. Return locatable issues, impacts, and recommendations without reapplying the template or entering the save workflow. Switch to write/update only when the user explicitly requests modifications.
4. Return a complete preview and suggested path by default. Save only on an explicit write request, with a unique target and an environment that permits writing. In read-only or planning mode, or without write permission, do not save deliverables or bypass restrictions through Shell, scripts, or delegation.
5. When updating or saving a confirmed preview, preserve the complete confirmed target design. Adjust affected parts only for confirmed changes to requirements, final design, or key contracts. Do not rewrite the body, shrink scope, or refresh implementation status based on development progress, intermediate implementations, or partial releases. Follow the workflow and writing rules for updates and evidence. After saving, reread the path, metadata, links, and body, and check for duplicate documents.

## Results

- Preview: suggested path and complete design body; an unresolved path does not block the preview.
- Save: write status, actual path, and unresolved questions that genuinely block implementation.
- Review: location, issue, evidence or impact, and recommendation, ordered by severity. Distinguish confirmed problems, optional improvements, and items that cannot be verified because specific prerequisites are missing.
