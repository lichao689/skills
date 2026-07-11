---
name: solo-ship
description: Use when the user asks to ship, land, release, deploy, finish a completed branch, or carry completed work through production verification in a solo-development repository.
---

# Solo Ship

## Core Contract

Solo Ship is the sole orchestrator for completed solo-development work. Its single endpoint is merged, deployed, and production-verified work. A merge, commit, or push is never completion. A request only to commit or push uses direct Git commands and does not trigger this skill.

Do not invoke another shipping, landing, publishing, finishing, or deployment orchestrator. Use direct Git, GitHub, CI, deployment, HTTP, service, and browser tools or repository commands. Make routine technical choices autonomously, choosing the safest reversible repository-native route. Do not ask the user to select workflow options.

Every mode reaches Deploy. End with `deployment: not applicable` only after repository rules, CI, scripts, remote configuration, and service documentation prove that no deployment entry exists.

## Parameters

Defaults: `mode=auto scope=auto evidence=auto pr=auto merge=auto cleanup=auto docs=auto approval=objective-blockers-only`.

| Parameter | Values | Meaning |
| --- | --- | --- |
| `mode` | `auto`, `quick`, `standard`, `strict`, `release` | Verification depth; read `references/risk-levels.md` for auto selection or escalation. |
| `scope` | `auto`, `session`, `entry`, `explicit` | Owned paths; read `references/scope-fence.md` when dirty, concurrent, or ambiguous state exists. |
| `evidence` | `auto`, `reuse`, `fresh` | Prior-evidence treatment; read `references/evidence-policy.md` whenever prior evidence exists. |
| `pr` | `auto`, `true`, `false` | PR use, constrained by repository policy. |
| `merge` | `auto`, `local`, `pr` | Repository-permitted integration route. |
| `cleanup` | `auto`, `skip` | Safe owned-local-resource cleanup. |
| `docs` | `auto`, `skip`, `required` | Factual documentation affected by the shipping set. |

Explicit parameters may deepen checks but cannot change the endpoint or waive an objective blocker. Apply a matching file under `references/repository-profiles/` only when the repository root proves the match.

## Matt Leaf Skills

Solo Ship fixes bounded review findings itself and retains control throughout. Only these Matt leaf skills may receive a bounded phase:

| Phase | Leaf skill | Pinned input | Return condition |
| --- | --- | --- | --- |
| Review | `code-review` | fixed point, commit list, diff, specification sources, repository standards | Standards and Spec axes both have verdicts. |
| Failure | `diagnosing-bugs` | failing command, raw output, target symptom, relevant scope | Root cause is fixed with regression evidence, or an objective external blocker is proven. |
| Conflict | `resolving-merge-conflicts` | merge target, both commit intents, conflict paths, specification sources | All conflicts are resolved and merge checks pass. |

Parallelize the two review axes only when host and repository rules permit; otherwise run them sequentially in the main thread. Git, GitHub, CI, deployment, health, and browser work is performed directly.

## Workflow

### 1. Orient

Read repository rules and inspect branch, upstream, remotes, worktrees, staged/unstaged/untracked state, stash, base candidates, existing PR and CI, and deployment entry points. Record the Entry Fence before changing anything. Build the Session Fence and classify every path using `references/scope-fence.md`. Select risk level and matching repository profile. Use forward-slash paths in instructions and records.

Completion: branch, upstream, base, worktree ownership, entry dirty set, shipping set, excluded set, risk level, PR/CI status, and deployment entry each have one unambiguous conclusion.

### 2. Review

Pin the fixed point, commits, shipping diff, intent source, and standards. Invoke `code-review` for separate Standards and Spec verdicts. If no independent specification exists, use the user request, commit messages, and stable repository rules as the minimal intent source. Fix findings and rerun affected checks; use direct commands for routine corrections.

Completion: every finding is fixed, proven false by evidence, or is an objective external blocker; no unverified risk is accepted by the agent.

### 3. Verify before package

Maintain the evidence record defined in `references/evidence-policy.md`. Run repository-classified targeted tests, static checks, builds, and cheap boundary checks. Release risk runs the repository release matrix; real external paths require runtime evidence. A related failure may be treated as pre-existing only with a passing baseline comparison; otherwise invoke `diagnosing-bugs` and return here.

Completion: every risk surface in the shipping set has fresh passing evidence or a baseline comparison proving remaining failures are unrelated; staged set and reviewed set have not drifted.

### 4. Package and publish

Stage explicit shipping paths, then inspect staged status, name list, and diff. Commit by coherent theme and push the exact target. Create or update a PR when policy, protection, or CI requires it. Poll required CI and review feedback; fix failures and repeat review or verification where the tree changed.

Completion: commits contain only the shipping set; the remote commit matches the intended local commit; required CI and review pass.

### 5. Merge

Read `references/git-topology-and-cleanup.md`. Fetch and re-check remote base immediately before integration. Use the repository-permitted PR or local merge route. If base advanced, recompute the diff and rerun the evidence made stale. Invoke `resolving-merge-conflicts` only for actual conflicts, then return here.

Completion: the target commit is reachable from the integration branch, the merge result matches the remote, and no conflict remains unresolved.

### 6. Deploy

Identify merge-triggered CI/CD, a repository manual deployment command, or an explicit service-update process. Execute or wait for it with bounded retries, then read the real deployment status and running revision. Do not infer success from merge status.

Completion: when a deployment target exists, its job succeeds and evidence proves the target version or commit is running; when none exists, repository facts prove `deployment: not applicable` after entry-point investigation.

### 7. Post-deploy verify

Use the matching repository profile to check affected service state, ports, health endpoints, critical APIs, target pages, browser console, user paths, and necessary canary evidence. Compare the running revision with the merged commit. A regression returns to `diagnosing-bugs`, verification, packaging, merge, and deployment as needed.

Completion: target user paths and critical health evidence pass, deployed revision matches the merged commit, and no regression introduced by this work remains.

### 8. Cleanup and report

Apply `references/git-topology-and-cleanup.md`. Remove only owned, clean, merged local worktrees and branches. Preserve remote branches by default, preserve every stash, and leave excluded or concurrent changes untouched. Produce the report below.

Completion: every deletion target passes ownership, cleanliness, and merged checks; the final report lists deployment, acceptance, commits, merge, cleanup, and excluded files.

## Objective Blockers

Stop only after exhausting safe in-scope alternatives when one external condition prevents progress: unavailable credentials, license, token, or protected-branch permission; persistently unavailable CI, deployment platform, or target service after bounded retries; no determinable deployment target after full entry-point investigation; an unauthorized irreversible data operation; an overlapping external edit that cannot be isolated without overwriting others; or incompatible business intent that specifications, tests, and current product facts cannot resolve.

Do not present a routine option menu. Leave one recovery checkpoint containing branch, base, latest commit, remote and PR state, last passing verification, blocker evidence, and the single external condition needed to resume.

## Final Report

Report mode and scope; evidence reused and rerun; review verdicts and fixes; verification commands and results; commits and push target; PR/CI and merge result; deployment job and running revision or proven `deployment: not applicable`; post-deploy health and user-path evidence; cleanup; excluded files; and any objective-blocker checkpoint.
