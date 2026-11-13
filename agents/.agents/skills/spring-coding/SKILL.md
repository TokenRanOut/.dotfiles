---
name: spring-coding
description: Apply Spring coding conventions when adding, modifying, or refactoring Spring-managed classes, or writing technical designs for their responsibilities, dependencies, and injection. Excludes read-only call-chain analysis, general conceptual questions, and Java coding unrelated to Spring.
---

# spring-coding

## Applicable conventions

- Load and follow `java-coding` before applying these Spring-specific conventions; reuse it if already loaded.
- Determine whether affected classes are new or existing, and inspect explicit project coding conventions and existing Lombok usage.
- Give explicit project conventions precedence over this skill's defaults. Historical field injection alone does not require field injection in new classes.
- Apply these rules to dependency designs and example code for Spring classes in technical designs as well.

## Interfaces and implementations

- Introduce a Service interface when required by an actual contract, polymorphism, dependency isolation, or established project conventions. In that case, define the interface and method contract before the implementation, including in technical designs.
- Decide whether Spring-managed classes need interfaces from their responsibilities and project conventions; do not mechanically pair interfaces and implementations.

## Repository responsibilities

- Keep Repositories responsible for data access and persistence, not business logic.
- Name methods for data operations, query conditions, or persistence outcomes rather than business actions or decisions. Retain necessary business terms for entities, fields, and states.
- Place business validation, calculations, state transitions, and cross-Repository business orchestration in Services or the corresponding domain objects.
- Keep query-condition construction, pagination, sorting, and persistence mapping in Repositories.

## Business orchestration and data reuse

- Use entry points or orchestration methods to organize retrieval, validation, and execution with explicit order and branches.
- Limit query methods to data retrieval rather than business validation; status filters in query conditions are data queries.
- Make validation methods evaluate supplied data without obtaining external data or context themselves.
- Use already retrieved and validated data in execution methods for persistence, assembly, or updates; do not fetch it again.
- Prefer collecting data required by the current flow whose query conditions are already known before business decisions and processing.
- Reuse query results within the current flow. Prefer batch retrieval over loop queries and repeated database access.
- Retrieve data needed only by particular branches, dependent on intermediate results, or requiring fresh state at the corresponding step; avoid unnecessary eager queries.
- Let Services or the business orchestration layer organize these steps and data reuse; retain data-access responsibilities in Repositories.

## Dependency injection

- Use constructor injection for new Spring-managed classes, preferably with `private final` dependency fields; do not use field injection.
- Preserve an existing class's injection style when modifying it unless migration is explicitly requested or necessary for the current change.
- Follow project conventions when choosing explicit constructors or existing Lombok patterns. Do not introduce dependencies solely for constructor injection.
