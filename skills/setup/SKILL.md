---
name: setup
description: Set up and repair this personal skills package across Codex and Claude Code. Use before first installation, after moving to a new machine, when a bundled skill is not visible, or when solo-ship reports a missing Matt leaf skill or required Git, GitHub CLI, test, CI, or deployment tool capability.
---

# Setup

This is the setup entrypoint for this skills repository. It checks host visibility, installs or refreshes this repository's bundled skills when requested, and reports the external Matt leaf skills and tool capabilities used by `solo-ship`.

Checks are read-only by default. Installing this repository's own skills is allowed when the user asks for setup or repair. Installing the external Matt skill pack requires explicit user confirmation.

## Solo Ship Contract

`solo-ship` remains the sole workflow orchestrator. Its only skill dependencies are these bounded Matt leaf skills:

- `code-review`
- `diagnosing-bugs`
- `resolving-merge-conflicts`

Git, GitHub CLI, repository tests, CI, and deployment commands are tool capabilities. Do not report them as skill dependencies and do not require other publishing, finishing, or deployment orchestrator skills.

## Core Commands

From the repository root:

```bash
scripts/setup-solo-ship.sh --target codex
scripts/setup-solo-ship.sh --target claude
scripts/setup-solo-ship.sh --target all
```

To install or refresh only this repository's bundled skills before checking:

```bash
scripts/setup-solo-ship.sh --target codex --install-local
scripts/setup-solo-ship.sh --target claude --install-local
scripts/setup-solo-ship.sh --target all --install-local
```

Use `--strict` in automation when a bundled skill, Matt leaf skill, or required CLI is missing.

## Process

### 1. Explore

Inspect the repository and host surfaces:

```bash
git status --short --branch
scripts/setup-solo-ship.sh --target all
```

For Codex visibility, prefer `codex debug prompt-input` with filesystem fallback. For Claude Code, check `~/.claude/skills` and `~/.agents/skills`.

### 2. Interpret

Require exact visibility for `solo-ship` and the three Matt leaf skills. Report Git and `gh` separately as CLI capabilities. Discover repository-native test, CI, and deployment entry points from repository files; their absence is a workflow fact to investigate, not a missing skill.

### 3. Repair

If this repository's bundled skills are missing, run the matching local install command:

```bash
scripts/setup-solo-ship.sh --target codex --install-local
```

If a Matt leaf skill is missing, present this command and wait for explicit confirmation before running it:

```bash
npx skills@latest add mattpocock/skills -g
```

After installation, link or copy the three selected skill directories into the host skill directory only when the host still cannot see them.

### 4. Verify

Rerun the relevant strict check:

```bash
scripts/setup-solo-ship.sh --target all --strict
```

Report host, missing leaf skill, CLI status, repository test/CI/deployment entry points, and the exact remaining repair command.
