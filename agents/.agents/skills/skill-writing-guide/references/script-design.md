# Script Design Reference

## When to read this reference

Read this reference when creating, modifying, or reviewing executable scripts bundled with a skill. For reviews, use the rules as inspection criteria without modifying scripts or treating the validation steps as authorization to execute them.

## Choose the simplest reliable implementation

Use an existing tool directly when it already performs the task reliably. Add a bundled script when repeated processing, deterministic validation, or a cohesive multi-step operation justifies it. Prefer the project's existing language and runtime instead of introducing another ecosystem for convenience.

Verify current runtime and package behavior before providing executable commands or templates. Do not assume automatic dependency installation or version-qualified imports work identically across runtimes.

## Declare dependencies and reproducibility requirements

- Declare required runtimes, external tools, and relevant minimum versions.
- Distinguish exact versions, compatible version ranges, and locked dependency graphs. A range such as `>=4.12,<5` or `~> 1.16` is not an exact pin.
- Pin tool versions where execution must be reproducible; avoid unbounded `latest` dependencies.
- Use a supported lockfile when transitive dependency resolution must also be reproducible. An exact direct dependency alone does not lock the full graph.
- Reuse project dependency declarations and lockfiles when available rather than maintaining a separate dependency system inside the skill.

For a standalone Python script, inline dependency metadata can declare the runtime and direct dependencies:

```python
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "beautifulsoup4==4.12.3",
# ]
# ///

from bs4 import BeautifulSoup

html = "<h1>Welcome</h1>"
print(BeautifulSoup(html, "html.parser").select_one("h1").get_text())
```

Use a runner supporting this metadata, such as `uv run scripts/extract.py`. Verify the installed runner's locking workflow if a fully reproducible dependency graph is required. Treat this snippet as an illustrative pattern, not a recommendation to replace an existing project's dependency version.

## Design a non-interactive interface

- Accept inputs through explicit arguments, files, or documented environment variables. Do not wait for TTY prompts, password dialogs, or confirmation menus.
- Reject missing or ambiguous required inputs with a useful error and usage guidance. Use enums where the valid choices form a closed set.
- Provide concise `--help` output describing required inputs, defaults, output behavior, and meaningful exit codes.

```text
Usage: scripts/process.py [OPTIONS] INPUT_FILE

Process input data and produce a summary report.

Options:
  --format FORMAT  Output format: json, csv, table (default: json)
  --output FILE    Write output to FILE instead of stdout
  --verbose        Print progress to stderr

Examples:
  scripts/process.py data.csv
  scripts/process.py --format csv --output report.csv data.csv
```

## Make output and failures actionable

- Write result data to stdout and progress, warnings, and diagnostics to stderr.
- State what failed, the received value when safe to disclose, the expected input, and how to correct it.
- Return a nonzero status on failure. Document distinct failure codes only when callers need to distinguish them.
- Keep output sizes predictable. Return a summary by default for large results, support pagination where appropriate, or write complete output to a file and report its path.

```text
Error: --format must be one of: json, csv, table.
Received: xml
```

## Handle retries and state changes deliberately

- Make retries idempotent where the operation permits it. Define existing-output behavior explicitly rather than silently overwriting files or suppressing errors.
- Provide a `--dry-run` mode for destructive or state-changing operations when a reliable preview is possible.
- Require explicit authorization for destructive behavior and use safe defaults. Do not treat a script's capability as permission to run it.
- Preserve applicable tool and environment restrictions, including read-only database access where required.

## Validate executable changes

1. Check argument parsing and `--help` behavior.
2. Run representative successful and invalid-input cases in an authorized environment.
3. Verify stdout, stderr, exit statuses, and output artifacts.
4. Test retry, existing-output, and preview behavior when applicable.
5. Report the commands and results. If execution is unavailable or outside scope, state what was checked statically and what remains untested.
