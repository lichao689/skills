---
name: solo-ship
description: Use when the user wants Codex to finish a completed code change or current branch for solo development, especially prompts like ship this, finish the branch, land it, merge it, push it, clean up after merge, or handle review-to-merge closure.
---

# Solo Ship

## Overview

Use this skill as the autonomous closure workflow for solo developer shipping after code changes are already mostly complete. Prefer existing specialized skills for each phase; this skill decides when to invoke them, defines entry and exit conditions, and stops only at explicit risk gates.

Default invocation:

```text
Use $solo-ship to finish the current branch.
```

Default parameters:

```text
mode=auto pr=auto cleanup=auto merge=auto docs=auto approval=stop-rules-only
```

Supported parameters:

| Parameter | Values | Default | Meaning |
| --- | --- | --- | --- |
| `mode` | `auto`, `quick`, `standard`, `strict` | `auto` | Risk level and workflow depth |
| `pr` | `auto`, `true`, `false` | `auto` | Whether to use a GitHub PR review step |
| `cleanup` | `ask`, `auto`, `skip` | `auto` | Whether to delete branches and worktrees after merge |
| `merge` | `auto`, `local`, `pr` | `auto` | Merge locally or through a PR |
| `docs` | `auto`, `skip`, `required` | `auto` | Whether docs or changelog updates are required |
| `approval` | `stop-rules-only`, `ask` | `stop-rules-only` | Whether routine review, commit, push, merge, and safe cleanup decisions should proceed automatically or pause for confirmation |

If parameters conflict, use the safer option and tell the user. For example, `mode=strict pr=false` requires a clear user override before skipping PR review. `approval=stop-rules-only` never overrides Stop Rules.

For detailed mode criteria, load `references/risk-levels.md`.

## Autonomous Closure Contract

The default contract is: do the routine shipping work without asking, and stop only when judgment or safety requires the user.

Proceed automatically when all are true:

- review findings are either fixed or can be recorded as accepted low risk
- verification has passed, or the remaining limitation is explicitly non-blocking for the selected mode
- commit scope can be isolated from unrelated changes
- push, merge, and cleanup targets are unambiguous
- cleanup touches only merged branches, completed remote branches, or clean redundant worktrees

Stop and ask only for Stop Rules, product judgment, credentials, destructive data changes, protected branch policy decisions, unmerged dirty work, or skipping a strict-mode requirement.

## Scope Lock

At invocation, take an entry snapshot of the repository's dirty state and lock the shipping scope to that snapshot.

The locked scope includes:

- files already staged, modified, deleted, renamed, or untracked when the skill begins
- files the skill itself changes to fix review findings, tests, docs, merge conflicts, or verification fallout for that locked scope

Do not review, fix, stage, commit, merge because of, clean up, or otherwise absorb files that become dirty after the entry snapshot unless they were changed by this skill for the locked scope. Treat later changes from users, tools, background processes, or other agents as concurrent external work to preserve, not as new ship scope.

If later external changes overlap a locked-scope file, alter branch topology, or otherwise prevent a safe commit, merge, or cleanup, stop with a checkpoint that names the conflicting paths or state. Do not expand the ship scope to catch up with concurrent work.

## Auto Decision Rules

Use these rules when a parameter is `auto`:

| Decision | Automatic choice |
| --- | --- |
| `mode` | Start from `references/risk-levels.md`; escalate when review, tests, CI, or touched surfaces reveal more risk |
| `pr` | Use PR review for `strict`, existing PRs, branch protection, required CI, large diffs, or repository policy; otherwise skip for quick/standard work after local review and verification |
| `merge` | Use PR merge when PR/CI/policy requires it; otherwise local merge is allowed after push and verification |
| `docs` | Require docs/changelog for user-visible behavior, public API, deployment, or strict-mode changes; otherwise record why docs were skipped |
| `cleanup` | Delete local/remote branches and remove worktrees only after post-merge verification and merged/clean safety checks |

Do not ask the user to choose among these unless more than one safe target remains after inspecting the repository.

## Required Orientation

Begin every run by inspecting the real repository state:

```bash
git status --short --branch
git branch --show-current
git remote -v
git worktree list
git diff --stat
git diff --name-only
git diff --cached --name-only
git ls-files --others --exclude-standard
```

Record these results as the entry snapshot before review, fixes, verification, or staging. Also inspect untracked files before committing or cleaning up. If this is not a git repository, stop and explain the blocker.

Determine:

- current branch and upstream branch
- base branch, usually `main` or `master`
- whether the current directory is a worktree
- dirty, staged, and untracked files
- locked shipping scope from the entry snapshot
- whether a remote exists
- whether a PR already exists
- likely mode if `mode=auto`
- whether this repository has a local shipping profile below

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
| Debug | `superpowers:systematic-debugging`, `diagnosing-bugs` | Failure cause is unclear | Root cause is found and fixed, or blocker is clear |
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

