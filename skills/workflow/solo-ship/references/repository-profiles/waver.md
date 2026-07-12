# WAVER Repository Profile

Apply only when the repository root matches WAVER. Read root and scoped `AGENTS.md` files, then run:

```text
conda run -n WAVER python scripts/harness/agent_preflight.py --scope <affected-scopes> --risk <routine|long|high>
```

Use the returned scoped rules. They are the single source of truth for test selection and Git/cleanup policy. Python, pytest, and Python static checks run through `conda run -n WAVER`.

| Touched surface | Before publish | After deploy |
| --- | --- | --- |
| Documentation/specification | `git diff --check` plus the relevant docs entry or guard | For `goal=integrate`, no runtime deploy check. For `goal=deploy`, verify the published target when one exists. |
| Frontend runtime | Relevant Vitest, then lint/build or type checks by risk | Verify `http://10.249.166.78:8000/`, target page, console, and critical interaction. Port `5173` is Vite HMR only. |
| Python/backend | Classified pytest and risk-appropriate static/full-safe checks | Verify service status, port `8000`, health endpoint, and critical API on the remote target; localhost is diagnostic only. |
| External-program adapter | Mock/classified tests plus server-side execution evidence | Verify task status, logs, artifact, or result page on the Windows server. |
| Deployment/CI | Strict/release matrix, workflow and artifact checks | Verify workflow/job, target service, and running revision. |

For `goal=integrate`, apply WAVER's required post-merge local-service refresh. Restart only affected runtime services; docs-only and test-only changes require no runtime restart. For `goal=deploy`, live service, HTTP, job, artifact, and browser evidence outrank stale logs. Delete only owned, merged feature branches and worktrees as required by WAVER policy; preserve shared, integration, or ambiguous branches.
