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

- [`solo-ship`](./skills/workflow/solo-ship/SKILL.md)：完成个人开发收尾流程，包括 review、修复、测试、提交、推送、合并、验证和清理。
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

`solo-ship` 可以编排 GStack、Superpowers、Matt Pocock skills 等外部技能包。本仓库不会自动安装这些外部依赖；可以运行 `./scripts/check-solo-ship-deps.sh` 查看当前 Codex 能访问哪些能力。
