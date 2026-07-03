# lichao689 Skills

Personal Codex / Claude Code skills.

## Install

Install from GitHub:

```bash
npx skills@latest add lichao689/skills
```

Or clone the repo and sync the bundled skills locally:

```bash
git clone git@github.com:lichao689/skills.git ~/Developer/lichao689-skills
cd ~/Developer/lichao689-skills
./scripts/link-skills.sh --target codex
```

Use `--target claude` or `--target all` for Claude Code or both hosts.

## Skills

- [`solo-ship`](./skills/workflow/solo-ship/SKILL.md): Finish solo development work end to end: review, fix, test, commit, push, merge, verify, and clean up.
- [`rules-curator`](./skills/workflow/rules-curator/SKILL.md): Curate durable repository rules before writing root agent instruction files.
- [`setup`](./skills/setup/SKILL.md): Install, check, and repair this skills package across Codex and Claude Code.

## Scripts

```bash
./scripts/list-skills.sh
./scripts/link-skills.sh --target codex
./scripts/check-solo-ship-deps.sh
./scripts/setup-solo-ship.sh --target all
```

`link-skills.sh` copies skills for Codex by default and links them for Claude by default. Existing non-symlink skill directories are moved to a timestamped backup folder instead of being deleted.

## Notes

`solo-ship` can orchestrate other optional skill packs, including GStack, Superpowers, and Matt Pocock's skills. This repo does not install those external packs automatically; run `./scripts/check-solo-ship-deps.sh` to see what Codex can currently access.
