---
name: solo-ship
description: Personal developer shipping workflow for Codex. Use when the user wants to review, fix, test, commit, push, optionally review a PR, merge to main or master, verify after merge, and clean up local or remote branches and git worktrees for solo development. Coordinates existing review, GitHub, shipping, verification, documentation, and cleanup skills with explicit risk modes and safety checks for destructive git operations.
---

# Solo Ship

## Overview

Use this skill as an orchestration workflow for solo developer shipping. Prefer existing specialized skills for each phase; this skill decides when to invoke them, defines entry and exit conditions, and prevents cleanup before the work is safely merged and verified.

Default invocation:

```text
Use $solo-ship to finish the current branch.
```

Default parameters:

```text
mode=auto pr=auto cleanup=ask merge=auto docs=auto
```

Supported parameters:

| Parameter | Values | Default | Meaning |
| --- | --- | --- | --- |
| `mode` | `auto`, `quick`, `standard`, `strict` | `auto` | Risk level and workflow depth |
| `pr` | `auto`, `true`, `false` | `auto` | Whether to use a GitHub PR review step |
| `cleanup` | `ask`, `auto`, `skip` | `ask` | Whether to delete branches and worktrees after merge |
| `merge` | `auto`, `local`, `pr` | `auto` | Merge locally or through a PR |
| `docs` | `auto`, `skip`, `required` | `auto` | Whether docs or changelog updates are required |

If parameters conflict, use the safer option and tell the user. For example, `mode=strict pr=false` requires a clear user override before skipping PR review.

For detailed mode criteria, load `references/risk-levels.md`.

## Required Orientation

Begin every run by inspecting the real repository state:

```bash
git status --short --branch
git branch --show-current
git remote -v
git worktree list
git diff --stat
git diff --name-only
```

Also inspect untracked files before committing or cleaning up. If this is not a git repository, stop and explain the blocker.

Determine:

- current branch and upstream branch
- base branch, usually `main` or `master`
- whether the current directory is a worktree
- dirty, staged, and untracked files
- whether a remote exists
- whether a PR already exists
- likely mode if `mode=auto`

After orientation, state the detected mode and why in one concise update.

## Mode Selection

Use `mode=auto` unless the user explicitly provides a mode.

- Use `quick` for docs, comments, tiny local fixes, and low-risk single-surface changes.
- Use `standard` for normal features, bug fixes, UI behavior changes, API additions, and local refactors.
- Use `strict` for database migrations, auth, permissions, payments, deployment, CI, public API changes, data deletion, broad refactors, security-sensitive changes, or anything likely to affect existing users.

Escalate mode when the diff or test failures reveal higher risk. Do not downgrade an explicit user-provided mode unless the user asks.

## Skill Orchestration

Use existing skills by opening their `SKILL.md` when they are relevant and available. If a referenced skill is unavailable, use the closest manual workflow and mention the fallback in the final response.

| Phase | Skills to use | Use when | Exit condition |
| --- | --- | --- | --- |
| Review | `review` (`gstack-review` only if the host exposes that alias) | Any non-cleanup shipping task | Findings are addressed or explicitly accepted |
| Fix | `superpowers:receiving-code-review` | Review or tests find issues | Fixes are implemented and diff is rechecked |
| Debug | `superpowers:systematic-debugging`, `diagnose` | Failure cause is unclear | Root cause is found and fixed, or blocker is clear |
| TDD | `tdd`, `superpowers:test-driven-development` | New behavior, bug fixes, or `strict` mode | Tests demonstrate the intended behavior or non-use is justified |
| Verify | `superpowers:verification-before-completion`, `health` | Before commit, before merge, and after merge | Relevant verification commands have run and results are known |
| Commit and Push | `github:yeet`, `yeet`, or explicit `git` + `gh` CLI fallback | Ready to create commits and push | Commit scope is correct, message explains why, push succeeds |
| PR Review | `github:github`, `github:gh-address-comments`, unprefixed equivalents, or explicit `gh` CLI fallback | `pr=true`, `merge=pr`, existing PR, or `strict` mode | PR diff is reviewed and comments are resolved or recorded |
| CI Fix | `github:gh-fix-ci`, `gh-fix-ci`, or explicit `gh run` / `gh pr checks` fallback | GitHub checks fail | CI cause is fixed or external blocker is identified |
| Merge | `ship` | Standard merge workflow | Work is merged to `main` or `master` |
| Deploy Merge | `land-and-deploy` | Deployment or post-merge canary matters | CI, deploy, and user-visible verification are complete |
| Docs | `document-release`, `changelog`, or manual changelog note | `docs=required`, `strict` mode, or user-visible behavior changes | Docs/changelog updated or explicit no-doc rationale is recorded |
| Cleanup | `superpowers:finishing-a-development-branch`, `careful`, `guard` | After successful post-merge verification | Redundant branch/worktree cleanup is complete or intentionally skipped |

