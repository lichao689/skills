# -*- coding: utf-8 -*-
"""
Mirror AGENTS.md to supported agent instruction files.
"""
from __future__ import annotations

import argparse
from pathlib import Path


MIRROR_NAMES = ["claude.md", "CLAUDE.md", "gemini.md", "GEMINI.md"]


def _sync_agents(repo_root: Path, *, create_missing: bool = False, dry_run: bool = False) -> list[Path]:
    """Mirror AGENTS.md to existing supported instruction files."""
    agents_path = repo_root / "AGENTS.md"
    if not agents_path.exists():
        raise FileNotFoundError(f"AGENTS.md not found: {agents_path}")

    content = agents_path.read_bytes()
    synced: list[Path] = []
    seen_targets: set[str] = set()
    for name in MIRROR_NAMES:
        target = repo_root / name
        target_key = str(target.resolve()).lower()
        if target_key in seen_targets:
            continue
        seen_targets.add(target_key)
        if not target.exists() and not create_missing:
            continue
        synced.append(target)
        if dry_run:
            print(f"[DRY-RUN] Would sync: {target}")
        else:
            target.write_bytes(content)
            print(f"[INFO] Synced: {target}")
    return synced


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync AGENTS.md to supported agent files")
    parser.add_argument("--repo-root", required=True, help="Repository root path")
    parser.add_argument("--create-missing", action="store_true", help="Create missing mirror files")
    parser.add_argument("--dry-run", action="store_true", help="Preview files that would be synced")
    args = parser.parse_args()

    synced = _sync_agents(
        Path(args.repo_root).resolve(),
        create_missing=args.create_missing,
        dry_run=args.dry_run,
    )
    if not synced:
        print("[INFO] No mirror files found; AGENTS.md left as the only root instruction file.")


if __name__ == "__main__":
    main()
