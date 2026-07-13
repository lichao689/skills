# Fast Merge Risk Levels

Read when repository policy does not already select validation depth or when failures reveal wider risk. Repository policy remains authoritative.

| Mode | Typical surfaces | Required depth |
| --- | --- | --- |
| `quick` | Documentation, copy, isolated style, obvious small fix | Exact diff check and relevant guard; reuse applicable evidence. |
| `standard` | Normal feature or bug fix, local API, bounded refactor, UI workflow | Affected tests plus required lint, build, type, or contract checks. |
| `strict` | Auth, permissions, security, data, public contracts, concurrency, broad cross-layer change | Independent affected-surface review, full affected matrix, and integration checkpoint. |

Risk changes validation depth, not delivery route. A formal release or broad remote deployment is a separate workflow with its repository release matrix.
