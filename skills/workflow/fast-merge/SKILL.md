---
name: fast-merge
description: Integrate completed personal-development work through a local-first Fast Merge. Use when the user asks to merge, finish, land, ship, or close completed work; include deployment to the current host only when explicitly requested.
---

# Fast Merge

## Contract

Default endpoint: the exact verified task commit is reachable from local `main`. Do not fetch, push, open a PR, or deploy unless the user explicitly requests that additional endpoint.

Explicit `push` or remote-sync intent adds the remote-main endpoint. Explicit `deploy-local` intent adds current-host deployment after local integration; it does not imply push. If both are requested, prove both independently.

The PR route is enabled only by repository rules, remote protection, required review, or an existing PR. A commit-only request stops after the commit. A push-only request updates the requested remote ref without inventing deployment or PR work.

Keep Fast Merge as the sole integration orchestrator. Use `code-review`, `diagnosing-bugs`, or `resolving-merge-conflicts` only as bounded leaf work when their condition is present.

## Workflow

### Bind scope and endpoint

Read repository Git and validation rules. Inspect branch or detached state, worktrees, staged/unstaged/untracked files, upstream, remotes, base, stash list, and commits intended for integration.

- Read `references/scope-fence.md` only when state is dirty, mixed, concurrent, or ownership is ambiguous.
- Read `references/repository-profiles/waver.md` only when the repository root is WAVER.
- Ordinary merge, finish, land, ship, or close selects local `main` only.
- Add remote main, PR, or current-host deployment only from explicit intent or an evidenced repository requirement.

Before mutation, the owned paths or commits, excluded state, target refs, validation boundary, and requested endpoints must be unambiguous.

### Verify and commit

Choose validation from the changed behavior and repository policy, using `references/risk-levels.md` when the repository has no sufficient rule. Reuse review, tests, lint, build, and QA evidence while its covered content and environment still match; read `references/evidence-policy.md` only when that applicability is uncertain.

For uncommitted owned work, stage exact paths, inspect the staged diff, run the required checks against that content, and commit it. Preserve external work in place.

Stage, commit, merge commit, and conflict-free rebase are packaging operations and never raise validation depth by themselves. A conflict invalidates evidence only for the affected surface. Every selected task must end with a clean worktree, an immutable commit, passing applicable checks, and no unresolved relevant finding.

### Integrate locally

Prefer the repository-native local-main controller. It should freeze local `main` and each task commit, create an owned temporary integration worktree, merge the task commits, run the bounded validator, then update local `main` only if its checkout is still clean and the frozen base has not drifted.

Do not fetch or push on this default route. Preserve the candidate when external dirtiness or main drift prevents the final fast-forward; use repository recovery rather than overwriting external work. Invoke `resolving-merge-conflicts` only for an actual conflict, then refresh conflict-affected evidence.

Prove the task and integration commits are reachable from local `main`.

### Add explicitly requested endpoints

- For explicit push or remote sync, use the repository's strict remote route and prove the exact commits from remote refs and ancestry, not push output alone.
- For the PR route, push the required feature branch, satisfy required checks and review, merge it, then prove the remote integration ref.
- For `deploy-local`, deploy from the locally integrated commit with the narrowest repository-native current-host command and prove the affected service, API, page, artifact, or user path. Remote synchronization is not a prerequisite.

Treat local integration, remote synchronization, PR completion, and deployment as separate results. Never repeat a proven endpoint merely because another endpoint is pending.

### Clean and report

Read `references/git-topology-and-cleanup.md` only when cleanup is requested or is the normal repository-owned finalization step. Remove a feature worktree or branch only when ownership is proven, it is clean, and its task commit is reachable from the endpoint that preserves it. Local-main reachability is sufficient for a local-only result.

Report task and integration commits, each requested endpoint and proof, reused and fresh evidence, cleaned or preserved resources, external state left untouched, and residual risk. Do not switch or detach the current session worktree unless the user explicitly asks.

## Blockers

Stop only when safe in-scope alternatives cannot resolve missing permission, persistent infrastructure failure, inseparable external edits, an unresolved merge conflict requiring user judgment, or incompatible intent. Report the exact commit, last proven state, preserved resources, and the single condition needed to resume.
