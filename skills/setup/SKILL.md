---
name: setup
description: Set up and repair this personal skills package across Codex and Claude Code. Use before first installing the package, after moving to a new machine, when a bundled skill is not visible, or when solo-ship reports missing orchestration skills or plugin-backed skills such as github:yeet, github:github, changelog, gh-address-comments, gh-fix-ci, Superpowers, GStack, or Matt Pocock skills. This is the expandable setup entrypoint for the repository.
---

# Setup

This is the top-level setup skill for this skills repository. It checks host visibility, installs or refreshes this repo's bundled skills when requested, and reports external dependencies that need user-controlled installation.

Default posture: checks are read-only. Installing this repository's own skills is allowed when the user asks for setup or repair. External packs, marketplace plugins, and third-party tools require explicit user confirmation and should usually be presented as commands or plugin actions rather than silently installed.

## Current Modules

- `solo-ship`: checks the skills and plugins that `solo-ship` can orchestrate across Codex and Claude Code.

Add future setup modules here as this repository grows.

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

Use `--strict` in automation when missing hard dependencies should fail the run.

## Process

### 1. Explore

Inspect the real repository and host surfaces:

```bash
git status --short --branch
scripts/setup-solo-ship.sh --target all
```

For Codex-specific visibility, prefer `codex debug prompt-input` over filesystem guesses. Codex plugin skills may appear with prefixes such as `github:yeet` and `superpowers:verification-before-completion`.

For Claude Code, check `~/.claude/skills` and `~/.agents/skills`. Claude may not see Codex plugin-prefixed names; that is a host capability mismatch, not necessarily a broken bundled skill.

### 2. Interpret

Evaluate by phase capability, not by one exact skill name:

- Review is satisfied by `review`; do not treat `gstack-review` as required when GStack registers the skill as `review`.
- Commit and push is best satisfied by `github:yeet` in Codex. In Claude, accept an equivalent `yeet` skill when installed, otherwise fall back to explicit `git` plus `gh` CLI steps.
- PR review is best satisfied by `github:github` plus `github:gh-address-comments` in Codex. In Claude, accept unprefixed equivalents or use `gh pr view`, `gh pr diff`, `gh pr checks`, and `gh pr comment` manually.
- CI fix is best satisfied by `github:gh-fix-ci` in Codex, or `gh-fix-ci` / manual `gh run` inspection elsewhere.
- Docs are satisfied by `document-release` or `changelog`; if both are absent, record a manual changelog note.

### 3. Repair

If only this repo's skills are missing, run the local install command:

```bash
scripts/setup-solo-ship.sh --target codex --install-local
```

Use `--target claude` or `--target all` when the user is fixing Claude Code as well.

For external dependencies, present the smallest relevant option and wait for the user's reply before running it:

1. GStack skills: update `/Users/lichao/.gstack/repos/gstack`, then run its setup for the affected host.
2. Codex GitHub plugin: enable or refresh the GitHub plugin in Codex so `github:yeet`, `github:github`, `github:gh-address-comments`, and `github:gh-fix-ci` become visible.
3. Codex Superpowers plugin: enable or refresh the Superpowers plugin so prefixed Superpowers skills become visible.
4. Matt skills: run `npx skills@latest add mattpocock/skills -g`, then link selected skills into the host skill directory if needed.

Do not rewrite bundled skills to require host-specific plugin names when a phase-level fallback exists. Prefer documenting alternatives in the orchestration table.

### 4. Verify

After repairs, rerun:

```bash
scripts/setup-solo-ship.sh --target all --strict
```

For Codex, also verify visible names:

```bash
codex debug prompt-input | rg "setup|solo-ship|github:yeet|github:github|changelog|ship|review"
```

Report the host, missing phase, visible alternatives, fallback path, and any command the user still needs to run.
