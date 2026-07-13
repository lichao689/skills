---
name: fast-merge
description: Integrate completed personal-development work through a local-first Fast Merge. Use when the user asks to merge, finish, land, ship, or close completed work; include deployment to the current host only when explicitly requested.
---

# Fast Merge

## Contract

Default endpoint: the exact verified task commit is reachable from the remote integration branch. Deployment is a separate event.

Explicit `deploy-local` endpoint: complete the default endpoint, then run the narrowest repository-native deployment on the current host and prove the affected path.

The PR route is an escalation selected only when repository rules, remote protection, required review, or an existing PR require it. Otherwise integrate locally and push the integration commit directly. A commit-only or push-only request uses direct Git.

Keep Fast Merge as the sole integration orchestrator. Use `code-review`, `diagnosing-bugs`, or `resolving-merge-conflicts` only as bounded leaf work when their condition is present.

## Steps

### 1. Bind

Read repository Git and validation rules. Inspect branch or detached state, worktrees, staged/unstaged/untracked files, upstream, remotes, base, stash list, and commits intended for integration. Read `references/scope-fence.md` only for dirty, mixed, concurrent, or ambiguous ownership. Read the WAVER profile when the repository root is WAVER.

Select the endpoint from explicit intent: ordinary ship/finish/land/merge means default merge; only an explicit request to deploy on this machine adds `deploy-local`.

Completion: the owned task commits or paths, excluded state, integration branch, route, validation boundary, and endpoint are unambiguous.

### 2. Verify and Commit

Reuse review, tests, lint, build, and QA evidence while its covered content and environment still match. Read `references/evidence-policy.md` when applicability is uncertain. Close only missing or invalidated risk surfaces using repository-native checks and `references/risk-levels.md`.

For uncommitted owned work, stage exact paths, inspect the staged diff, run the required checks against that content, and commit it. Preserve external work in place.

Completion: every task worktree selected for integration is clean, every task result has an immutable commit, applicable checks pass, and no relevant finding remains unresolved.

### 3. Integrate Locally

Fetch the remote integration branch and freeze its commit plus every task commit. Prefer the repository-native integration controller. Otherwise create an owned temporary integration worktree at the frozen remote base, merge task commits with explicit merge commits, and run the bounded integration validator before finalizing the candidate.

On the local route, keep feature branches local and prepare one verified integration commit for the remote integration branch. On the PR route, prepare and push the feature branch required by that route. Invoke `resolving-merge-conflicts` only for an actual conflict, then refresh conflict-affected evidence.

Completion: one immutable verified integration candidate exists, contains every selected task commit exactly once, and is based on the current remote integration branch.

### 4. Push and Prove

On the local route, push the integration candidate directly to the remote integration branch. On the PR route, push the feature branch, satisfy required checks and review, merge it, then fetch the integration branch.

Prove success from remote refs and ancestry rather than push output alone. Treat remote integration and root-checkout fast-forward synchronization as separate results; never repeat a confirmed remote merge because a local checkout cannot yet sync.

Completion: the remote integration branch contains the exact task commits and verified integration commit, required remote checks pass, and remote ancestry is recorded.

### 5. Close

For the default endpoint, record deployment as not requested. For `deploy-local`, use the narrowest current-host deployment command covering the changed runtime surface, then prove service state and the affected API, page, artifact, or user path. Remote release and broad release validation remain separate user-directed work.

Clean only worktrees and branches that are proven owned, clean, and merged; read `references/git-topology-and-cleanup.md` before cleanup. Report commits, integration route, remote proof, reused and fresh evidence, optional local-deployment proof, preserved external state, and residual risk.

Completion: the selected endpoint is proven, owned temporary resources are safely closed or explicitly preserved, and unrelated work remains untouched.

## Blockers

Stop only when safe in-scope alternatives cannot resolve missing permission, persistent infrastructure failure, inseparable external edits, an unresolved merge conflict requiring user judgment, or incompatible intent. Report the exact commit, last proven state, preserved resources, and the single condition needed to resume.
