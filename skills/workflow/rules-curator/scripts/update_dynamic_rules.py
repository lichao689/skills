# -*- coding: utf-8 -*-
"""
Append curated repository rules to AGENTS.md and mirror supported agent files.
"""
from __future__ import annotations

import argparse
from datetime import date
from pathlib import Path

try:
    from sync_agents import _sync_agents
except ImportError:
    def _sync_agents(repo_root: Path, *, create_missing: bool = False, dry_run: bool = False) -> list[Path]:
        return []


HEADER_SECTION = "## 动态更新规则"
TABLE_HEADER = "| 日期 | 规则 | 适用范围 | 来源 | 备注 |\n|---|---|---|---|---|"


def _clean_cell(value: str) -> str:
    return value.replace("\r", " ").replace("\n", " ").replace("|", r"\|").strip()


def _make_row(rule_date: str, rule: str, scope: str, source: str, note: str) -> str:
    cells = [rule_date, rule, scope, source, note]
    return "| " + " | ".join(_clean_cell(cell) for cell in cells) + " |"


def _find_table_insert_index(lines: list[str], section_index: int) -> int | None:
    insert_idx: int | None = None
    for idx in range(section_index + 1, len(lines)):
        line = lines[idx].strip()
        if idx > section_index + 1 and line.startswith("## "):
            break
        if line.startswith("|"):
            insert_idx = idx
        elif insert_idx is not None and line:
            break
    return insert_idx


def update_file(file_path: Path, new_row: str, rule_content: str, *, dry_run: bool = False) -> bool:
    if not file_path.exists():
        return False

    content = file_path.read_text(encoding="utf-8")
    escaped_rule_content = _clean_cell(rule_content)
    if rule_content and (rule_content in content or escaped_rule_content in content):
        print(f"[INFO] Rule already exists, skipping: {file_path.name}")
        return False

    original = content
    if HEADER_SECTION not in content:
        if not content.endswith("\n"):
            content += "\n"
        content += f"\n{HEADER_SECTION}\n{TABLE_HEADER}\n{new_row}\n"
    else:
        lines = content.splitlines()
        section_index = next(i for i, line in enumerate(lines) if line.strip() == HEADER_SECTION)
        insert_idx = _find_table_insert_index(lines, section_index)
        if insert_idx is None:
            lines[section_index + 1:section_index + 1] = TABLE_HEADER.splitlines() + [new_row]
        else:
            lines.insert(insert_idx + 1, new_row)
        content = "\n".join(lines) + "\n"

    if content == original:
        return False
    if dry_run:
        print(f"[DRY-RUN] Would update: {file_path.name}")
        print(new_row)
    else:
        file_path.write_text(content, encoding="utf-8")
        print(f"[SUCCESS] Updated: {file_path.name}")
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Append a curated root rule to AGENTS.md")
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--rule", required=True)
    parser.add_argument("--scope", default="全仓库")
    parser.add_argument("--source", default="对话")
    parser.add_argument("--note", default="新增")
    parser.add_argument("--date", default=None)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--create-missing-mirrors", action="store_true")
    args = parser.parse_args()

    root = Path(args.repo_root).resolve()
    today = args.date if args.date else date.today().strftime("%Y-%m-%d")
    new_row = _make_row(today, args.rule, args.scope, args.source, args.note)

    agents_path = root / "AGENTS.md"
    if not agents_path.exists():
        content = f"# 仓库规则\n\n{HEADER_SECTION}\n{TABLE_HEADER}\n{new_row}\n"
        if args.dry_run:
            print(f"[DRY-RUN] Would create: {agents_path}")
            print(content)
        else:
            agents_path.write_text(content, encoding="utf-8")
            print(f"[SUCCESS] Created: {agents_path.name}")
        updated = True
    else:
        updated = update_file(
            agents_path,
            new_row,
            args.rule.replace("\r", " ").replace("\n", " ").strip(),
            dry_run=args.dry_run,
        )

    if updated:
        _sync_agents(root, create_missing=args.create_missing_mirrors, dry_run=args.dry_run)
    else:
        print("[INFO] No change; mirror sync skipped.")


if __name__ == "__main__":
    main()
