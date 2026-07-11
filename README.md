# lichao689 Skills

个人 Codex / Claude Code 技能库。

## 安装

从 GitHub 安装：

```bash
npx skills@latest add lichao689/skills
```

也可以克隆仓库后同步本地技能：

```bash
git clone git@github.com:lichao689/skills.git ~/Developer/lichao689-skills
cd ~/Developer/lichao689-skills
./scripts/link-skills.sh --target codex
```

如果要用于 Claude Code 或同时用于两个宿主，把 `--target` 改成 `claude` 或 `all`。

## 技能

- [`solo-ship`](./skills/workflow/solo-ship/SKILL.md)：将已完成的个人开发工作从评审持续推进到部署与上线验收，包括修复、验证、发布、合并和安全清理。
- [`code-simplifier`](./skills/workflow/code-simplifier/SKILL.md)：对最近改动过的代码做行为不变的简化与清理，去掉多余防卫、明显废话注释和不必要抽象，并对齐仓库规范。
- [`rules-curator`](./skills/workflow/rules-curator/SKILL.md)：在写入根级 agent 规则文件前，整理和判断哪些规则值得长期保留。
- [`setup`](./skills/setup/SKILL.md)：安装、检查和修复这个技能包在 Codex 与 Claude Code 中的配置。

## 脚本

```bash
./scripts/list-skills.sh
./scripts/link-skills.sh --target codex
./scripts/check-solo-ship-deps.sh
./scripts/setup-solo-ship.sh --target all
```

`link-skills.sh` 默认会为 Codex 复制技能目录，为 Claude 创建链接。已有的非链接技能目录不会被删除，而是移动到带时间戳的备份目录。

## 备注

`solo-ship` 只依赖 Matt Pocock skills 中的三个阶段技能：`code-review`、`diagnosing-bugs` 和 `resolving-merge-conflicts`。Git、GitHub CLI、CI、测试与部署命令属于工具能力，不是技能依赖。本仓库不会自动安装外部依赖；可以运行 `./scripts/check-solo-ship-deps.sh` 查看当前宿主可访问的技能与工具。
