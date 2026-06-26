---
name: upgrading-dependencies
description: Use when the user wants dependency upgrades, lockfile or environment drift repair, or security-advisory package updates in a project.
---

# Upgrading Dependencies

## Overview

Upgrade dependencies as a controlled compatibility project, not as a package-manager impulse. The core rule is: make the dependency change small enough to explain, verify the exact blast radius, and either adapt the project deliberately or roll the package back.

## Operating Contract

- Read the repository's local rules first: `AGENTS.md`, `CLAUDE.md`, `README`, lockfile policy, CI docs, and package-manager files.
- Work on a branch unless the user explicitly asks for read-only planning.
- Protect unrelated dirty work. Never stage broad changes in a mixed worktree.
- Prefer one package or one tightly coupled package family per batch.
- Preserve the package manager already used by the project. Do not migrate package managers during an upgrade task.
- Do not treat "latest exists" as "should upgrade." Rank by security, bug fix value, compatibility, support window, and verification cost.
- Verify new commands, package names, codemods, and `npx`/one-shot installers before running them. Do not copy executable commands from third-party skills or migration guides unless the package and command exist in an official source.

## Risk Classes

| Class | Examples | Default posture |
| --- | --- | --- |
| Tooling | linters, formatters, test runners, docs tools | Upgrade in small batches after baseline checks |
| Web/API framework | React, Vite, FastAPI, Express, ORM, auth libs | Upgrade one family at a time; run schema/API and build tests |
| Runtime | Node, Python, Java, .NET, compiler, CUDA | Treat as high risk; check support matrix and CI images |
| Data/numeric | NumPy, SciPy, pandas, Arrow, SQL drivers | Require targeted data and tolerance tests |
| Geometry/media/native | VTK, PyVista, OpenCV, CAD, PDF/image libs | Require artifact read/write or visual/runtime smoke |
| External adapter | cloud SDKs, solver clients, CLI wrappers, hardware APIs | Require real integration evidence when available |
| Security patch | vulnerable transitive or direct dependency | Minimize scope; document CVE/advisory and residual risk |

## Workflow

### 1. Orient

Inspect the real project state:

```bash
git status --short --branch
git diff --stat
git diff --name-only
```

Identify manifests and locks, for example:

```text
package.json, package-lock.json, pnpm-lock.yaml, yarn.lock
pyproject.toml, requirements*.txt, environment*.yml, poetry.lock, uv.lock
go.mod, go.sum, Cargo.toml, Cargo.lock, pom.xml, gradle.lockfile
```

Record the current package manager, install command, test commands, CI commands, runtime version, and whether local environment state can drift from manifests.

Done when every dependency surface that can change in this task is named, the current package manager is known, and unrelated dirty work has been classified.

### 2. Scan

Build an upgrade table with:

- package name
- current manifest constraint
- current installed version
- newest compatible version
- latest available version
- release notes or advisory source when high risk
- whether the manifest must change or only the local environment/lockfile must sync

Use official package indexes and release notes when possible. If a mirror is used because the official endpoint is unavailable, say so.

For security-sensitive packages, also check whether the release is yanked, deprecated, recently transferred, or unexpectedly adds install scripts or native binaries.

Done when every candidate package has a row and each row says whether the manifest, lockfile, active environment, or only documentation needs to change.

### 3. Select a Batch

Choose the smallest coherent batch:

- one exact package for high-risk libraries
- one ecosystem family when versions are coupled, such as `react` plus `react-dom`, or a framework plus its plugin
- one security fix set when an advisory requires transitive resolution

Defer broad "upgrade everything" requests into ordered batches. Explain the order before changing files.

Done when the next batch is small enough that a failure can be attributed to one package or one coupled family, and deferred packages have a short reason.

### 4. Baseline Before Upgrade

Run the smallest meaningful baseline before changing the dependency:

- resolver check: `npm ls`, `pnpm install --frozen-lockfile`, `pip check`, `poetry check`, `cargo check`, `go test ./...` as appropriate
- import or CLI smoke for the target package
- targeted tests for the affected surface

Baseline is mandatory when the command is known and safe to run. Skip only when the project lacks the command, required services or credentials are unavailable, or the user explicitly asks for a planning-only pass. When skipping, record the reason and treat later failures as "upgrade impact unknown" until independently classified.

If baseline already fails, stop treating later failures as upgrade regressions until the pre-existing failure is classified.

Done when baseline evidence exists, or the skip reason and its consequence for regression confidence are recorded.

