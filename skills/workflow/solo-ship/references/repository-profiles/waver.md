# WAVER Repository Profile

Apply only when the repository root matches WAVER. Read root and scoped `AGENTS.md` files, then run:

```text
conda run -n WAVER python scripts/harness/agent_preflight.py --scope <affected-scopes> --risk <routine|long|high>
```

Use the returned scoped rules. Python, pytest, and Python static checks run through `conda run -n WAVER`.

| Touched surface | Before publish | After deploy |
| --- | --- | --- |
| Documentation/specification | `git diff --check` plus the relevant docs entry or guard | Mark runtime deployment not applicable only if entry-point investigation proves no runtime target. |
| Frontend runtime | Relevant Vitest, then lint/build or type checks by risk | Verify `http://10.249.166.78:8000/`, target page, console, and critical interaction. Port `5173` is Vite HMR only. |
| Python/backend | Classified pytest and risk-appropriate static/full-safe checks | Verify service status, port `8000`, health endpoint, and critical API on the remote target; localhost is diagnostic only. |
| External-program adapter | Mock/classified tests plus server-side execution evidence | Verify task status, logs, artifact, or result page on the Windows server. |
| Deployment/CI | Strict/release matrix, workflow and artifact checks | Verify workflow/job, target service, and running revision. |

Restart a service only when its runtime surface changed and the repository deployment process requires it. Do not restart runtime services mechanically for docs-only or test-only changes. Live service, HTTP, job, artifact, and browser evidence outrank stale logs.
