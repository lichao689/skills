# -*- coding: utf-8 -*-
"""
同步 AGENTS.md -> claude.md / CLAUDE.md / gemini.md / GEMINI.md（全量镜像）。
"""
from __future__ import annotations

from pathlib import Path
import argparse


def _sync_agents(repo_root: Path) -> None:
    """同步主规则文件到其他映射文件。"""
    agents_path = repo_root / "AGENTS.md"
    if not agents_path.exists():
        raise FileNotFoundError(f"AGENTS.md not found: {agents_path}")

    content = agents_path.read_bytes()
    for name in ["claude.md", "CLAUDE.md", "gemini.md", "GEMINI.md"]:
        target = repo_root / name
        target.write_bytes(content)
        print(f"[INFO] Synced: {target}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync AGENTS.md to claude.md and gemini.md")
    parser.add_argument("--repo-root", required=True, help="Repository root path (relative or absolute)")
    args = parser.parse_args()
    _sync_agents(Path(args.repo_root))


if __name__ == "__main__":
    main()
