# Solo Ship Risk Levels

Use this reference when `mode=auto` is requested or when the workflow needs to justify escalation.

## Quick

Use `quick` when all are true:

- change is small and easy to inspect in one focused diff pass
- no database, auth, permissions, deployment, CI, security, public API, or data deletion surface
- no broad refactor or cross-module contract change
- verification can be local and targeted

Examples:

- documentation or comments
- typo fixes
- small copy changes
- isolated style adjustment
- one-file low-risk bug fix with obvious behavior

Minimum workflow:

```text
orient -> focused review -> targeted verify -> commit/push -> merge -> post-merge verify -> safe cleanup or checkpoint
```

PR review is optional when local review and verification are sufficient.

## Standard

Use `standard` for normal feature and bugfix work that has meaningful behavior but no high-risk surface.

Examples:

- normal frontend or backend feature
- local API addition that is not public or compatibility-critical
- bug fix with tests
- local refactor with limited blast radius
- UI workflow change that affects existing screens

Minimum workflow:

```text
orient -> review skill -> fix -> verify -> commit/push -> optional PR review -> merge -> post-merge verify -> safe cleanup or checkpoint
```

Use PR review when the diff is large, the repository already uses PRs, or the user asks for it.

## Strict

Use `strict` when the change can break users, data, releases, security, or project infrastructure.

Triggers:

- database migration or persistent data shape change
- auth, permissions, secrets, payments, or security-sensitive code
- deployment, infrastructure, CI, packaging, or release automation
- public API, SDK, protocol, file format, or backward compatibility change
- data deletion, destructive scripts, or irreversible migrations
- broad refactor across multiple ownership boundaries
- concurrency, caching, background jobs, or async behavior with production impact
- failing CI or unclear test failures during shipping

Minimum workflow:

```text
orient -> review skill -> TDD or focused tests -> fix -> full verification -> PR review -> CI fix if needed -> docs/changelog check -> merge -> post-merge verification -> guarded cleanup
```

Strict mode requirements:

- Do not silently skip PR review.
- Do not silently skip CI status inspection when a remote PR or GitHub workflow exists.
- Consider docs or changelog for user-visible behavior.
- Use guarded cleanup and preserve unmerged work.

## Escalation Rules

Escalate from `quick` to `standard` when:

- more than one subsystem changes
- behavior changes in user-visible code
- tests need nontrivial updates
- review reveals edge cases not covered by the initial fix

Escalate from `standard` to `strict` when:

- data, auth, deployment, CI, public API, or security surfaces appear
- tests fail in a way that suggests hidden coupling
- merge conflicts touch behavior-sensitive files
- cleanup would remove worktree or branch state that is not obviously redundant

Do not downgrade a user-requested `strict` run. If a user requests `quick` but the diff is high risk, explain the mismatch and use `standard` or `strict` unless the user explicitly overrides the risk.
