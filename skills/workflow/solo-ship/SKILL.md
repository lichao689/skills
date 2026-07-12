---
name: solo-ship
description: Fast-merge or deploy completed solo-development work. Use when the user asks to ship, finish, land, merge, release, or deploy; reuse valid implementation evidence and avoid repeating review, tests, packaging, or deployment work.
---

# Solo Ship

## Contract

Carry completed work to one endpoint:

- `merge`: the target commit is on the remote integration branch.
- `deploy`: `merge` plus the narrow required deployment and affected-path proof.

A request only to commit or push uses direct Git. Do not invoke another shipping or deployment orchestrator.

Defaults: `goal=auto path=auto mode=auto evidence=auto`.

| Parameter | Values | Binding |
| --- | --- | --- |
| `goal` | `auto`, `merge`, `deploy` | Deploy/release/production intent selects `deploy`; ship/finish/land/merge selects `merge`. |
| `path` | `auto`, `fast`, `full` | `auto` tries Fast first. Explicit `fast` is a preference, never a waiver. |
| `mode` | `auto`, `quick`, `standard`, `strict`, `release` | Required risk coverage; read `references/risk-levels.md` only when selection is unclear or elevated. |
| `evidence` | `auto`, `reuse`, `fresh` | Prior-evidence treatment; read `references/evidence-policy.md` only for a disputed, partial, or invalidated item. |

Path and mode are independent. `fast + strict` is valid when strict evidence already covers the current commit.

## Choose a Path

Treat prompts such as “Implement completed,” “reuse existing review/tests,” “fast merge,” or “do not repeat verification” as Fast candidates. Actual repository and conversation evidence decides eligibility.

Use Fast when all are true:

- the base and shipping commits are identifiable;
- `HEAD` is committed and staged, unstaged, and untracked state are empty;
- the current conversation contains actual passing review and verification results applicable to `HEAD` and the selected mode;
- no unresolved finding or relevant post-verification edit exists.

A small evidence gap stays on Fast: close only that gap. Use Full only for dirty or uncommitted work, unclear ownership or commits, broadly missing evidence, mixed external edits, or a design/scope change.

## Fast

Target: 3 minutes; report the concrete process bottleneck above 5 minutes.

### 1. Detect

Read repository rules needed for Git integration. Inspect only status, branch/upstream, base, shipping commits, and the existing review/verification results in the current conversation. Derive `goal` and `mode`. The committed tree is the scope fence; do not create a snapshot. For `goal=merge`, do not inspect deployment entries.

Completion: the clean committed `HEAD`, shipping commits, base, required risk coverage, and endpoint are unambiguous.

### 2. Merge

Fetch the remote base. If it has not changed relevant contracts, dependencies, configuration, or call paths, retain evidence. Push the existing commits; do not stage, recommit, rewrite, or rerun valid checks. Use the repository-required PR or merge route, then prove the target commit is reachable from the remote integration branch.

If a relevant evidence gap appears, close only that gap and resume here. Invoke `resolving-merge-conflicts` only for an actual conflict; refresh only conflict-affected evidence.

Completion: the remote integration branch contains the exact verified commit and required CI is passing.

### 3. Finish

For `goal=merge`, stop after remote alignment.

For `goal=deploy`, use the narrowest repository-native deployment covering the affected runtime surface. Use development deployment for immediate engineering validation and formal CI/CD only for milestones or releases. Acquire target-environment health, revision where available, and affected-path proof after deployment.

Completion: the selected endpoint is proven. Report result, reused or supplemented evidence, delivery target, and residual risk in a few lines.

## Full

Use Full only when Fast eligibility fails.

### 1. Bind

Inspect Git/worktree state and establish owned shipping and excluded sets. Read `references/scope-fence.md` only for dirty, ambiguous, overlapping, or concurrent state. Read `references/git-topology-and-cleanup.md` before creating an integration worktree.

Completion: base, ownership, shipping set, excluded set, endpoint, and risk mode are unambiguous.

### 2. Close Gaps

Reuse valid evidence. Derive required risk surfaces and produce only missing or invalidated review and verification. Invoke `code-review` only when both Standards and Spec axes are absent; execute one missing axis directly. Invoke `diagnosing-bugs` only when a related failure needs non-routine diagnosis. After a fix, review its delta and rerun the failed check plus adjacent regression coverage.

Completion: every required risk surface has applicable passing evidence and no unresolved finding remains.

### 3. Package and Finish

Stage exact owned paths, prove staged content matches verified content, commit, push, merge, and prove remote alignment. For `goal=deploy`, perform the same narrow deployment rule as Fast. Read `references/git-topology-and-cleanup.md` only when owned temporary resources exist, and clean only proven owned, clean, merged resources.

Completion: the selected endpoint is proven and excluded or concurrent work remains untouched.

## Blockers

Stop only for an external condition that safe in-scope alternatives cannot resolve: missing permission or credentials, persistently unavailable required infrastructure, unauthorized irreversible data work, inseparable external edits, or incompatible business intent. Report the branch, base, commit, last valid evidence, remote/deployment state, and the single condition needed to resume.
