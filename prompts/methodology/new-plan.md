# Plan an approved result from existing context

Use the shared workflow linked from CLAUDE.md/AGENTS.md. A plan covers one agreed result, potentially many functions and phases.

```prompt
Read the supplied idea or task and the relevant business index, architecture and existing checkpoints. Search for an active plan in the existing architecture as well as plans/. If an existing plan covers this result, continue or amend it; do not create a duplicate.

Ask only for information that changes the next decision and is not already available. Record facts separately from hypotheses and estimates. Create plans/YYYY-MM-DD-name.md from the template only when no suitable plan exists.

Include the full outcome, scope, technical choices and rejected alternatives, phases with acceptance criteria, tests, permissions, limits and rollback. Preserve the stage journal and checkpoint. An approved existing scope stays approved; substantial changes need approval.

For a new plan, use status черновик, obtain independent review and judge the findings before asking for owner approval. For continuation, retain the real status and resume the checkpoint after verifying it against code and tests.

Respond to the owner in Russian.
```

Optional next stage: prompts/methodology/plan-critique.md or /plan.
