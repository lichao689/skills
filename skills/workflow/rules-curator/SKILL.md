---
name: rules-curator
description: Use when the user wants to sediment durable repository rules or agent instructions, mentions "以后都这样", "全局规则", "沉淀成规则", or asks to update AGENTS.md, CLAUDE.md, or GEMINI.md.
---
# Rules Curator

## Overview
Rules Curator turns conversation-level intent into durable repository guidance. Its job is curation: classify first, write only when the candidate belongs in a high-authority rule file.

Formerly `rules-keeper`.

## Workflow
1. Extract the candidate rule.
- Capture the smallest actionable sentence.
- Remove one-off task context, implementation narration, and temporary preference wording.
- Completion criterion: the candidate can stand alone as future-agent guidance.

2. Classify the destination.

| Destination | Use when |
|---|---|
| Root rule | Long-lived, cross-task, mandatory, agent-actionable guidance |
| Standard doc | Longer policy, examples, rationale, or project development standard |
| Decision or ADR | A durable trade-off, architecture choice, tool choice, or reversal |
| Learning | A useful pattern, pitfall, or operational note that is not mandatory |
| Handoff or context | Current work state, remaining tasks, blockers, or resume notes |
| No write | One-off instruction, transient preference, or already-covered rule |

Completion criterion: state the chosen destination and why it fits before writing.

3. Apply the root-rule gate.

Write to root instruction files only when all are true:
- The rule is expected to remain valid across future sessions.
- It applies across tasks, modules, pages, or agents.
- It tells future agents what to do or avoid.
- The user explicitly wants durable behavior, or confirms it after review.
- It is concise enough for a root instruction file, or has a concise root summary with a documentation link.
- It does not duplicate or conflict with an existing rule.

If any item fails, route to the better destination instead of forcing a root rule.

4. Ask before high-authority writes when confirmation is missing.
- If `request_user_input` is available, ask one question with 2-3 choices.
- Put the recommended option first and suffix its label with `(Recommended)`.
- Stop until the user answers.
- If that tool is unavailable, ask in chat with a numbered list and wait for the reply.

Recommended choices:
1. Standard doc plus root summary, for longer rules.
2. Root rule, for short mandatory guidance.
3. Learning or decision record, for non-mandatory knowledge.

5. Write the rule.
- Prefer `scripts/update_dynamic_rules.py`.
- Root file is `AGENTS.md`.
- Mirror to existing `claude.md` / `CLAUDE.md` / `gemini.md` / `GEMINI.md` by default.
- Create missing mirror files only when the repository or user explicitly wants mirrored agent files.

6. Report the result.
- Destination chosen.
- Exact rule text written or reason no write happened.
- Files changed.
- Duplicate or conflict notes.

## Script Usage
Append a root rule:

```bash
python "C:\path\to\skills\rules-curator\scripts\update_dynamic_rules.py" --repo-root . --rule "All runtime logs must be English ASCII" --scope "全仓库"
```

Preview without writing:

```bash
python "C:\path\to\skills\rules-curator\scripts\update_dynamic_rules.py" --repo-root . --rule "All runtime logs must be English ASCII" --dry-run
```

Sync existing mirror files:

```bash
python "C:\path\to\skills\rules-curator\scripts\sync_agents.py" --repo-root .
```

Create missing mirror files only when explicitly requested:

```bash
python "C:\path\to\skills\rules-curator\scripts\sync_agents.py" --repo-root . --create-missing
```

## Rule Table
Root rules are appended under:

```markdown
## 动态更新规则
| 日期 | 规则 | 适用范围 | 来源 | 备注 |
|---|---|---|---|---|
```

Rows use:

`| 日期 | 规则 | 适用范围 | 来源 | 备注 |`

Use the note field for replacements, for example `supersedes: 2026-07-01 old summary`.

## Common Mistakes
- Do not write a clear sentence just because it is clear. Clear one-off instructions are still one-off.
- Do not append near-duplicates. Merge, replace, or mark supersession.
- Do not put long rationale in root files. Link to a standard, ADR, or solution doc.
- Do not silently create every possible agent file in a repository that only uses one.
- Do not treat a learning as a rule. Rules are mandatory; learnings are guidance.
