# WAVER Repository Profile

Apply only when the repository root is WAVER. Read root and scoped `AGENTS.md`, then run the repository preflight for `git` plus affected scopes. Its returned standards are authoritative.

## Integration

- Parallel Agent work uses one feature branch and worktree per task; Codex-managed detached worktrees must first receive an owned feature branch.
- Prefer `task agent:finish -- <TASK-ID>` so agentctl freezes `origin/main`, merges in a temporary integration worktree, runs `validate:checkpoint`, creates the merge commit, pushes it to `origin/main`, and confirms remote ancestry.
- If agentctl cannot own the task lifecycle, follow the same local integration contract manually. Use a PR only when repository or remote facts require it.
- Default completion is remote `main` alignment. Root-checkout synchronization and deployment are separate results.

## Validation

- Reuse applicable development evidence and close only missing risk surfaces.
- Run `task validate:dev` for dirty-tree patch integrity and targeted pytest/Vitest/lint/build checks selected by the repository test standard.
- Run `task validate:checkpoint` for multi-Agent integration or before finalizing the integration commit.
- Full-safe, release, external-program, and expensive validation require the authorization defined by WAVER rules.

## Current-host deployment

Only explicit `deploy-local` intent adds deployment after remote `main` alignment:

| Changed surface | Narrow current-host entry |
| --- | --- |
| Backend | `task deploy:local:backend` |
| Frontend | `task deploy:local:web` |
| Frontend and backend | `task deploy:local:app` |

Prove service health and the affected API, page, artifact, or user path. Ordinary Fast Merge does not deploy, restart services, or trigger GitHub Actions. Batch several merged changes into one later local deployment when immediate runtime proof is unnecessary.
