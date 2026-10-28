---
name: new-project
description: Bootstrap a new company or project from merc1305/claude-code-starter, create a private GitHub repository and start the adaptive Claude Code/Codex workflow. Use for new-project requests; starter maintenance does not itself authorize company creation.
---

# New project from the owner's starter

The implementation lives in `scripts/bootstrap-new-project.sh` in the GitHub fork. Fetch it fresh; do not reconstruct the bootstrap manually or use a stale local checkout.

## Inputs and boundaries

- Use `merc1305/claude-code-starter` only when creating a project. Do not merge upstream during project creation. Explicit starter-maintenance requests may update the fork.
- Collect the kebab-case project name, destination (default `~/sources/<name>`) and idea only if not already provided. If the current empty directory is the intended destination, use it directly.
- Before creating a remote, ensure the user has approved the exact name and location. Existing explicit approval counts; do not ask again. Always create a PRIVATE repository.
- `.business/` stays tracked in private company repositories for backup and history. Do not exclude or untrack it. Never put passwords, tokens or personal client data there. Verify remote visibility before writing confidential business context or pushing it.

## Run the canonical bootstrap

After authorization, fetch and execute:

```bash
task_tmp=$(mktemp -d)
gh api repos/merc1305/claude-code-starter/contents/scripts/bootstrap-new-project.sh \
  -H "Accept: application/vnd.github.raw" > "$task_tmp/bootstrap.sh" &&
bash "$task_tmp/bootstrap.sh" <target-dir> <repo-name>
```

The script clones the current fork, makes two local commits, creates the private repository, verifies privacy and pushes. Use `--no-remote` only for an explicitly local project or isolated verification. Check exit status. If it fails, inspect the actual local and remote state and report the failed step; do not blindly rerun, create another repository, or claim success. Fix repeatable bootstrap defects in the starter, not through ad hoc reconstruction of a company.

## Start from the user's context

Read the generated `CLAUDE.md` or `AGENTS.md`, `docs/workflow.md` and `AUTOPILOT.md`. Verify `.starter/provenance.json` records the fork and commit. Confirm `.business/INDEX.md` is tracked and the remote is private (or the project intentionally stays local).

Write the supplied idea, known facts, uncertainties and immediate goal in `.business/INDEX.md`, preserving existing useful content. Do not store it in AUTOPILOT frontmatter. Ask only questions that affect the next decision; use the adaptive entry for idea, architecture, code or continuation. Progress and approval live in the active plan/checkpoint. There is no required numbered onboarding and no `completed: false` trigger.

If the project is outside the current chat directory, open a new session there so its instructions load. Explain the destination; do not imply the current session changed directory merely because bootstrap ran.
