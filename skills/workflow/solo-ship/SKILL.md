---
name: solo-ship
description: Integrate or deploy completed solo-development work. Use when the user asks to ship, finish, land, merge, release, deploy, or carry completed work through production verification; reuse valid development evidence and rerun only invalidated coverage.
---

# Solo Ship

## Contract

Solo Ship validates completed work and carries it to one endpoint:

- `integrate`: the target commit is on the remote integration branch.
- `deploy`: `integrate` plus successful deployment, running-revision proof, and affected-path verification.

A request only to commit or push uses direct Git commands. Do not invoke another shipping or deployment orchestrator. Use direct Git, GitHub, CI, deployment, HTTP, service, and browser tools or repository commands.

Defaults: `goal=auto mode=auto scope=auto evidence=auto pr=auto merge=auto cleanup=auto docs=auto`.

| Parameter | Values | Binding |
| --- | --- | --- |
| `goal` | `auto`, `integrate`, `deploy` | `auto` selects `deploy` for deploy/release/production intent and `integrate` for ship/finish/land/merge intent. |
| `mode` | `auto`, `quick`, `standard`, `strict`, `release` | Verification depth; read `references/risk-levels.md` for selection or escalation. |
| `scope` | `auto`, `session`, `entry`, `explicit` | Owned paths; read `references/scope-fence.md` when state is dirty, concurrent, or ambiguous. |
| `evidence` | `auto`, `reuse`, `fresh` | Prior-evidence treatment; read `references/evidence-policy.md` whenever prior evidence exists. |
| `pr` | `auto`, `true`, `false` | PR use, constrained by repository policy. |
| `merge` | `auto`, `local`, `pr` | Repository-permitted integration route. |
| `cleanup` | `auto`, `skip` | Safe cleanup of owned temporary resources. |
| `docs` | `auto`, `skip`, `required` | Factual documentation affected by the shipping set. |

Explicit parameters may deepen checks but cannot waive repository policy or an objective blocker. Apply a matching file under `references/repository-profiles/` only when the repository root proves the match.

## Leaf Skills

Solo Ship retains control. Invoke a leaf only when its branch fires:

| Branch | Leaf skill | Trigger | Return condition |
| --- | --- | --- | --- |
| Review gap | `code-review` | Both Standards and Spec coverage are missing or invalid | Both axes have verdicts. When only one axis is missing, execute that axis directly instead of invoking the full leaf. |
| Failure | `diagnosing-bugs` | A related check fails and routine diagnosis is insufficient | Root cause is fixed with regression evidence, or an objective external blocker is proven. |
| Conflict | `resolving-merge-conflicts` | An actual merge conflict exists | Conflicts are resolved and affected evidence is refreshed. |

Git, GitHub, CI, deployment, health, and browser work is direct. Review fixes invalidate only affected evidence unless they expand scope or change the design.

## 1. Bind

Read repository rules. Inspect branch, upstream, remotes, worktrees, staged/unstaged/untracked state, stash, base candidates, existing PR/CI, and deployment entries. Select `goal`, risk, repository profile, shipping set, and excluded set. Record the Entry Fence before mutation. Use the lightweight repository-native snapshot for clear ownership; escalate to the content-recoverable fence in `references/scope-fence.md` only for ambiguous, overlapping, or concurrent state. Read `references/git-topology-and-cleanup.md` before creating or using an integration worktree.

Collect prior review, test, build, CI, QA, and runtime evidence. Pin its base, covered content, command, environment, result, and risk surfaces according to `references/evidence-policy.md`.

Completion: every observed path has one ownership class; goal, risk, base, shipping set, excluded set, deployment entry, and existing evidence each have one unambiguous conclusion.

## 2. Validate

Derive the required risk surfaces from the shipping diff. Classify each evidence item as `reuse`, `rerun-minimal`, or `rerun-required`. Reuse valid development evidence; Git packaging operations alone do not invalidate it. Invoke `code-review` only for missing or invalid Standards/Spec axes. Run only checks needed to close uncovered or invalidated risk surfaces.

After a fix, review the fix delta and rerun the failed check plus adjacent regression coverage. Rebind scope only when the fix expands intent, changes the design, touches excluded paths, or overlaps external work.

Completion: every required risk surface has applicable passing evidence; Standards and Spec each have a valid verdict; the verified content identity and residual risks are recorded.

## 3. Integrate

Stage exact shipping paths. Prove the staged content matches the verified content; if it does, do not repeat review or tests. Inspect staged status, name list, and diff, then commit by coherent theme and push the exact target. Use a PR only when requested or required by repository policy, protection, or CI.

Fetch and compare the remote base immediately before merge. A base advance invalidates only evidence affected through changed contracts, dependencies, configuration, or call paths. Resolve actual conflicts through the conflict branch, refresh affected evidence, and merge by the repository-permitted route. Prove the target commit is reachable from the remote integration branch.

Completion: commits contain only the shipping set; staged and verified content agree; required CI passes; the target commit is on the remote integration branch and local/remote results agree.

## 4. Finish

For `goal=integrate`, run only repository-required post-merge health or local-service refresh checks.

For `goal=deploy`, identify merge-triggered CI/CD, a repository deployment command, or an explicit service-update process. Execute or wait with bounded retries. Prove the deployment job, running revision, and affected service/API/page/user path. Production and real external-program evidence must be obtained from the target environment after deployment; development evidence cannot substitute for it.

Read `references/git-topology-and-cleanup.md` before cleanup. Clean only owned temporary resources whose ownership, cleanliness, and merged state are proven. Preserve excluded and concurrent changes. Apply repository cleanup policy when it overrides generic branch-retention defaults.

Completion: the selected endpoint is proven, required post-endpoint checks pass, owned temporary resources are cleaned or explicitly preserved for recovery, and excluded changes remain untouched.

## Objective Blockers

Stop only after exhausting safe in-scope alternatives when one external condition prevents progress: unavailable credentials or protected-branch permission; persistently unavailable CI, deployment platform, or target service; unauthorized irreversible data work; an overlapping external edit that cannot be isolated; or incompatible business intent that current facts cannot resolve.

Leave one recovery checkpoint containing goal, branch, base, latest commit, remote/PR/deployment state, last valid evidence, the single condition needed to resume, excluded paths, and any preserved snapshot cleanup instruction.

## Report

Default to a compact report:

- result: integrated/deployed commit and target;
- evidence: reused, minimally rerun, and rerun checks;
- delivery: push, merge, and deployment revision when applicable;
- preserved: excluded or concurrent changes;
- residual risk or blocker.

Expand commands, findings, CI, deployment, cleanup, and recovery details only for `strict`, `release`, failure, or blocker cases.
