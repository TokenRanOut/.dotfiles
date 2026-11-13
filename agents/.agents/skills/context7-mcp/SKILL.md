---
name: context7-mcp
description: >
  Use this skill when a task requires current third-party library, framework, SDK, API, CLI, or cloud-service documentation for API usage, configuration, or version-specific behavior. Do NOT use for business-logic debugging, ordinary refactoring, code review, general programming, or merely mentioning a framework.
---

# context7-mcp

Use Context7 when answering requires current third-party API, configuration, or version documentation instead of relying on training data.

## When to Use This Skill

Activate this skill when the user:

- Asks setup or configuration questions ("How do I configure Next.js middleware?")
- Requests code whose correctness depends on library API usage ("Write a Prisma query for...")
- Needs API references ("What are the Supabase auth methods?")
- Needs version-specific behavior or migration documentation.

A framework name alone is not a trigger. Do not use for business-logic debugging, ordinary refactoring, code review, standalone scripts that require no third-party API documentation, or general programming concepts. If a separate third-party API documentation question arises, scope the lookup to that question.

## How to Fetch Documentation

### Step 1: Resolve the Library ID

Call `resolve-library-id` with:

- `libraryName`: The library name extracted from the user's question
- `query`: What to look up in the library's documentation (improves relevance ranking)

### Step 2: Select the Best Match

From the resolution results, choose based on:

- Exact or closest name match to what the user asked for
- Higher benchmark scores indicate better documentation quality
- If the user mentioned a version (e.g., "React 19"), prefer version-specific IDs

### Step 3: Fetch the Documentation

Call `query-docs` with:

- `libraryId`: The selected Context7 library ID (e.g., `/vercel/next.js`)
- `query`: What to look up in the library's documentation, scoped to a single concept

If the user's question spans multiple distinct concepts (e.g. routing and auth and caching), make a separate `query-docs` call per concept with the same library ID, unless the question is about how the concepts interact — combined queries dilute ranking and return shallow results for each topic.

### Step 4: Use the Documentation

Incorporate the fetched documentation into your response:

- Answer the user's question using current, accurate information
- Include relevant code examples from the docs
- Cite the library version when relevant

## Guidelines

- **Be specific**: Describe what to look up in the library's documentation, but keep each query to a single concept
- **One topic per query**: Split multi-topic questions into separate `query-docs` calls — resolve the library ID once, then query per concept, unless the question is about how the concepts interact
- **Version awareness**: When users mention versions ("Next.js 15", "React 19"), use version-specific library IDs if available from the resolution step
- **Prefer official sources**: When multiple matches exist, prefer official/primary packages over community forks
- **Unavailable documentation**: State the limitation if no relevant documentation is available; do not guess current APIs.
