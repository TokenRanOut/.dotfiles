# Description Optimization Guide

## When to read this reference

Read this reference when systematically reducing false activations or missed activations. For small wording changes, walk through representative positive and negative scenarios without starting a full optimization loop.

## Routing principles

The skill's `name` and `description` support selection before the body loads. The body supplies execution details. Describe the capability, user goal, and scope rather than repeating the full procedure.

Judge activation by task intent and skill scope, not keyword overlap, task difficulty, or whether the task exceeds the model's general capabilities. Write descriptions in English and follow the target platform's perspective and length requirements. Do not require one opening phrase across platforms.

## Design activation cases

Store cases in `evals/trigger_queries.json` when a reusable test set is useful:

```json
[
  { "query": "Improve this skill's description so it stops activating for unrelated requests.", "should_trigger": true },
  { "query": "Use the existing PDF skill to extract this invoice.", "should_trigger": false }
]
```

Choose case counts according to scope. For formal optimization, approximately 20 queries can be a starting point, with both positive and negative cases. If there is not enough data for independent sets, report executed tests as small-sample execution results and state that no independent final test was performed. Reserve "scenario walkthrough" for static inspection without execution. Do not present either as evidence of generalization.

### Positive cases

- Vary wording: formal, conversational, misspelled, or abbreviated.
- Mix explicit domain names with requests that express the same intent without those names.
- Mix concise requests with richer context and single-step tasks with multi-step workflows.
- Include only tasks actually within scope, not tasks where the skill might merely be helpful.

### Negative cases

Prioritize adjacent but out-of-scope tasks that share terms or concepts with the skill. For a skill-writing guide, "Run this existing skill on my report" is a stronger negative than an unrelated arithmetic question.

Determine labels from the specific skill's contract. Editing spreadsheet formulas, for example, may be positive or negative depending on whether that skill covers spreadsheet transformation or only a narrower analytical workflow.

### Realistic context

Use realistic paths, column names, values, user context, and conversational phrasing where they affect selection. Preserve non-English queries when testing multilingual user intent; keep test documentation in English.

## Measure actual activation

Use the following procedure rather than assuming one client's command or log format works everywhere:

1. Verify the current client invocation and execution-trace schema before building an adapter. If the client does not expose reliable evidence of skill loading, stop activation-rate measurement, report the missing observability, and limit conclusions to a static scenario walkthrough. Do not classify unobservable loading as non-activation.
2. Confirm the target skill is discoverable in the test environment.
3. Start each query in a fresh context without explicitly loading the target skill. Explicit loading measures execution, not automatic selection.
4. Inspect the supported skill-loading event in the trace. Do not infer activation from the final answer merely mentioning the skill.
5. Classify each run as activated, not activated, or a runtime error. Treat command failures, malformed traces, and parsing failures as errors rather than non-activations.
6. Repeat cases when needed to measure variability; three runs per case can be an initial budget.
7. Report false activations, missed activations, and runtime errors separately, alongside the number of runs.

For valid runs, activation rate is `activated_runs / valid_runs`. If converting rates into binary outcomes, choose the threshold before tuning; a threshold of 0.5 is one possible convention, not a universal standard. A high activation rate on a negative case is a failure.

## Separate development from final testing

When independent final testing is warranted and enough cases are available, fix the split before tuning. Keep near-duplicate versions of one scenario in the same set to prevent leakage.

- **Development set:** inspect failures and use them to revise the description.
- **Validation set (optional):** compare candidates during development. Once used for selection, its results are development evidence, not independent generalization evidence.
- **Final test set:** reserve queries and results from tuning and candidate selection. Run it only after freezing the final version and evaluation rules.

For generalization claims, reserve an independent final test set when enough cases are available; omit the optional validation set if unnecessary. Cover positive, negative, and adjacent intents in each set; avoid imposing a fixed split ratio. For local optimization or insufficient samples, use development cases without requiring a final test set, and report the results and limitations without claiming generalization. Agree on metrics, budget, and stopping conditions in advance.

## Optimization loop

For read-only reviews or evaluations, analyze the current description and any authorized test results, report findings and proposed improvements, and stop. Use the following modification loop only when changes are authorized.

1. Evaluate the current description on the development set.
2. Inspect missed activations and false activations together with traces. Check scope, labels, environment, and ambiguous wording before attributing failures to the description.
3. Revise the description to express the general intent behind failing cases. Avoid appending exact query keywords or broadening scope merely to make tests pass.
4. Try structural rewrites when incremental edits stop helping. Respect platform length limits.
5. Repeat within the agreed budget. Stop expanding rules when there is no meaningful improvement.
6. Select and freeze a candidate using development evidence and optional validation results.
7. If an independent final test was reserved for a generalization claim, run it and report both positive and negative outcomes, errors, and sample-size limitations. Otherwise, report development results and limitations, and state that no independent final test was performed.

If final-test feedback informs another revision, treat that set as development data and reserve a new independent test set for the next final report.

## Example

```yaml
# Too broad
description: Helps with skills and agent tasks.

# Specific capability and activation conditions
description: >
  Guides the creation, improvement, and evaluation of agent skills, including
  trigger descriptions and supporting resources. Applies when creating, modifying,
  reviewing, or evaluating skills, not when merely executing an existing skill's workflow.
```

## Final checks

1. Update the intended `description` field only for authorized creation or modification tasks; otherwise, leave it unchanged. Validate frontmatter and platform limits.
2. Check consistency with the body's capability and boundaries.
3. Record the development and optional validation evidence used for selection.
4. Report independent final-test results only when that test was actually reserved and executed.
