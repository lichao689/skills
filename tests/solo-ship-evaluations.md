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

This file is the durable transcript artifact for the current-skill RED baseline recorded on 2026-07-11.

### E1 — Do not stop at merge

Run identifier: `/root/red_merge (second RED run)`
Date: 2026-07-11

Raw transcript:

```text
按旧技能，我会先执行强制的 post-merge verification：更新基础分支、重新运行关键验证，然后在安全检查通过后清理已合并分支和 worktree。

但旧技能没有把“仓库存在 production deployment workflow”定义为必须继续部署的充分条件。它只在“部署、canary 或线上验证很重要”时要求使用 `land-and-deploy`，属于条件性判断；因此流程允许在 post-merge verification 和 cleanup 后收口，未明确强制等待 20 分钟完成生产部署及 post-deploy verification。

CURRENT_SKILL_RESULT: FAIL
```

### E2 — Preserve concurrent dirty work

Run identifier: `/root/red_dirty (second RED run)`
Date: 2026-07-11

Raw transcript:

```text
旧版技能会触发 Stop Rule：ship 启动后，外部修改与 fenced shipping set 中同一文件重叠，必须停止并报告冲突路径。它没有提供创建 owned integration worktree、从 ship-start 快照提取 owned hunks并继续发布的路径；WAVER profile 还允许 documented stash。

因此本场景无法按旧技能继续发布。

CURRENT_SKILL_RESULT: FAIL
```

### E3 — One orchestrator

Run identifier: `/root/red_orchestrator (second RED run)`
Date: 2026-07-11

Raw transcript:

```text
旧版技能的控制流是：

`solo-ship`（顶层编排器）
→ 复用已通过的 review 证据
→ `superpowers:verification-before-completion` / `health` 做提交前验证
→ `github:yeet` 完成提交和推送
→ 严格模式下使用 `github:github` 处理 PR；CI 失败时使用 `github:gh-fix-ci`
→ `land-and-deploy` 执行合并、部署和线上验证
→ `document-release` 处理部署相关文档
→ `superpowers:finishing-a-development-branch` 配合 `careful` 或 `guard` 清理分支和 worktree
→ 控制权返回 `solo-ship` 汇总结果。

虽然 `solo-ship` 仍是顶层编排器，但旧版明确调用了 `github:yeet`、`land-and-deploy`、`superpowers:finishing-a-development-branch` 等插件阶段技能，而非只使用 Matt 的三个叶子技能。

CURRENT_SKILL_RESULT: FAIL
```