Host naming differs. Codex plugin skills may be visible with prefixes such as `github:yeet` or `superpowers:test-driven-development`; Claude Code may expose local skills without those prefixes, or may require a manual `gh` CLI fallback. Treat a phase as ready when one suitable skill or explicit fallback is available. If availability is unclear, run `setup`.

## Workflow

### 1. Orient

Inspect repository state and select mode. If the working tree contains changes outside the requested scope, protect them. Do not revert or overwrite user changes.

### 2. Review

Run a code-review style pass before committing. Prioritize logic correctness, edge cases, old behavior regressions, test gaps, documentation gaps, and whether the commit message can explain why the change exists.

In `quick` mode, a focused diff review is enough. In `standard` and `strict` modes, use the dedicated review skill when available.

### 3. Fix

Address review findings and failing tests. Re-run the smallest meaningful verification after each fix. If a failure is unclear, switch to systematic debugging rather than guessing.

### 4. Verify Before Commit

Run project-appropriate tests, lint, type checks, builds, or manual checks. Prefer the repository's documented commands. If no test command is discoverable, say so and perform the strongest reasonable local check.

Do not commit until verification has either passed or the remaining risk is explicitly reported.

### 5. Commit and Push

Use a commit message that states why the change was made, not only what changed. Keep unrelated changes out of the commit. Push after the commit unless the user asked for a local-only workflow.

### 6. Optional PR Review

Use PR review when:

- `pr=true` or `merge=pr`
- `mode=strict`
- a PR already exists
- CI or repository policy requires a PR
- the diff is large enough that a second review surface is useful

If `pr=auto`, skip PR review for clearly quick work after local review and verification.

### 7. Merge

Merge only after review and verification are complete. Use `ship` for the normal case. Use `land-and-deploy` when deployment, canary checks, or live service verification matter.

### 8. Post-Merge Verify

After merge, switch to the base branch, update it, and re-run the key verification command(s). This is mandatory unless the user explicitly asks to stop before merge.

### 9. Cleanup

Cleanup is allowed only after post-merge verification succeeds or the user explicitly accepts the residual risk.

Before deleting anything, verify:

```bash
git status --short --branch
git branch --merged
git worktree list
```

For a worktree, inspect that worktree's `git status --short --branch` before removal. Delete local branches only when they are merged. Delete remote branches only when they correspond to the completed branch and are no longer needed.

If `cleanup=ask`, ask before deleting local branches, remote branches, or worktrees. If `cleanup=skip`, leave cleanup instructions or a concise list of remaining artifacts. If `cleanup=auto`, proceed only when all safety checks are clean and the user explicitly requested auto cleanup.

## Stop Rules

Stop and ask or report a blocker when:

- the repository has unrelated dirty changes that would be committed or deleted
- the base branch cannot be determined
- tests fail and the root cause is not understood
- merge conflicts require product judgment
- branch or worktree cleanup would delete unmerged or dirty work
- `strict` mode would skip PR, CI, or docs without explicit user approval

## Final Response

Report:

- mode used and whether it was explicit or detected
- review result and fixes made
- verification commands and outcomes
- commit hash and push target, if created
- merge target and result, if merged
- post-merge verification result
- cleanup performed or intentionally skipped

Keep the final concise, but include unresolved risks.
