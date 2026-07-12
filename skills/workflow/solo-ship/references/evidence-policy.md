# Evidence Contract

Read whenever prior review, test, build, CI, QA, or runtime evidence may cover the shipping set.

## Evidence identity

Record enough identity to decide applicability without rerunning the work:

- base commit;
- covered paths and their content hashes;
- relevant tests, dependency manifests, lockfiles, generated contracts, and configuration hashes;
- exact command, environment, exit code, failure count, and result;
- covered risk surfaces;
- whether any relevant input changed afterward.

Risk surfaces are `standards`, `spec`, `behavior`, `contract`, `architecture`, `security`, `build`, `runtime`, `visual`, and `external-program`. Testing does not replace review, and review does not replace behavioral or runtime proof.

## Classification

| Class | Predicate | Action |
| --- | --- | --- |
| `reuse` | Covered content, dependencies, command target, environment, result, and risk surface still apply | Cite the evidence and prove no relevant drift. |
| `rerun-minimal` | Source identity still applies but a packaging boundary or unrelated wrapper changed | Run only content-identity, staged-boundary, `git diff --check`, or the affected guard. |
| `rerun-required` | Relevant source, dependency, configuration, base interaction, environment, scope, or failure state changed | Rerun only affected review axes and verification surfaces. |

Failed, blocked, environment-mismatched, or scope-incomplete evidence is never reusable. A related remaining failure needs a passing baseline comparison proving it predates the shipping content and adds no failure.

## Invalidation matrix

| Change | Review | Test/build | Runtime |
| --- | --- | --- | --- |
| Stage, commit, push, or commit-message only | retain | retain | retain |
| Test-only change | retain unless intent changed | invalidate affected tests | retain |
| Runtime source change | invalidate affected axes | invalidate affected checks | invalidate |
| Dependency, lockfile, generated contract, or build configuration | invalidate affected axes | invalidate affected checks/build | invalidate |
| Repository standard change | invalidate Standards | retain unless tooling changed | retain |
| Specification or acceptance change | invalidate Spec | invalidate affected checks | invalidate affected acceptance |
| Conflict resolution | invalidate affected axes | invalidate affected checks | invalidate |
| Base advance with no relevant contract, dependency, configuration, or call-path effect | retain | retain or minimal guard | retain |
| Base advance with relevant effect | invalidate affected axes | invalidate affected checks | invalidate |
| Redeployment or target-environment change | retain | retain | reacquire from target |

After a bounded fix, invalidate only evidence covering the changed content and its affected surfaces. Fall back from Fast to Full Bind only when intent, design, scope ownership, or excluded paths change.

## Evidence modes

| Mode | Binding |
| --- | --- |
| `auto` | Apply the classifications above. |
| `reuse` | Reuse only evidence satisfying the full `reuse` predicate; otherwise choose the minimal valid rerun. |
| `fresh` | Treat all relevant review and verification as `rerun-required`; prior evidence may select commands but cannot close a surface. |

Post-deploy job, running revision, production health, target user paths, and real external-program execution are target-environment evidence. Acquire them after deployment whenever `goal=deploy`; pre-merge development evidence cannot satisfy them.
