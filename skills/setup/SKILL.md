---
name: setup
description: Set up and repair this personal skills package across Codex and Claude Code. Use before first installation, after moving to a new machine, when a bundled skill is not visible, or when fast-merge reports a missing leaf skill or Git capability.
---

# Setup

Install or refresh this repository's bundled skills and check the external capabilities used by `fast-merge`. Checks are read-only unless the user requests installation or repair. Installing the external Matt skill pack requires explicit confirmation.

## Fast Merge Contract

`fast-merge` is the integration orchestrator. Its bounded leaf skills are:

- `code-review`
- `diagnosing-bugs`
- `resolving-merge-conflicts`

Git is always required. GitHub CLI is required only when repository or remote policy selects the GitHub PR route.

## Commands

```bash
scripts/setup-fast-merge.sh --target codex
scripts/setup-fast-merge.sh --target claude
scripts/setup-fast-merge.sh --target all
```

Add `--install-local` to refresh this repository's skills before checking, and use `--strict` in automation.

## Process

1. Run `git status --short --branch` and the matching setup command.
2. Require exact visibility for `fast-merge` and the three leaf skills. Report Git and route-required `gh` separately.
3. Repair bundled skills with `scripts/setup-fast-merge.sh --target <host> --install-local`.
4. If a Matt leaf skill is missing, present `npx skills@latest add mattpocock/skills -g` and wait for explicit confirmation.
5. Rerun the matching command with `--strict` and report the remaining failure precisely.
