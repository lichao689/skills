# -*- coding: utf-8 -*-
"""
Append durable repository rules to AGENTS.md and mirror supported agent files.
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path
from datetime import date

# 尝试导入同步函数，若失败则定义简易版
try:
    from sync_agents import _sync_agents
except ImportError:
    def _sync_agents(root): pass

HEADER_SECTION = "## 动态更新规则"
TABLE_HEADER = "| 日期 | 规则 | 适用范围 | 来源 | 备注 |\n|---|---|---|---|---|"

def update_file(file_path: Path, new_row: str) -> bool:
    if not file_path.exists():
        return False

    content = file_path.read_text(encoding="utf-8")

    # 1. 检查是否已存在相同规则（简单去重）
    # 提取规则文本（假设格式：| 日期 | 规则 | ...）
    rule_content = new_row.split("|")[2].strip()
    if rule_content in content:
        print(f"[INFO] 规则已存在，跳过写入: {file_path.name}")
        return False

    # 2. 定位或创建章节
    if HEADER_SECTION not in content:
        # 章节不存在，追加到文件末尾
        print(f"[INFO] 初始化章节 '{HEADER_SECTION}' 于: {file_path.name}")
        if not content.endswith("\n"):
            content += "\n"
        content += f"\n{HEADER_SECTION}\n{TABLE_HEADER}\n{new_row}\n"
    else:
        # 章节存在，寻找表格末尾追加
        # 简单策略：找到章节后，在下一行追加（如果还没表格则创建表格）
        parts = content.split(HEADER_SECTION)
        pre_section = parts[0]
        post_section = parts[1]

        if "|---|" not in post_section:
            # 有标题没表格，补充表格
            new_post = f"\n{TABLE_HEADER}\n{new_row}\n" + post_section
        else:
            # 寻找表格结束位置（空行或新标题）或者直接在表格最后一行后追加
            # 这里采用简单追加到表格块的策略
            lines = post_section.splitlines()
            insert_idx = -1
            for i, line in enumerate(lines):
                if line.strip().startswith("|"):
                    insert_idx = i
                elif insert_idx > -1 and not line.strip().startswith("|"):
                    # 表格结束了
                    break

            if insert_idx == -1:
                # 没找到表格行？异常情况，重置
                new_post = f"\n{TABLE_HEADER}\n{new_row}\n" + post_section
            else:
                # 在 insert_idx 后插入
                lines.insert(insert_idx + 1, new_row)
                new_post = "\n".join(lines)

        content = pre_section + HEADER_SECTION + new_post

    if not content.endswith("\n"):
        content += "\n"
    file_path.write_text(content, encoding="utf-8")
    print(f"[SUCCESS] 已写入: {file_path.name}")
    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--rule", required=True)
    parser.add_argument("--scope", default="全仓库")
    parser.add_argument("--source", default="对话")
    parser.add_argument("--note", default="新增")
    parser.add_argument("--date", default=None)

    args = parser.parse_args()

    root = Path(args.repo_root).resolve()
    today = args.date if args.date else date.today().strftime("%Y-%m-%d")

    # 构建规则行
    # 清理换行符，避免破坏表格结构
    clean_rule = args.rule.replace("\n", " ").strip()
    new_row = f"| {today} | {clean_rule} | {args.scope} | {args.source} | {args.note} |"

    # 1. 更新主文件 AGENTS.md
    agents_path = root / "AGENTS.md"
    if not agents_path.exists():
        # 如果不存在，尝试创建
        print(f"[WARN] AGENTS.md 不存在，创建新文件: {agents_path}")
        agents_path.write_text(f"# 仓库规则\n\n{HEADER_SECTION}\n{TABLE_HEADER}\n{new_row}\n", encoding="utf-8")
        updated = True
    else:
        updated = update_file(agents_path, new_row)

    # 2. 如果主文件更新了，执行同步
    if updated:
        print("[INFO] 主文件已更新，开始同步...")
        _sync_agents(root)
    else:
        print("[INFO] 主文件未变更，跳过同步。")

if __name__ == "__main__":
    main()
