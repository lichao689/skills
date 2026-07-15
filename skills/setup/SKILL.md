---
name: setup
description: Set up and repair this personal skills package across Codex and Claude Code. Use before first installation, after moving to a new machine, or when a bundled skill is not visible.
---

# Setup

Install or refresh this repository's bundled skills. Inspection is read-only unless the user requests installation or repair.

## Commands

```bash
scripts/list-skills.sh
scripts/link-skills.sh --target codex
scripts/link-skills.sh --target claude
scripts/link-skills.sh --target all
scripts/link-skills.sh --target codex --with-gstack
scripts/setup-gstack-subset.sh --target all --dry-run
```

Use `--strategy copy` or `--strategy link` to override the target's default installation strategy.
Use `--with-gstack` only when the user wants the curated gstack subset and its locked runtime.

## Process

1. Run `scripts/list-skills.sh` to inspect the bundled skills.
2. Select `codex`, `claude`, or `all` based on the requested host.
3. For gstack, run `scripts/setup-gstack-subset.sh --target <host> --dry-run` and verify Git, Bun, network, and destination paths before installation.
4. Install with `scripts/link-skills.sh --target <host>`; append `--with-gstack` when requested.
5. Run `scripts/list-skills.sh` again and verify that each expected `SKILL.md` is present at the destination. For gstack, verify the 13 selected short names and the runtime `browse --help` command.
