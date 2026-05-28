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

Check optional `solo-ship` dependency skills:

```bash
./scripts/check-solo-ship-deps.sh
```

The dependency checker is read-only. It reports whether Codex can see the recommended GStack, Superpowers, and Matt skills that `solo-ship` can orchestrate, then prints install guidance for anything missing. It does not install external skill packs or run setup commands.

## Skills

- [`solo-ship`](./skills/workflow/solo-ship/SKILL.md): Review, fix, commit, push, merge, verify, and clean up solo developer work.

## Scripts

List bundled skills:

```bash
./scripts/list-skills.sh
```

Check `solo-ship` dependency skills:

```bash
./scripts/check-solo-ship-deps.sh
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

## Solo Ship Dependencies

`solo-ship` is an orchestration skill. It works best when these skill groups are available to Codex:

- GStack: `ship`, `review`, `health`, `land-and-deploy`, `careful`, `guard`
- Superpowers: `superpowers:verification-before-completion`, `superpowers:receiving-code-review`, `superpowers:systematic-debugging`, `superpowers:finishing-a-development-branch`, `superpowers:test-driven-development`
- Matt skills: `tdd`, `diagnose`, `grill-me`, `zoom-out`

This repository does not auto-install those external packs. Use the checker first:

```bash
./scripts/check-solo-ship-deps.sh
```

### GStack

If GStack already exists on the machine:

```bash
cd /Users/lichao/.gstack/repos/gstack
git pull --ff-only
./setup --host codex --quiet
gstack-config set skill_prefix false
codex debug prompt-input | rg "ship|review|health|land-and-deploy"
```

If GStack is not installed, install or clone GStack first, then run its Codex setup. The dependency checker intentionally does not clone or install GStack for you.

### Superpowers

Install or enable the Superpowers plugin from Codex's plugin system, restart Codex if needed, then verify:

```bash
codex plugin marketplace list
codex plugin marketplace upgrade
codex debug prompt-input | rg "superpowers:verification-before-completion|superpowers:receiving-code-review"
```

The dependency checker does not modify Codex plugin marketplace configuration.

### Matt Skills

Use the skills.sh installer:

```bash
npx skills@latest add mattpocock/skills -g
```

Select the Matt skills and agents you want. If Codex cannot see selected skills after installation, copy or link the selected skill folders from `~/.agents/skills` into `~/.codex/skills`, then verify:

```bash
codex debug prompt-input | rg "tdd|diagnose|grill-me|zoom-out"
```

Claude users can install this repo with `skills.sh` or run `./scripts/link-skills.sh --target claude`, but `solo-ship` dependency checking currently targets Codex only.
