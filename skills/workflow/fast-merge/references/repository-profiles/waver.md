# WAVER Repository Profile

Apply only when the repository root is WAVER. Read root and scoped `AGENTS.md`, then run the repository preflight for `git` plus affected scopes. Its returned standards are authoritative.

## Integration

- Parallel Agent work uses one feature branch and worktree per task; Codex-managed detached worktrees must first receive an owned feature branch.
- For ordinary merge/finish/land/ship, use `task agent:merge-local -- <TASK-ID>` so agentctl freezes local `main`, merges in a temporary integration worktree, runs `validate:dev`, and safely fast-forwards local `main` without fetch or push.
- Only explicit push or remote-sync intent uses `task agent:finish -- <TASK-ID>`, the strict `remote-main` route with checkpoint and remote ancestry proof. Use a PR only when repository or remote facts require it.
- If agentctl cannot own the task lifecycle, follow the selected endpoint contract manually. Current session detached synchronization is not a default side effect.

## Validation

- Reuse applicable development evidence and close only missing risk surfaces.
- Run `task validate:dev` for dirty-tree patch integrity and targeted pytest/Vitest/lint/build checks selected by the repository test standard.
- Run `task validate:checkpoint` only for multi-task runtime-code integration, strict risk, or explicit user intent. Commit, merge, conflict-free rebase, and push do not trigger it.
- Full-safe, release, external-program, and expensive validation require the authorization defined by WAVER rules.

## Current-host deployment

Only explicit `deploy-local` intent adds deployment after local `main` integration; push is not required:

| Changed surface | Narrow current-host entry |
| --- | --- |
| Backend | `task deploy:local:backend` |
| Frontend | `task deploy:local:web` |
| Frontend and backend | `task deploy:local:app` |

Prove service health and the affected API, page, artifact, or user path. Ordinary Fast Merge does not deploy, restart services, or trigger GitHub Actions. Batch several merged changes into one later local deployment when immediate runtime proof is unnecessary.
