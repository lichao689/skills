# lichao689 Skills

Personal Codex skills.

## Quickstart

Install with the skills.sh installer:

```bash
npx skills@latest add lichao689/skills
```

For Codex on this machine, the most reliable install path is to clone this repo and sync the skills into `~/.codex/skills`:

```bash
git clone git@github.com:lichao689/skills.git ~/Developer/lichao689-skills
cd ~/Developer/lichao689-skills
./scripts/link-skills.sh --target codex
codex debug prompt-input | rg "solo-ship"
```

For Codex, the script copies skill folders by default so skills keep short names like `$solo-ship`. For Claude, it links skill folders by default, matching the `mattpocock/skills` local workflow. Existing non-symlink skill directories are moved to a timestamped backup folder instead of being deleted.

## Skills

- [`solo-ship`](./skills/workflow/solo-ship/SKILL.md): Review, fix, commit, push, merge, verify, and clean up solo developer work.

## Scripts

List bundled skills:

```bash
./scripts/list-skills.sh
```

Sync skills for Codex:

```bash
./scripts/link-skills.sh --target codex
```

Link skills for Claude:

```bash
./scripts/link-skills.sh --target claude
```

Link skills for both:

```bash
./scripts/link-skills.sh --target all
```

Force symlinks instead of copies:

```bash
./scripts/link-skills.sh --target codex --strategy link
```
