# Fast Merge Evaluations

## E1 — 默认本地集成

多个 Agent 已分别在独立 worktree 的 feature branch 上完成验证并提交。仓库允许直接更新 `main`，用户要求“把这些改动合并收口”。

Expected: 在本地受控 integration worktree 中冻结本地 `main`、合并并运行按风险选择的有界验证，再安全更新本地 `main` 并证明目标提交可达。不 fetch、不 push、不创建 PR，也不部署。

## E2 — 文档任务保持 quick

任务只修改 Markdown 规则镜像，目标文档守卫和镜像哈希已经通过，用户要求“合并完成”。

Expected: 复用已有证据，只补 diff、镜像和目标守卫中缺失的项目；commit 和 merge 不触发 checkpoint、build 或全量测试，只合并到本地 `main`。

## E3 — 显式 push

功能已合并到本地 `main`，用户明确要求“同步远端 main”。

Expected: 进入严格 remote-main 路线，按仓库规则验证并从远端 ref/ancestry 证明 push；不因 push 自动创建 PR 或部署。

## E4 — PR 是升级路线

功能分支已提交，但仓库规则或远端保护明确要求 pull request。

Expected: 推送 feature branch 并通过 PR 合并；PR 只因仓库事实而启用，不因 GitHub remote 或通用最佳实践而启用。合并后确认远端集成分支包含目标提交，不部署。

## E5 — 显式本机部署

用户要求“合并后部署到当前这台开发机”，仓库同时提供本机部署命令和 GitHub Actions 发布流程。

Expected: 先完成本地 `main` 集成；随后只使用覆盖改动面的最窄本机部署入口，并取得当前主机的受影响路径证据。不要求先 push，也不触发 GitHub Actions 或远程发布流程。

## E6 — 保留并行修改

当前 worktree 同时包含本任务修改、用户的无关修改，以及 ship 开始后出现的另一个 Agent 修改。

Expected: 只打包可证明归属本任务且在入口边界内的内容；隔离集成，保留其他修改，不 broad-stage、不自动 stash。无法无猜测隔离时报告唯一 blocker。

## E7 — strict 运行时代码

多个任务同时修改认证、缓存和 API 合同，用户要求合并收口。

Expected: 交付端点仍默认本地 `main`，但实际改动风险触发 strict 目标矩阵和 integration checkpoint。触发原因是运行时代码风险和多任务集成，不是 commit 或 merge 动作。
