# Plan: integrate upstream while preserving the owner's starter workflow

Date: 2026-10-28
Status: approved
Approval: owner explicitly authorized integration, four adaptations, new-project verification and push in this chat.

## Scope and acceptance

- Merge upstream bced4fe into the owner's fork; retain planning commands and their statuses.
- Keep business context tracked in private company repositories. Installer defaults to private-git policy; explicit local policy supports public projects. Preserve existing files and never silently untrack them. Explain that the installer does not verify remote visibility or publish data.
- Adapt bootstrap and the installed new-project skill to adaptive AUTOPILOT and a durable provenance file. New companies use only fresh GitHub fork clones and private repositories. Keep required workflow, scanners, license and tests usable after template cleanup.
- Preserve fail-fast required secrets and Telegram token coverage.
- Accept only the exact standard macOS /var -> /private/var and /tmp -> /private/tmp aliases; reject arbitrary symlinks as before.
- Test installation, preservation, idempotence, default macOS temp paths and unsafe symlink rejection. Test bootstrap with isolated Git/GitHub shims, including private create/push arguments and failures. After push, smoke-test a fresh GitHub clone with --no-remote. Do not create a real company or test GitHub repository.

## Execution and limits

One implementation phase and one release verification phase. No model API spend, production, external messages or actual company creation. Up to two review/fix rounds per defect, then reassess the cause. Keep all test projects under work/ or OS temporary directories. Rollback uses Git history; do not rewrite remote history. Use an independent review before final commit; judge each finding against evidence.

## Phases

- [x] Integrate code, docs, skill and regression tests; full suite and independent review.
- [ ] Commit and push to origin/main after checks; verify remote SHA and fresh-clone new-project smoke run; sync the local skill with a backup.

## Checkpoint

Merge in progress; upstream files selected as baseline for conflicting files. No remote writes yet. Next: review this plan, implement adaptations and verify.


## Independent plan review

Reviewer integration_review accepted the scope and requested explicit ignore-conflict refusal, nonzero GitHub failures and preservation of LICENSE. Judge: accepted all three; directly supported by existing bootstrap and installer behavior. Implemented in code and regression tests.

## Implementation review decisions

Independent reviewer integration_review found: (1) multi-path git check-ignore cannot use --quiet; accepted and changed to captured non-quiet output with operational error handling, (2) stale business-index untracking instruction; accepted and replaced with private Git policy, (3) duplicate-plan risk in legacy commands; accepted and updated discovery and continuation semantics. Existing regression test covers ignore refusal; startup and canonical prompt references were inspected after edits.

Re-review: initial findings resolved. Accepted final stale INDEX footer correction. Rejected the proposed extra CI unittest step: scripts/security-audit.sh already runs the entire unittest suite at line 9 before scanning. CI invokes this wrapper on both matrix platforms; a second step would duplicate the suite. Focused installer run: 17 tests passed on macOS with default temporary paths.

## Pre-push verification

`bash scripts/security-audit.sh`: 41 tests passed on the owner's Mac using its default temporary directory; 123 index blobs scanned without findings. `bash -n scripts/bootstrap-new-project.sh`, `git diff --cached --check` and skill-creator quick_validate passed. Both installed skill aliases now read the updated skill; the original file is backed up outside the repository. No real company repository was created. Next: push and smoke-test the live fork with --no-remote.
