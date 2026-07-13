# Evidence Contract

Read when prior review, test, build, QA, or runtime evidence may cover the integration candidate.

## Identity

Record the covered commit or content hashes, relevant dependency/configuration inputs, command and environment, result, and covered risk surfaces. Risk surfaces are `standards`, `spec`, `behavior`, `contract`, `architecture`, `security`, `build`, `runtime`, `visual`, and `external-program`.

## Decision

| Class | Predicate | Action |
| --- | --- | --- |
| `reuse` | Covered content, inputs, environment, result, and risk surface still apply | Cite it and prove no relevant drift. |
| `minimal` | Source identity still applies but packaging or an unrelated wrapper changed | Run only the boundary, diff, or affected guard. |
| `refresh` | Relevant source, dependency, configuration, base interaction, environment, or failure state changed | Rerun affected review and verification surfaces. |

Stage, commit, push, or commit-message changes retain evidence. Relevant source, dependency, generated contract, configuration, conflict resolution, or base-interaction changes invalidate only affected surfaces. Failed, blocked, environment-mismatched, or scope-incomplete evidence cannot close a surface.

For `deploy-local`, merge evidence remains reusable, but current-host service state and affected-path behavior must be acquired after deployment.
