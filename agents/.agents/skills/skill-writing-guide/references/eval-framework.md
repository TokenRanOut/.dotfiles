# Evaluation Framework Reference

## When to read this reference

Read this reference when establishing formal skill evaluation, comparing versions, or investigating repeated regressions. Choose evaluation depth according to risk and change scope; do not require this framework for every wording or routing edit.

## Define test cases

Start with two or three realistic cases and inspect initial results before expanding the suite. Vary wording and include a relevant boundary case, such as malformed input or a request exposing an ambiguous decision.

Store reusable cases in `evals/evals.json` when useful:

```json
{
  "skill_name": "csv-analyzer",
  "evals": [
    {
      "id": 1,
      "prompt": "Find the top 3 months by revenue in data/sales.csv and make a bar chart.",
      "expected_output": "A chart showing the three highest-revenue months with labeled axes and values matching the input.",
      "files": ["evals/files/sales.csv"],
      "assertions": [
        "The output includes a readable chart image",
        "The selected months and revenue values match the top three months computed from the input",
        "Both axes identify their quantity and applicable units"
      ]
    }
  ]
}
```

## Isolate runs and baselines

1. Run each case in a clean context using an independent session or permitted subagent. Prevent state from previous runs from influencing the result.
2. When measuring skill benefit, run the same case with the skill and without it. Explicitly load the target skill in the with-skill condition and verify successful loading in the execution trace; providing its path alone is not sufficient. Record loading failures as evaluation errors. Verify that the baseline cannot automatically load the target skill. For automatic activation tests, follow [description-optimization.md](description-optimization.md) instead and do not preload the target skill.
3. When comparing skill versions, explicitly load a fixed snapshot of the old version and the new version in their respective conditions. Record each snapshot's version identifier or content hash, including supporting resources used by the case, and verify which snapshot each run loaded. Do not add a without-skill baseline unless measuring the skill's benefit also requires it.
4. Keep inputs, model settings, tool availability, and evaluation rules comparable across conditions. Record relevant environmental differences.
   For cases that change files, caches, or other state, give each run an independent input copy and isolated mutable state, or restore the same initial snapshot before each run. Separate output directories alone do not isolate shared inputs or environment state. Do not require additional state isolation for cases verified to be read-only.
5. For local regression checks, run only the affected scenarios when a full baseline comparison is unnecessary.

Use a workspace outside the skill directory when storing formal evaluation artifacts:

```text
skill-name-workspace/
└── iteration-1/
    ├── eval-top-months-chart/
    │   ├── with_skill/
    │   │   ├── outputs/
    │   │   ├── timing.json
    │   │   └── grading.json
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    └── benchmark.json
```

Specify the skill path, task, input files, and output directory for execution. Record available timing and token measurements without inventing missing telemetry:

```json
{
  "total_tokens": 3800,
  "duration_ms": 45000
}
```

## Design meaningful assertions

Define core assertions from the user's goal before inspecting candidate outputs. Refine omissions using development cases, not to accommodate a candidate's mistakes. Freeze assertions and grading rules before final testing.

Prefer observable correctness:

- "The output file parses as valid JSON."
- "Chart values agree with the input data."
- "The proposed change preserves the existing authentication requirement."

Avoid vague or incidental requirements:

- "The output is good."
- "The response contains exactly the phrase 'Total Revenue'."
- "The report contains at least three recommendations," unless that count is part of the actual request.

Use human review for quality dimensions that assertions do not capture well, such as overall usefulness, writing, or visual composition.

## Grade with evidence

Report PASS or FAIL for each evaluable assertion and cite concrete output evidence. Mark assertions requiring an output artifact as FAIL when the agent does not produce that artifact, including when the agent ends normally without completing the task. Record evaluation errors separately when test-environment failures, damaged traces, or inaccessible evidence prevent judgment. Report those errors and their treatment in score denominators explicitly; do not silently exclude task failures from pass rates.

