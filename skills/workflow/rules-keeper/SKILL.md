---
name: rules-keeper
description: Use when durable repository-level rules, conventions, or agent instructions need to be recorded in root instruction files such as AGENTS.md, CLAUDE.md, or GEMINI.md.
---
# Rules Keeper

## 概述
识别长期有效的仓库级规则，并将其写入仓库根目录的规则清单。默认以 `AGENTS.md` 为主规则文件，并同步到存在的 `claude.md` / `CLAUDE.md` / `gemini.md` / `GEMINI.md`。

本技能不假设任何特定仓库结构。规则是否应写入仓库，由用户意图和规则的长期适用范围决定。

## 工作流
1) 识别全局规则
- 触发特征：包含“全局/统一/以后都这样/所有页面/全仓库/必须遵守”等语义。
- 范围要求：必须是跨模块、跨页面、跨任务或跨会话长期有效的规则。
- 排除：一次性任务指令、临时偏好、单次执行步骤。

2) 澄清（必要时）
- 规则过于含糊时，先追问确认范围、强制级别或对象。
- 若已清晰，直接记录。

3) 写入规则（首选脚本）
- 使用 `scripts/update_dynamic_rules.py` 追加规则表行。
- 目标文件：`AGENTS.md`，以及存在的 `claude.md`、`gemini.md`；若存在大写文件名 `CLAUDE.md` / `GEMINI.md` 也同步。
- 写入位置：各文件的 `## 动态更新规则` 表格中；若章节不存在则自动创建。
- 同步策略：只要 `AGENTS.md` 被更新，自动将其内容全量镜像到 `claude.md` / `CLAUDE.md` 与 `gemini.md` / `GEMINI.md`。

4) 汇报
- 返回新增规则文本与更新文件列表。
- 若检测到疑似重复，仅提示“已存在”不重复写入。

## 规则格式
表格固定列：
`| 日期 | 规则 | 适用范围 | 来源 | 备注 |`

示例：
```
## 动态更新规则
| 日期 | 规则 | 适用范围 | 来源 | 备注 |
|---|---|---|---|---|
| 2026-01-11 | 所有运行期日志必须为英文 ASCII | 全仓库 | 对话 | 新增 |
```

## 脚本
### scripts/update_dynamic_rules.py
功能：向 AGENTS.md/claude.md/gemini.md 追加规则行并去重。若 AGENTS.md 被更新，自动同步覆盖 claude.md / CLAUDE.md 与 gemini.md / GEMINI.md。

**关键路径说明**：
本脚本位于技能目录中。调用时优先使用绝对路径，并用双引号包裹路径以处理空格。若环境支持相对路径，也可以从技能目录运行脚本。

参数：
- `--repo-root`：仓库根目录（通常为 `.`）
- `--rule`：规则正文（必填，需用引号包裹）
- `--scope`：适用范围（默认“全仓库”）
- `--source`：来源（默认“对话”）
- `--note`：备注（默认“新增”）
- `--date`：日期（YYYY-MM-DD，默认当天）

**正确调用示例 (Windows)**：
```bash
python "C:\path\to\skills\rules-keeper\scripts\update_dynamic_rules.py" --repo-root . --rule "所有运行期日志必须为英文 ASCII" --scope "全仓库"
```

### scripts/sync_agents.py
功能：将仓库根目录的 `AGENTS.md` 作为主文件，**全量镜像**覆盖到 `claude.md` / `CLAUDE.md` 与 `gemini.md` / `GEMINI.md`（若不存在则创建），确保三份文件完全一致。

实现位置：本技能目录 `scripts/sync_agents.py`。

使用示例：
```bash
python "C:\path\to\skills\rules-keeper\scripts\sync_agents.py" --repo-root .
```

## 去重与冲突策略
- 去重：同一“规则”文本重复出现时不追加。
- 冲突：不自动覆盖旧规则；若发现语义冲突，提示用户确认再处理。
