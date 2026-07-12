# Solo Ship Risk Levels

Read for `mode=auto` and whenever scope, failures, or deployment conditions may escalate verification. Repository policy is the source of truth for its test matrix.

| Mode | Typical surfaces | Required depth |
| --- | --- | --- |
| `quick` | Docs, comments, copy, isolated style, obvious small fix | Reuse valid review/checks; close only missing axes and cheap boundaries. |
| `standard` | Normal feature or bug fix, local API, bounded refactor, UI workflow | Reuse valid review and affected checks; run build or runtime checks only for uncovered surfaces. |
| `strict` | Auth, permissions, security, data, public contracts, broad refactor, CI/deployment, concurrency | Independent affected-surface review, full affected matrix, required CI, and target evidence for `goal=deploy`. |
| `release` | Formal release, coupled production surfaces, irreversible or high-blast-radius delivery | Repository release matrix, required CI/artifacts, deployment revision, canary, and critical journeys. |

Escalate `quick` for meaningful multi-surface behavior, `strict` for data/auth/security/public contracts/deployment/hidden coupling, and `release` for a formal or coupled production release. Risk changes verification depth; `goal` independently selects integration or deployment.
