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
codex debug prompt-input | rg "solo-ship|setup"
```

For Codex, the script copies skill folders by default so skills keep short names like `$solo-ship`. For Claude, it links skill folders by default, matching the `mattpocock/skills` local workflow. Existing non-symlink skill directories are moved to a timestamped backup folder instead of being deleted.

Check optional `solo-ship` dependency skills:

```bash
./scripts/check-solo-ship-deps.sh
```

The dependency checker is read-only. It reports whether Codex can see the recommended GStack, Superpowers, and Matt skills that `solo-ship` can orchestrate, then prints install guidance for anything missing. It does not install external skill packs or run setup commands.

Run the full setup check for Codex and Claude Code:

```bash
./scripts/setup-solo-ship.sh --target all
```

To install or refresh only this repository's bundled skills before checking:

```bash
./scripts/setup-solo-ship.sh --target codex --install-local
./scripts/setup-solo-ship.sh --target claude --install-local
```

The `setup` skill can repair this repo's local skill installation, but it still does not auto-install external packs or Codex plugins. Its current module checks `solo-ship`, reports missing phase capabilities, and gives the smallest manual command or plugin action for GStack, Superpowers, GitHub, and Matt skills.

## Skills

- [`solo-ship`](./skills/workflow/solo-ship/SKILL.md): Review, fix, commit, push, merge, verify, and clean up solo developer work.
- [`setup`](./skills/setup/SKILL.md): Install, check, and repair this skills package across Codex and Claude Code. Its first module covers the skills and plugins that `solo-ship` orchestrates.
- [`upgrading-dependencies`](./skills/workflow/upgrading-dependencies/SKILL.md): Audit, batch, upgrade, verify, and record dependency changes across package managers.

## Scripts

List bundled skills:

```bash
./scripts/list-skills.sh
```

Check `solo-ship` dependency skills:

```bash
./scripts/check-solo-ship-deps.sh
```

Check and optionally install this repo's local skills for a host:

```bash
./scripts/setup-solo-ship.sh --target codex
./scripts/setup-solo-ship.sh --target claude
./scripts/setup-solo-ship.sh --target all
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
- Matt skills: `tdd`, `diagnosing-bugs`

This repository does not auto-install those external packs. Use the checker first:

```bash
./scripts/check-solo-ship-deps.sh
```

For cross-host setup, use:

```bash
./scripts/setup-solo-ship.sh --target all
```

Codex plugin skills may appear with prefixes such as `github:yeet` and `github:github`. Claude Code often sees local skill folders without those prefixes, or no equivalent at all. `solo-ship` should be evaluated by phase capability: if the GitHub plugin skill is unavailable, use the explicit `git` and `gh` CLI fallback rather than treating the whole workflow as blocked.

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
codex debug prompt-input | rg "tdd|diagnosing-bugs"
```

Claude users can install this repo with `skills.sh` or run `./scripts/link-skills.sh --target claude`, but `solo-ship` dependency checking currently targets Codex only.