Inspect repository state, record the entry snapshot, lock the shipping scope, and select mode. If the working tree contains changes outside the requested scope, protect them. Do not revert or overwrite user changes.

Classify every dirty or untracked path before staging:

- in scope for this ship
- unrelated user work to preserve
- generated/ignored artifact to leave alone
- ambiguous path that triggers a Stop Rule

During the rest of the run, compare later `git status` and diff checks against the locked scope. Exclude new external dirty paths from review, verification decisions, staging, commits, and cleanup unless this skill created them for the locked scope.

Use explicit path staging for mixed worktrees. Do not use `git add -A` when unrelated changes exist.

### 2. Review

Run a code-review style pass before committing. Prioritize logic correctness, edge cases, old behavior regressions, test gaps, documentation gaps, and whether the commit message can explain why the change exists.

In `quick` mode, a focused diff review is enough. In `standard` and `strict` modes, use the dedicated review skill when available.

### 3. Fix

Address review findings and failing tests. Re-run the smallest meaningful verification after each fix. If a failure is unclear, switch to systematic debugging rather than guessing.

Loop until one of these is true:

- no blocking review findings remain
- remaining findings are explicitly recorded as accepted risk
- a Stop Rule blocks further progress

After nontrivial fixes, re-check the diff before committing.

### 4. Verify Before Commit

Run project-appropriate tests, lint, type checks, builds, or manual checks. Prefer the repository's documented commands. If no test command is discoverable, say so and perform the strongest reasonable local check.

Do not commit until verification has either passed or the remaining risk is explicitly reported.

### 5. Commit and Push

Use a commit message that states why the change was made, not only what changed. Keep unrelated changes out of the commit. Push after the commit unless the user asked for a local-only workflow.

Before committing, run `git diff --cached --stat` and `git diff --cached --name-only`; the staged set must match the reviewed shipping scope. If unrelated changes are already staged, unstage or stop before committing.

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

Before claiming the merge is final, fetch and re-check topology against the remote base. If `origin/main` or `origin/master` advanced while shipping, resolve the new topology and repeat the required verification.

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

If `cleanup=ask`, ask before deleting local branches, remote branches, or worktrees. If `cleanup=skip`, leave cleanup instructions or a concise list of remaining artifacts. If `cleanup=auto`, proceed only when all safety checks are clean and cleanup targets are unambiguous.

When cleanup proceeds automatically, report exactly what was deleted and what was intentionally left behind.

## Repository Profiles

Apply a profile only when orientation proves the checkout matches it.

### WAVER (`D:\codes\WAVER`)

Use this profile when the repository root is `D:\codes\WAVER`.

- Python commands use `conda run -n WAVER <command>`.
- Keep staging boundaries explicit; prefer exact path lists over broad staging.
- If unrelated dirty work exists before merge, preserve it with a documented stash or stop if the scope is ambiguous. Quote stash refs in PowerShell, e.g. `'stash@{0}'`.
- After merging back to `main`, restart the local backend service `WAVER-Backend`.
- Restart or verify the Vite dev server on port `5173` when it is running or frontend preview is part of the work. The command shape is `npm run dev -- --host 0.0.0.0 --port 5173 --strictPort` from `web/`.
- Post-merge runtime proof must be separate checks: `Get-Service WAVER-Backend`, process/port checks for `8000` and `5173`, `http://localhost:8000/api/health`, and the relevant UI route or local Vite URL when frontend verification applies.
- Trust live service/process/HTTP evidence, not stale logs.

## Checkpointing

When stopping before completion, leave a concise recovery checkpoint in the final response:

- current branch, base branch, and upstream
- latest commit hash and push target, if any
- PR URL, if any
- last successful verification command
- exact blocker or Stop Rule
- next safe command or decision needed

## Stop Rules

Stop and ask or report a blocker when:

- the repository has unrelated dirty changes that would be committed or deleted
- post-invocation external changes overlap locked-scope files or make the locked scope impossible to isolate
- the base branch cannot be determined
- tests fail and the root cause is not understood
- merge conflicts require product judgment
- branch or worktree cleanup would delete unmerged or dirty work
- `strict` mode would skip PR, CI, or docs without explicit user approval
- multiple plausible commit, push, merge, cleanup, or deployment targets remain after inspection
- credentials, protected-branch overrides, destructive data changes, or irreversible migrations are required

## Final Response

Report:

- mode used and whether it was explicit or detected
- review result and fixes made
- verification commands and outcomes
- commit hash and push target, if created
- merge target and result, if merged
- post-merge verification result
- cleanup performed or intentionally skipped
- any checkpoint needed to resume

Keep the final concise, but include unresolved risks.
