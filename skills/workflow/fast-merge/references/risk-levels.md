# Fast Merge Risk Levels

Read when repository policy does not already select validation depth or when failures reveal wider risk. Repository policy remains authoritative.

| Mode | Typical surfaces | Required depth |
| --- | --- | --- |
| `quick` | Documentation, rules, copy, isolated style, obvious small fix | Exact diff check, mirror/hash check when applicable, and relevant targeted guard; do not add checkpoint or build. |
| `standard` | Normal feature or bug fix, local API, bounded refactor, UI workflow | Affected tests plus required lint, build, type, or contract checks. |
| `strict` | Auth, permissions, security, data, public contracts, concurrency, broad cross-layer change | Independent affected-surface review, full affected matrix, and integration checkpoint. |

Risk changes validation depth, not delivery route. A formal release or broad remote deployment is a separate workflow with its repository release matrix.

Stage, commit, merge commit, push, and conflict-free rebase do not raise risk. A merge conflict invalidates only evidence for the conflict-affected files and interfaces. Use an integration checkpoint only for multi-task runtime integration, `strict` risk, or an explicit user/repository requirement.