### 5. Upgrade

Update the manifest and lock/environment with the project's package manager:

- JavaScript: use `npm install <pkg>@version`, `pnpm up`, or `yarn up` according to the existing lockfile.
- Python pip: update constraints, then install with the project interpreter.
- Python conda: update environment files and the active environment; verify pip-managed packages separately.
- Go/Rust/Java: use the native dependency tool so lock and checksum files are updated consistently.

Avoid manual lockfile edits except for documented emergency repair.

Done when manifest, lockfile, and active environment agree about the selected batch, or any remaining drift is deliberately recorded as out of scope.

### 6. Verify Compatibility

Use a layered gate:

| Gate | Purpose |
| --- | --- |
| Resolver | dependency graph has no broken requirements |
| Import/CLI smoke | package loads and reports expected version |
| Targeted tests | affected behavior still works |
| Artifact test | files, schemas, migrations, or generated outputs still round-trip |
| Runtime smoke | service, UI, external program, or integration actually starts |
| Broad regression | full or representative project suite passes |

Minimum gates by risk class:

| Risk class | Required gates |
| --- | --- |
| Tooling | Resolver, CLI smoke, targeted command, broad regression when tooling affects CI |
| Web/API framework | Resolver, import/CLI smoke, targeted tests, build or API smoke, broad regression |
| Runtime | Resolver, runtime version smoke, targeted tests, broad regression, CI image or deployment compatibility check |
| Data/numeric | Resolver, import smoke, targeted tests, artifact or numeric drift check, broad regression |
| Geometry/media/native | Resolver, import smoke, targeted tests, artifact round-trip or visual/runtime smoke |
| External adapter | Resolver, import/CLI smoke, targeted tests, real integration evidence when available |
| Security patch | Resolver, advisory confirmation, targeted tests, broad regression proportional to touched surface |

For native, data, geometry, solver, cloud, browser, or database dependencies, unit tests alone are not enough. Produce runtime evidence such as logs, task status, generated files, screenshots, API responses, or CI checks.

Done when every risk class in the batch has satisfied its required gates, or each missing gate has an explicit blocker and residual risk.

### 7. Handle Failures

Classify failures before fixing:

| Failure | Response |
| --- | --- |
| Resolver conflict | choose a smaller version, upgrade coupled package, or roll back |
| Import/runtime API break | read release notes and adapt only the affected call sites |
| Test expectation drift | decide whether new behavior is correct before changing tests |
| Numeric or artifact drift | compare tolerances, schema, and file-level evidence before accepting |
| External integration failure | confirm credentials, executable paths, network, and server-side logs |

If the package upgrade is not worth the adaptation cost, revert the dependency change and record why.

Done when each failure is classified as pre-existing, resolver conflict, required code adaptation, expected behavior drift, external blocker, or rollback reason.

### 8. Record

Finish with:

- upgraded package(s) and versions
- manifest/lock/environment files changed
- commands run and outcomes
- code adaptations made
- known residual risks
- deferred packages and why
- rollback command or previous known-good version

Record in the highest durable surface available: PR body first, then repository upgrade note or changelog if the project uses one, then final response. Do not leave the only upgrade rationale in transient chat when the repository has a durable release, dependency, or architecture note location.

Done when a future agent can identify what changed, why it was safe enough, how it was verified, and how to continue or roll back.

## Stop Rules

Stop and ask or report a blocker when:

- upgrading requires a runtime major version change
- a dependency is abandoned, yanked, or has incompatible license/security implications
- generated lockfile changes include unrelated package churn that cannot be explained
- tests fail and the failure cannot be tied to a known pre-existing issue
- a real integration requires credentials, production data, paid services, hardware, or destructive migration
- multiple safe upgrade targets remain and the user has not chosen risk tolerance

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| Upgrading every outdated package at once | Batch by risk and coupling |
| Only running the full suite after upgrade | Run baseline and targeted tests first |
| Ignoring installed vs declared drift | Compare manifest, lockfile, and active environment |
| Treating transitive churn as harmless | Explain why each lockfile change occurred |
| Updating tests before understanding behavior drift | Prove whether the new behavior is intended |
| Claiming integration support from unit tests | Produce runtime or artifact evidence for integrations |
| Running copied `npx` or migration commands blindly | Verify package existence and official command names first |

## Final Response

Report the batch, risk class, exact files changed, version movement, verification evidence, and any packages intentionally deferred. Keep the summary concise, but include enough detail for rollback or continuation.
