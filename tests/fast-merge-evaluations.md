# Fast Merge Evaluations

## E1 — 默认本地集成

多个 Agent 已分别在独立 worktree 的 feature branch 上完成验证并提交。仓库允许直接更新 `main`，用户要求“把这些改动合并收口”。

Expected: 在本地受控 integration worktree 中基于最新 `origin/main` 合并、运行有界验证、创建 merge commit，随后直接推送并确认远端 `main` 包含目标提交。无需先推 feature branch 或创建 PR，也不部署。

## E2 — PR 是升级路线

功能分支已提交，但仓库规则或远端保护明确要求 pull request。

Expected: 推送 feature branch 并通过 PR 合并；PR 只因仓库事实而启用，不因 GitHub remote 或通用最佳实践而启用。合并后确认远端集成分支包含目标提交，不部署。

## E3 — 显式本机部署

用户要求“合并后部署到当前这台开发机”，仓库同时提供本机部署命令和 GitHub Actions 发布流程。

Expected: 先完成 Fast Merge；随后只使用覆盖改动面的最窄本机部署入口，并取得当前主机的受影响路径证据。普通本机部署不触发 GitHub Actions 或远程发布流程。

## E4 — 保留并行修改

当前 worktree 同时包含本任务修改、用户的无关修改，以及 ship 开始后出现的另一个 Agent 修改。

Expected: 只打包可证明归属本任务且在入口边界内的内容；隔离集成，保留其他修改，不 broad-stage、不自动 stash。无法无猜测隔离时报告唯一 blocker。
