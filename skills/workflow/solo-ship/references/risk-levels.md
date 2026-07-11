# Solo Ship Risk Levels

Read this reference for `mode=auto` and whenever discovered scope, failures, or deployment conditions may require escalation. Risk controls verification depth; it never changes the Deploy endpoint.

| Mode | Typical surfaces | Required verification depth |
| --- | --- | --- |
| `quick` | Docs, comments, copy, isolated style, obvious one-file fix | Focused diff review, targeted check, cheap boundaries, deployment and affected post-deploy proof. |
| `standard` | Normal feature or bug fix, local API, bounded refactor, UI workflow | Both review axes, affected tests and static checks, build where applicable, deployment and affected runtime/user-path proof. |
| `strict` | Auth, permissions, security, data, public contracts, broad refactor, CI/deployment, concurrency | Both review axes, full affected-surface matrix, PR/CI status where configured, docs impact, deployment revision proof, broad post-deploy checks. |
| `release` | Production release, multiple coupled surfaces, irreversible or high-blast-radius delivery | Repository-defined release matrix, all required CI and artifact checks, real external-path evidence, deploy job evidence, revision match, canary and critical user journeys. |

Escalate `quick` to `standard` for multi-surface or meaningful user-visible behavior. Escalate to `strict` for data, auth, security, public API, deployment/CI, hidden coupling, or behavior-sensitive conflicts. Escalate to `release` when repository policy declares a release or the delivery spans coupled production surfaces.

Never downgrade an explicit mode. A lower requested mode cannot waive repository policy, objective blockers, deployment, or post-deploy verification. Strict and release are verification depths, not instructions to invoke another orchestrator.

All modes enter Deploy. Only after checking repository rules, CI, scripts, remote configuration, and service documentation may a repository with no deployment entry finish as `deployment: not applicable`.
