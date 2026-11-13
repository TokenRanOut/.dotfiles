---
name: skill-writing-guide
description: >
  Guides the creation, improvement, and evaluation of agent skills, including SKILL.md,
  trigger descriptions, supporting scripts, references, and test cases. Applies when
  creating, modifying, reviewing, or evaluating skills, not when merely executing an existing skill's workflow,
  developing ordinary application code, or editing OpenCode configuration.
tags: skill,meta,creation,best-practices
---

# skill-writing-guide

## Workflow

Identify the task mode first. For reviews, inspect and report findings, evidence, and recommendations without editing files. For evaluations, run only authorized tests and report results without applying fixes unless requested. For creation or modification, apply and validate the agreed changes. Use the following steps as inspection criteria for reviews and evaluations, and as editing guidance for creation and modification.

1. Read the existing skill and applicable conventions. Use real tasks and project materials to establish expected inputs, outputs, activation scenarios, and related tasks outside its scope. Reuse available examples; ask for missing facts that affect scope instead of inventing rules.
2. Check that `description` identifies the capability, user intent, and activation conditions. Add exclusions where adjacent tasks could be confused. Follow the target platform's perspective and length requirements; do not impose a universal opening phrase.
3. Keep the body focused on the execution entry point, necessary constraints, decisions, and expected results. Move details into supporting references and state when to read them. Reuse skills already loaded and still applicable.
4. Validate at a depth proportional to the task. Report findings and recommendations for reviews or evaluations; report changed paths and key behavior changes for creation or modification. Include verification results and remaining limitations.

## Authoring rules

- Write this guide and all skills created or modified under it in English, including descriptions, instructions, explanations, and supporting references. Translate existing prose within the agreed editing scope. Preserve original identifiers, paths, quoted source material, and non-English test inputs when their original form matters.
- Use imperative phrasing for executable instructions: "Read the configuration" or "Validate the output," rather than "You should validate the output." Use natural declarative sentences for explanations; do not turn headings, facts, or examples into commands.
- Organize each skill around one coherent goal. Add domain conventions, project knowledge, and non-obvious failure modes the agent lacks; omit basic tutorials and repeated global rules.
- Start `SKILL.md` with YAML frontmatter containing at least `name` and `description`. Use a kebab-case name matching the skill directory and top-level heading. Follow the target platform's supported metadata fields and description limits.
- Choose sections and wording that serve the task instead of imposing a fixed template. Provide a default approach and introduce alternatives only with clear selection conditions. Prescribe fragile or order-sensitive steps precisely; leave room for judgment where multiple approaches are valid.
- Keep the main document concise. Treat approximately 500 lines as a prompt to review structure, not a reason to split rules that must be understood together.
- Give the body and references distinct responsibilities. Avoid duplicating entire workflows, resolve relative links from the containing Markdown file, and add scripts or templates only when they provide concrete reuse or reliability benefits.
- Extract reusable constraints from observed failures and user corrections. State their applicability and necessary rationale instead of turning one task's details into universal requirements.
- Declare dependencies and responsibilities without making multiple skills prescribe the same behavior. Do not treat a request to edit a skill as authorization to execute its business workflow. Run selected workflow cases only for validation, within the user's authorization and with appropriate isolation.

## Read supporting references as needed

| Need | Reference |
|---|---|
| Diagnose false activations or missed activations, or systematically optimize a description | [description-optimization.md](references/description-optimization.md): positive and negative cases, iteration, and independent final testing |
| Establish formal behavior evaluation, compare versions, or investigate recurring regressions | [eval-framework.md](references/eval-framework.md): isolated runs, assertions, baselines, and result aggregation |
| Create, modify, or review supporting executable scripts | [script-design.md](references/script-design.md): non-interactive interfaces, diagnostics, dependency reproducibility, and script patterns |

## Validation and delivery

- For small wording or routing changes, check frontmatter, links, rule consistency, English prose, and imperative instructions. Walk through representative activation and non-activation scenarios.
- For workflow changes, select a few real cases or static scenarios covering affected decisions. Execute tests only within the user's authorization and task boundaries.
- For broad or high-impact changes, use formal evaluation and with-skill/without-skill comparisons as needed. Do not require a workspace or full evaluation suite for every edit.
- Evaluate observable results and evidence rather than fixed phrases, template completeness, or rule counts. Distinguish static checks from executed tests; do not report a scenario walkthrough as measured activation accuracy or demonstrated behavior improvement.
