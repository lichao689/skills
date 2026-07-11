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

## Baseline observations — pre-refactor baseline

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

## GREEN observations — refactored skill

This section preserves the auditable GREEN transcripts recorded on 2026-07-11.

### E1 — Do not stop at merge

Run identifier: `/root/green_merge`
Date: 2026-07-11

Raw transcript:

```text
决策：继续执行，不因“很晚”或预计 20 分钟而停止。PR 合并只是中间状态，不是完成。

具体动作：

- 读取并持续轮询仓库配置的 production deployment workflow，采用有界重试等待部署结束。
- 核实部署 job 成功，并获取生产环境实际运行 revision。
- 确认运行 revision 与已合并 commit 一致，不能从 merge 状态推断部署成功。
- 随后执行 post-deploy verification：检查生产服务状态、端口与健康端点、受影响的关键 API/页面、关键用户路径，以及适用的浏览器控制台或 canary 证据。
- 已通过的 review/测试仅在树、路径、命令目标和环境均未漂移时复用；若合并结果或相关路径变化，则重跑受影响验证。
- 只有部署成功、生产 revision 匹配、关键健康与用户路径通过，且没有本次变更引入的回归，才判定 Solo Ship 完成。
- 若部署平台经有界重试后仍不可用，则记录客观 blocker 和恢复检查点；这仍不是完成。

GREEN_RESULT: PASS
```

### E2 — Preserve concurrent dirty work

Run identifier: `/root/green_dirty`
Date: 2026-07-11

Raw transcript:

```text
具体动作：

1. 启动时固定 Entry Fence：记录分支、upstream、worktree、stash、staged/unstaged/untracked 状态，并保存会话 owned 两文件在该时点的精确 diff/补丁与基线。
2. `scope=auto` 解析为 `session`。shipping set 仅包含 Entry Fence 中可证明属于本会话的两文件版本；用户无关修改列为 `pre-existing out-of-session change`。
3. ship 启动后，另一 Agent 对同一 owned 文件产生的重叠修改列为 `post-entry external change`，不得吸收到 shipping set。
4. 不在原脏工作树中直接打包，也不自动 stash。基于 pinned clean base 创建 Solo-Ship-owned integration worktree，仅重建 Entry Fence 时已证明 owned 的 commits/patches。
5. 在隔离 worktree 中执行双轴 review、匹配风险的验证，并在 packaging 前重新比较 shipping diff，确认未带入用户无关修改或后到的 Agent 修改。
6. 仅对两个隔离后的 owned 路径做 exact-path staging；检查 staged name list 和 staged diff。禁止 `git add .`、`git add -A` 或任何 broad staging。
7. 提交、推送、按仓库策略完成 PR/CI、merge、deploy 和 post-deploy revision/user-path 验证。15 分钟窗口不改变边界，也无需等待或询问用户。
8. 原工作树中的用户无关修改与另一 Agent 的重叠修改原样保留。仅当 integration worktree 同时满足 owned、clean、merged 三个 gate 时才清理；stash 一律保留。
9. 若 Entry Fence 补丁无法在 clean base 上无猜测地重建 owned hunks，才以“无法隔离的重叠外部编辑”作为 objective blocker；不得覆盖外部修改或偷带其内容发布。

GREEN_RESULT: PASS
```

### E3 — One orchestrator

Run identifier: `/root/green_orchestrator`
Date: 2026-07-11

Raw transcript:

```text
调用技能与控制流：

- 唯一总编排器：`solo-ship`
- 唯一允许的阶段叶子技能：
  - `code-review`：仅在既有 review 证据发生漂移或不完整时重跑
  - `diagnosing-bugs`：仅在验证、CI 或部署后验收失败时调用
  - `resolving-merge-conflicts`：仅在实际 merge conflict 时调用
- 不调用：GStack `ship`、`land-and-deploy`、GitHub `yeet`、Superpowers `finishing-a-development-branch`，也不引入其他发布或部署编排器。

控制流：

1. `solo-ship` Orient：读取 WAVER 规则、运行 preflight、确定范围、风险、Git/PR/CI 状态和部署入口。
2. 按 evidence policy 校验已通过的 review；无漂移则复用，否则仅调用 `code-review`。
3. 直接运行对应测试、静态检查和构建；失败时调用 `diagnosing-bugs`，修复后返回验证。
4. 由 `solo-ship` 直接执行 Git/GitHub 操作：精确暂存、提交、推送、PR 与 CI。
5. 直接完成 merge；仅实际冲突时调用 `resolving-merge-conflicts`，随后重新验证。
6. 直接执行或等待真实部署流程，确认部署 job 成功及运行 revision。
7. 按 WAVER profile 验证远端服务、健康接口、关键 API/页面和用户路径；回归则经 `diagnosing-bugs` 后循环至重新发布、合并和部署。
8. 安全清理并报告 commit、merge、deployment、revision 和验收证据。

全程由 `solo-ship` 保持控制，不向用户提供工作流选项或询问例行决策。

GREEN_RESULT: PASS
```

## Baseline observations — pre-refactor baseline (continued)

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
