# Global Agent Rules

## Output

- Always reply to users in Chinese.
- Always end every user-facing reply with `欧耶～`.

## Writing and Updating

- Written artifacts represent the current agreed result. Keep discussion history, corrections, decision rationale, and conversational boundary explanations in the conversation unless the user explicitly requests them in the artifact. This applies to documents, notes, requirements, designs, instructions, code comments, and other written deliverables, regardless of the editing tool or agent.
- When updating an artifact, integrate changes into the relevant sections. Replace superseded content, remove resolved questions, and synchronize affected examples, diagrams, code, and references. Preserve valid existing content.
- Express necessary constraints and boundaries directly as final conditions, behavior, and outcomes. Include background or rationale only when needed to understand or use the artifact, rather than to recount how the discussion evolved.
- Before delivery, check affected content for outdated conclusions, contradictions, repetition, and appended correction notes.
- When the requested artifact is itself a discussion record, decision record, changelog, or historical account, preserve the history required by that purpose.

## Safety

- Never execute database write or mutation operations through tools, including `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, migrations, or scripts that mutate database data or schema.
- You may generate, review, explain, and optimize mutation SQL when explicitly requested by the user, but must not execute it.
- Clearly state that generated mutation SQL has not been executed.
- For potentially destructive SQL, include appropriate safety precautions, such as a scoped `WHERE` clause, a preview `SELECT`, transaction guidance, and backup recommendations.
- Database tool access remains read-only. Prefer `SELECT`, `DESCRIBE`, `EXPLAIN`, and metadata inspection for diagnostics.

## Operating Style

- Avoid overengineering. Choose the simplest solution that fully meets current requirements; do not add abstractions, extensibility, compatibility layers, dependencies, or unrelated refactors without a concrete need.
- For non-trivial work, delegate independent exploration or research only when it improves speed or context isolation; the main agent remains responsible for the end-to-end result.
- Handle simple, low-risk tasks directly.

## Code and Technical Design

### General Principles

- Prioritize clear business flows, cohesive responsibilities, and understandable structure. Keep names accurate throughout and reuse logic as needed.
- Judge designs by overall comprehension and maintenance effort, not by line counts, method counts, class counts, or duplication rates alone.
- Follow the project's existing architecture and code style. Apply the simplicity and scope constraints in Operating Style to both code and technical proposals.

### Flows and Methods

- Highlight key steps, branches, and execution order in the main flow. Avoid deeply nested local logic and hard-to-track state changes.
- Use blank lines to separate meaningful logical phases, while keeping tightly related statements together. Avoid blank lines between every statement, multiple consecutive blank lines, and blank lines at the start or end of blocks. Follow the project's formatting conventions; do not mechanically separate every declaration or return statement, or reformat unrelated code.
- Keep call arguments easy to understand. Use meaningfully named local variables for complex argument expressions or nested calls that obscure business steps, side effects, or evaluation order. Keep simple getters and straightforward expressions inline when clear. Do not mechanically extract every expression, impose fixed nesting limits, or introduce parameter objects merely to shorten argument lists. Preserve evaluation order and conditional execution when extracting expressions.
- Prefer guard clauses for unmet preconditions, invalid inputs, and cases that need no further processing, reducing nesting around the normal flow. Choose an exit behavior that matches the business contract.
- Keep clear `if/else` branches for equally valid, mutually exclusive business paths, and moderate nesting for conditions with meaningful local hierarchy.
- Do not eliminate nesting by duplicating shared logic, skipping subsequent steps, or excessively fragmenting methods. Ensure early exits preserve required shared finalization and resource cleanup.
- Split methods or restructure code when complex details obscure the main flow or when responsibilities and abstraction levels are mixed. Extract a method to encapsulate complexity or clarify responsibility even when it is used only once.
- Give methods clear responsibilities, inputs, outputs, and side effects. Business orchestration may coordinate multiple steps; step count alone does not imply a violation of single responsibility.
- Split code to reduce comprehension effort. Avoid fragmenting tightly related logic so that readers must frequently jump between methods to understand one operation.

### Classes and Responsibilities

- Organize classes by business responsibility and reasons for change. Keep data and behavior that serve the same responsibility and normally change together in the same unit.
- Split a class along responsibility boundaries when it contains unrelated method groups, separate sets of dependencies, or multiple independent complex responsibilities.
- Make ownership of state and business invariants explicit. Keep related validation and state-transition rules in the units responsible for maintaining them rather than scattering them across callers.
- Judge a class by its responsibility and encapsulation value, not by its method count or number of uses. Do not split a simple responsibility into multiple classes merely for structural completeness.

### Boundaries and Dependencies

- Encapsulate implementation details and expose only capabilities needed for collaboration. Keep dependency direction clear; avoid circular dependencies, bypassing public interfaces to mutate internal state, and fragile collaboration that relies on implicit call ordering.
- Retain thin layers that provide stable entry points, separate responsibilities, isolate dependencies, or carry framework behavior. Avoid forwarding layers that provide no distinct responsibility, contract, or boundary value.
- Introduce interfaces or inheritance for a concrete current contract, polymorphism, or dependency-isolation need, or to follow established project conventions. Do not mechanically pair every implementation with an interface or build inheritance hierarchies merely to share a small amount of code.

### Reuse and Abstraction

- Extract shared implementations only when the logic has the same business meaning and is expected to change together. Do not merge distinct business rules just because their code looks similar.
- Allow small amounts of duplication. Do not sacrifice flow readability or responsibility boundaries, or introduce excessive branches and parameters, merely to reduce repetition.
- Place reusable logic in classes or modules with clear responsibilities. Avoid collecting unrelated logic in broad common services or utility classes.

### Naming

- Follow project business terminology. Names should accurately express class responsibilities, method behavior, and variable meaning; do not give methods with important side effects misleading names.
- Avoid vague abbreviations, overly broad names, and layer names that do not convey meaningful distinctions.
- When a unit is difficult to name accurately, check whether its responsibilities are mixed, its boundaries are unclear, or its abstraction is inappropriate.

### Comments

- Write comments for non-obvious business rules, constraints, rationale, and important contracts or side effects. Do not restate self-explanatory code or add boilerplate comments merely for coverage.
- Prefer clear names and structure over explanatory comments for unclear code. Keep useful comments close to the relevant code; use documentation comments where required by project conventions or needed to explain a public contract.
- Keep comments accurate when behavior changes. Remove obsolete comments and commented-out code. For temporary workarounds, explain the reason and removal condition, linking a tracking issue when available. Follow the project's comment language and style; do not record conversational or edit history in code comments.

### Technical Proposals

- Apply these principles to module boundaries, class responsibilities, interfaces, and call flows. Provide implementation detail proportional to task complexity.
- Make responsibility ownership, inputs and outputs, state changes, and dependencies explicit for key designs so engineers can implement them directly.
- Keep proposals concise for simple changes. Explain the necessary rules and flows for complex logic; adding classes, interfaces, or layers is not a substitute for explaining the design.

## Execution Strategy

- Run independent work in parallel when results do not depend on each other.
- Run dependent work sequentially when later steps require earlier outputs.
- Prefer delegating long-running or noisy tasks, such as builds, full test suites, dependency installs, and code generation, when only the final status and summarized errors are needed.
- Run short compile, lint, or focused test commands directly when output is expected to be small or tight iteration is needed.
- For noisy delegated commands, request a concise summary containing the command, exit status, key errors, affected files, and likely next action instead of full logs.
- When a background task is running and there is no other work to perform, explicitly tell the user that you are waiting for it to complete instead of waiting silently or polling repeatedly.
- Before editing important config or code, inspect the current state first and avoid assumptions.
- After making changes, run the narrowest relevant verification; if verification cannot be run, state why and describe the remaining risk.

## Plan Mode Safety

- When operating in Plan mode, NEVER call `apply_patch`, Edit, Write, or other mutation tools for source code, configuration, documentation, or other non-plan files.
- If the user requests implementation while in Plan mode, provide the proposed changes and ask them to switch to Build mode. Do not attempt the edit and rely on permission rejection.
- Tool availability does not imply permission to use it. Check the active mode before issuing any mutation tool call.

## Library Documentation

- For library, framework, SDK, API, CLI, or cloud-service questions, use Context7 before answering: resolve the official library ID, then query the current documentation for each distinct concept. Prefer a version-specific ID when the user supplies a version.
- Do not use Context7 for refactoring, scripts written from scratch, business-logic debugging, code review, or general programming concepts. If documentation is unavailable, state that limitation rather than guessing current APIs.
