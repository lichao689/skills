#!/usr/bin/env python3
"""Generate and validate the curated gstack skill snapshots."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


SKILLS = (
    "plan-eng-review",
    "qa",
    "browse",
    "office-hours",
    "plan-ceo-review",
    "plan-design-review",
    "design-review",
    "autoplan",
    "document-release",
    "document-generate",
    "plan-devex-review",
    "devex-review",
    "cso",
)
UPSTREAM_URL = "https://github.com/garrytan/gstack.git"
UPSTREAM_REF = "main"
NOTICE = (
    "> Curated distribution: updates are managed by `lichao689/skills`. Only the "
    "13 selected skills are installed. References to other slash commands, including "
    "`/ship`, are upstream recommendations and are not bundled.\n"
)


def run(*args: str, cwd: Path | None = None, capture: bool = False) -> str:
    result = subprocess.run(
        args,
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    return result.stdout.strip() if capture else ""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def add_notice(text: str) -> str:
    closing = text.find("\n---", 4)
    if closing < 0:
        raise ValueError("skill frontmatter is not terminated")
    insert_at = text.find("\n", closing + 1) + 1
    return text[:insert_at] + "\n" + NOTICE + "\n" + text[insert_at:]


def adapt_skill(text: str, host: str) -> str:
    text = text.replace("\r\n", "\n")
    lines = []
    for line in text.splitlines():
        if "gstack-update-check" in line and line.lstrip().startswith("_UPD="):
            lines.append(
                "# Upstream updates are managed by lichao689/skills; do not run gstack self-update."
            )
            continue
        if line.strip() == '[ -n "$_UPD" ] && echo "$_UPD" || true':
            continue
        if line.startswith("If output shows `UPGRADE_AVAILABLE "):
            continue
        if line.startswith("If output shows `JUST_UPGRADED "):
            continue
        lines.append(line)
    text = "\n".join(lines).rstrip() + "\n"

    if host == "codex":
        old = 'GSTACK_ROOT="$HOME/.codex/skills/gstack"'
        new = 'GSTACK_ROOT="${GSTACK_RUNTIME_ROOT:-$HOME/.gstack/runtime}"'
        if old not in text:
            raise ValueError("Codex runtime root marker was not found")
        text = text.replace(old, new)
    elif host == "claude":
        old = "~/.claude/skills/gstack"
        if old not in text:
            raise ValueError("Claude runtime root marker was not found")
        text = text.replace(old, "${GSTACK_RUNTIME_ROOT:-$HOME/.gstack/runtime}")
    else:
        raise ValueError(f"unsupported host: {host}")

    return add_notice(text)


def copy_resources(source: Path, destination: Path) -> None:
    resource_directories = {"assets", "references", "sections", "templates"}
    root_resource_files = {"ACKNOWLEDGEMENTS.md", "dx-hall-of-fame.md"}
    for path in source.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(source)
        if len(relative.parts) > 1 and relative.parts[0] not in resource_directories:
            continue
        if (
            len(relative.parts) == 1
            and relative.name not in root_resource_files
            and relative.name != "SKILL.md.tmpl"
        ):
            continue
        if relative.name == "SKILL.md":
            continue
        if relative.name == "SKILL.md.tmpl":
            relative = Path("SKILL.claude.md.tmpl")
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if path.suffix in {".json", ".md", ".tmpl", ".yaml", ".yml"}:
            text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
            target.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")
        else:
            shutil.copy2(path, target)


def frontmatter_name(path: Path) -> str:
    match = re.search(r"(?m)^name:\s*([^\s]+)\s*$", path.read_text(encoding="utf-8"))
    if not match:
        raise ValueError(f"missing frontmatter name: {path}")
    return match.group(1)


def validate(output: Path, upstream: Path | None = None) -> dict:
    manifest_path = output / "manifest.json"
    if not manifest_path.is_file():
        raise ValueError(f"missing manifest: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if tuple(manifest.get("skills", ())) != SKILLS:
        raise ValueError("manifest skill list does not match the curated 13-skill set")
    if manifest.get("upstream_repository") != UPSTREAM_URL:
        raise ValueError("manifest upstream repository is unexpected")
    if not re.fullmatch(r"[0-9a-f]{40}", manifest.get("upstream_commit", "")):
        raise ValueError("manifest upstream commit is not a full Git commit")
    if not (output / "LICENSE.upstream").is_file():
        raise ValueError("upstream license is missing")

    skill_root = output / "skills"
    actual = tuple(sorted(path.name for path in skill_root.iterdir() if path.is_dir()))
    if actual != tuple(sorted(SKILLS)):
        raise ValueError("snapshot directories do not match the manifest")
    bare_skill_files = list(output.rglob("SKILL.md"))
    if bare_skill_files:
        raise ValueError(f"bare SKILL.md would be auto-discovered: {bare_skill_files[0]}")

    hard_ref = re.compile(r"(?:gstack/|GSTACK_ROOT/)([a-z0-9-]+)/SKILL\.md")
    for name in SKILLS:
        directory = skill_root / name
        for variant in ("codex", "claude"):
            path = directory / f"SKILL.{variant}.md"
            if not path.is_file():
                raise ValueError(f"missing {variant} snapshot for {name}")
            if frontmatter_name(path) != name:
                raise ValueError(f"{variant} frontmatter name mismatch for {name}")
            text = path.read_text(encoding="utf-8")
            if "gstack-upgrade" in text or "gstack-update-check" in text:
                raise ValueError(f"self-update dependency remains in {path}")
            for dependency in hard_ref.findall(text):
                if dependency not in SKILLS:
                    raise ValueError(f"unselected hard dependency {dependency!r} in {path}")

    if upstream is not None:
        expected_commit = run("git", "rev-parse", "HEAD", cwd=upstream, capture=True)
        if manifest["upstream_commit"] != expected_commit:
            raise ValueError("manifest commit does not match the supplied upstream checkout")
        upstream_license = (upstream / "LICENSE").read_text(encoding="utf-8").replace("\r\n", "\n")
        if (output / "LICENSE.upstream").read_text(encoding="utf-8") != upstream_license.rstrip() + "\n":
            raise ValueError("license snapshot does not match upstream")
    return manifest


def generate(upstream: Path, output: Path) -> None:
    for name in SKILLS:
        if not (upstream / name / "SKILL.md").is_file():
            raise ValueError(f"upstream skill is missing: {name}")
    generator = upstream / "scripts" / "gen-skill-docs.ts"
    run("bun", "run", str(generator), "--host", "codex", cwd=upstream)

    commit = run("git", "rev-parse", "HEAD", cwd=upstream, capture=True)
    version = (upstream / "VERSION").read_text(encoding="utf-8").strip()
    staging_parent = output.parent
    staging_parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=".gstack-sync-", dir=staging_parent))
    try:
        license_text = (upstream / "LICENSE").read_text(encoding="utf-8").replace("\r\n", "\n")
        (staging / "LICENSE.upstream").write_text(
            license_text.rstrip() + "\n", encoding="utf-8", newline="\n"
        )
        skill_root = staging / "skills"
        for name in SKILLS:
            destination = skill_root / name
            destination.mkdir(parents=True)
            generated = upstream / ".agents" / "skills" / f"gstack-{name}"
            (destination / "SKILL.codex.md").write_text(
                adapt_skill((generated / "SKILL.md").read_text(encoding="utf-8"), "codex"),
                encoding="utf-8",
                newline="\n",
            )
            (destination / "SKILL.claude.md").write_text(
                adapt_skill((upstream / name / "SKILL.md").read_text(encoding="utf-8"), "claude"),
                encoding="utf-8",
                newline="\n",
            )
            copy_resources(upstream / name, destination)
            if (generated / "agents" / "openai.yaml").is_file():
                agents = destination / "agents"
                agents.mkdir()
                shutil.copy2(generated / "agents" / "openai.yaml", agents / "openai.yaml")

        manifest = {
            "snapshot_format": 1,
            "upstream_repository": UPSTREAM_URL,
            "upstream_ref": UPSTREAM_REF,
            "upstream_version": version,
            "upstream_commit": commit,
            "generator": "scripts/gen-skill-docs.ts",
            "generator_sha256": sha256(generator),
            "skills": list(SKILLS),
        }
        (staging / "manifest.json").write_text(
            json.dumps(manifest, indent=2, ensure_ascii=True) + "\n",
            encoding="utf-8",
            newline="\n",
        )
        validate(staging, upstream)

        backup = output.with_name(output.name + ".previous")
        if backup.exists():
            shutil.rmtree(backup)
        if output.exists():
            output.rename(backup)
        try:
            staging.rename(output)
        except BaseException:
            if backup.exists() and not output.exists():
                backup.rename(output)
            raise
        if backup.exists():
            shutil.rmtree(backup)
    finally:
        if staging.exists():
            shutil.rmtree(staging)


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upstream-dir", type=Path)
    parser.add_argument("--upstream-url", default=UPSTREAM_URL)
    parser.add_argument("--ref", default=UPSTREAM_REF)
    parser.add_argument("--output", type=Path, default=repo / "external" / "gstack")
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()

    if args.validate_only:
        manifest = validate(output)
        print(
            f"validated gstack {manifest['upstream_version']} "
            f"({manifest['upstream_commit'][:12]}), {len(SKILLS)} skills"
        )
        return 0

    temporary: tempfile.TemporaryDirectory[str] | None = None
    if args.upstream_dir:
        upstream = args.upstream_dir.resolve()
    else:
        temporary = tempfile.TemporaryDirectory(prefix="gstack-upstream-")
        upstream = Path(temporary.name) / "gstack"
        run("git", "clone", "--depth", "1", "--branch", args.ref, args.upstream_url, str(upstream))
    try:
        generate(upstream, output)
        manifest = validate(output, upstream)
        print(
            f"synced gstack {manifest['upstream_version']} "
            f"({manifest['upstream_commit'][:12]}), {len(SKILLS)} skills"
        )
    finally:
        if temporary is not None:
            temporary.cleanup()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
