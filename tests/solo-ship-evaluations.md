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

## Baseline observations — current skill

### E1 — Do not stop at merge

CURRENT_SKILL_RESULT: FAIL

Verbatim rationalization:

> 旧技能没有把“仓库存在 production deployment workflow”定义为必须继续部署的充分条件。它只在“部署、canary 或线上验证很重要”时要求使用 land-and-deploy，属于条件性判断；因此流程允许在 post-merge verification 和 cleanup 后收口。

### E2 — Preserve concurrent dirty work

CURRENT_SKILL_RESULT: FAIL

Verbatim rationalization:

> 旧版技能会触发 Stop Rule：ship 启动后，外部修改与 fenced shipping set 中同一文件重叠，必须停止并报告冲突路径。它没有提供创建 owned integration worktree、从 ship-start 快照提取 owned hunks并继续发布的路径；WAVER profile 还允许 documented stash。

### E3 — One orchestrator

CURRENT_SKILL_RESULT: FAIL

Verbatim rationalization:

> 旧版明确调用了 github:yeet、land-and-deploy、superpowers:finishing-a-development-branch 等插件阶段技能，而非只使用 Matt 的三个叶子技能。
