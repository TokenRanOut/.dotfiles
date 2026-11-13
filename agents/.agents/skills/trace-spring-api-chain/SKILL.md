---
name: trace-spring-api-chain
description: >
  Trace cross-layer calls, business flows, data access, and external calls from Spring backend HTTP, RPC, MQ, or job entry points.
  Use for end-to-end flow analysis, not non-Spring projects, isolated single-class analysis, reviews requiring no call tracing, or code generation.
tags: spring,tracing,call-chain,backend
---

# trace-spring-api-chain

Follow `code-explore` for exploration scope, delegation contracts, and citation conventions. Reuse it if already loaded; otherwise load it. This skill adds only Spring-specific tracing dimensions.

## Workflow

1. **Identify the goal and scope**: Confirm the entry point and desired business endpoint. Determine layers from build manifests, modules, and package structure rather than assuming a fixed architecture.
2. **Locate the entry point**: Search by entry identifier and extract protocol, path or queue, inputs, and return values. Read [spring-entry-patterns.md](references/spring-entry-patterns.md) when the entry is unclear or detailed search patterns are needed; list and confirm remaining ambiguous candidates.
3. **Collect evidence layer by layer**: Locate actual implementations from call sites and injected types. Verify calls, argument flow, branches, exceptions, and return paths through data access or remote boundaries. Read small file sets directly; delegate independent complex branches when useful rather than splitting by class or line count.
4. **Handle boundaries**: Distinguish synchronous calls, asynchronous submission, event publication, and remote requests. Apply the rules below to stop or continue; do not draw asynchronous work as part of the same synchronous stack.
5. **Report and verify**: Check the flow against evidence coverage and identify unresolved implementations, configuration, and relationships. Agent counts do not establish completeness.

## Spring evidence dimensions

Extract only dimensions present in the flow. Include relevant rows in delegated tasks without repeating the general contract.

| Dimension | Evidence to confirm |
|---|---|
| Injection and AOP | Interface implementations, `@Qualifier` / `@Primary`, conditional beans, profiles, proxy interception, and self-invocation |
| Locking | Local/distributed lock locations, keys, timeouts, and release paths |
| Transactions | `@Transactional` or programmatic boundaries, propagation, read-only settings, commit/rollback, and exception handling |
| Caching | Read/write/invalidation locations, cache names, keys, and TTL from configuration and implementation |
| Data access | Mapper/Repository SQL, tables, filters, and operation types; inspect configured MyBatis interceptor effects when relevant |
| MQ | Producer/consumer locations, topics/queues, exchanges, routing keys, payloads, and correlation fields |
| Events and async | Event types, listeners, `@Async`, thread pools, scheduling configuration, and submission/execution boundaries |
| RPC / HTTP | Feign, Dubbo, gRPC, or other target services, signatures, URLs, fallbacks, and circuit-breaker configuration |
| Retry and compensation | Retry counts, backoff, exception matching, `@Recover`, catch-based compensation, or Saga rollback |

## Asynchronous and external boundaries

- For synchronous-request analysis, stop at async submission, MQ publication, or remote calls; identify targets and unexpanded follow-up work.
- For end-to-end business analysis, continue into in-scope consumers, listeners, or async methods. Establish connections through message types, routing, subscriptions, and correlation fields; present subsequent execution separately.
- Event publication is not inherently asynchronous. Determine behavior from listeners, executors, and actual configuration; mark it unknown when unverifiable.
- Proxy interfaces such as Feign require no local generated implementation; verify declarations and fallbacks. Continue into remote sources only when explicitly in scope and matched to the actual target.
- Apply `code-explore` public-signature and explicit-exception boundaries to external dependencies. Report missing consumers, remote repositories, or configuration as evidence gaps rather than filling them by inference.

## Common pitfalls

- Resolve multiple injected implementations using qualifiers, conditions, and active configuration; preserve candidate branches if the environment is unknown.
- Do not treat proxies as business implementations. Same-class self-invocation usually bypasses Spring proxies; annotations alone do not prove `@Transactional` or `@Async` takes effect.
- Track visited methods and call edges to avoid cycles while preserving distinct key branches within a method.
- Do not skip intermediate layers. State where tracing stops if SQL or remote-contract mapping lacks evidence.

## Results and verification

By default, return brief business context, entry identifiers, the core flow with file/line citations, boundaries, and unresolved questions. Indent trees by actual call depth and show asynchronous continuations separately. Add validation, data operations, external calls, or key-field tables as needed; do not repeat all citations in both prose and reference tables.

- [ ] Support each key call edge with call-site and target evidence; cover relevant branches, exceptions, and return paths.
- [ ] Match entry metadata, implementation selection, and key argument flow to source; label inferences.
- [ ] Support transactions, locks, caches, retries, and related behavior with evidence rather than annotations or names alone.
- [ ] Mark async, event, MQ, and RPC boundaries; stop or continue according to the user's goal and authorized scope.
- [ ] Include project/module, symbol, file path, and line numbers in citations; keep diagrams consistent with prose.
- [ ] State endpoints, unresolved configuration, and uncovered scope. Evidence may come from direct reads or verified delegated summaries.