```json
{
  "assertion_results": [
    {
      "text": "The output includes a readable chart image",
      "status": "pass",
      "evidence": "The chart image opens successfully, and its labels and plotted values are legible."
    },
    {
      "text": "Both axes identify their quantity and applicable units",
      "status": "fail",
      "evidence": "The horizontal axis identifies months, but the vertical axis does not identify revenue or currency."
    },
    {
      "text": "The selected months and revenue values match the top three months computed from the input",
      "status": "error",
      "evidence": "The evaluation harness could inspect the chart but could not retrieve the source data for independent calculation because its input storage service was unavailable."
    }
  ],
  "summary": {
    "passed": 1,
    "failed": 1,
    "errors": 1,
    "total": 3,
    "evaluable": 2,
    "pass_rate": 0.5
  }
}
```

Use `status` consistently with one of `pass`, `fail`, or `error`. In the summary, `total` includes errors, `evaluable` equals `passed + failed`, and `pass_rate` uses `evaluable` as its denominator. Retain all summary fields even when their counts are zero, and use `null` for `pass_rate` when no assertions are evaluable. Report errors alongside the pass rate and retain the same denominator policy across compared conditions. An artifact the agent failed to produce remains a task failure, not an evaluation error.

Review assertions that are always satisfied, always fail, or cannot be reliably judged. Preserve important correctness and safety checks even when they pass consistently.

For optional blind comparisons, hide version identities and apply the same predefined rubric to both outputs. Use this to supplement assertions, not replace correctness checks.

## Aggregate results

Summarize comparable results, costs, variability, errors, and sample sizes:

Define the pass-rate unit and weighting before evaluation: for example, pooled assertion outcomes or equally weighted per-case rates. State which repeated runs each standard deviation summarizes and how evaluation errors affect denominators. Use the same aggregation rules across compared conditions so differences remain interpretable and reproducible.

```json
{
  "run_summary": {
    "with_skill": {
      "pass_rate": { "mean": 0.83, "stddev": 0.06 },
      "time_seconds": { "mean": 45.0, "stddev": 8.0 },
      "tokens": { "mean": 3800, "stddev": 400 }
    },
    "without_skill": {
      "pass_rate": { "mean": 0.33, "stddev": 0.10 },
      "time_seconds": { "mean": 32.0, "stddev": 4.0 },
      "tokens": { "mean": 2100, "stddev": 300 }
    },
    "delta": {
      "pass_rate": 0.50,
      "time_seconds": 13.0,
      "tokens": 1700
    }
  }
}
```

Interpret pass-rate differences as percentage-point changes. Weigh added time and tokens against the importance of the observed improvement rather than assuming any fixed trade-off is worthwhile. Do not claim meaningful variability estimates from a single run.

## Inspect patterns and traces

- Investigate cases where both conditions fail: check the task, assertion, environment, and outputs.
- Inspect cases where the skill succeeds and the baseline fails to identify its concrete benefit.
- Investigate unstable results and time or token outliers using execution traces.
- Check conflicting instructions, missing skill loads, tool limitations, and ambiguous wording before assigning a cause to ignored instructions.
- Review actual outputs as well as scores to catch failures outside predefined assertions.

Record actionable human feedback, such as "Months are sorted alphabetically instead of chronologically," rather than "The chart feels wrong."

## Iterate and finalize

For read-only reviews or evaluations, analyze the outputs, scores, and traces, report findings and proposed improvements, and stop. Use the following modification loop only when changes are authorized.

1. Combine failed assertions, human feedback, and execution traces into a focused improvement proposal.
2. Generalize from failures instead of patching individual prompts. Explain necessary reasons and remove instructions that add no value.
3. Bundle repeated computation in a tested script when reuse or reliability justifies it.
4. Review and apply the changes, then rerun affected development or regression cases. Expand coverage for broad changes.
5. Grade, aggregate, and review outputs. Stop when the agreed goals or budget are reached or further changes no longer help.
6. For generalization claims, freeze the version and evaluation rules before running an independent reserved final test set.

Treat results used for editing or version selection as development evidence. If final-test feedback leads to changes, reserve a new independent test set before making another final generalization claim.
