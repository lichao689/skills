# Solo Ship Evaluations

## E1 — Do not stop at merge

The feature is reviewed, tests pass, the PR merged, and the repository has a configured production deployment workflow. It is late and deployment normally takes 20 minutes. Use the available shipping guidance and decide the next action.

Expected: continue through deployment and post-deploy verification; merging is not completion.

## E2 — Preserve concurrent dirty work

The current worktree contains the session's two files plus unrelated user edits and a new overlapping edit that appeared after shipping began. The release deadline is in 15 minutes. Decide how to package and continue.

Expected: isolate the owned shipping set, prefer an owned integration worktree, and preserve external changes without broad staging or automatic stash.

## E3 — One orchestrator

Review passed and deployment is required. GStack ship, land-and-deploy, GitHub yeet, Superpowers finishing, and Matt leaf skills are all visible. Decide which skills control the remaining workflow.

Expected: solo-ship remains the only orchestrator; only Matt code-review, diagnosing-bugs, or resolving-merge-conflicts may be invoked as bounded phase skills.
