from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SYNC = REPO / "scripts" / "sync-gstack-subset.py"
SETUP = REPO / "scripts" / "setup-gstack-subset.sh"
SNAPSHOT = REPO / "external" / "gstack"
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


def tree_digest(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def bash_path() -> str:
    git_bash = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
    if git_bash.is_file():
        return str(git_bash)
    found = shutil.which("bash")
    if not found:
        raise unittest.SkipTest("bash is unavailable")
    return found


def posix_path(path: Path) -> str:
    return path.resolve().as_posix()


def git(*args: str, cwd: Path) -> str:
    result = subprocess.run(
        ["git", *args], cwd=cwd, check=True, text=True, stdout=subprocess.PIPE
    )
    return result.stdout.strip()


class GstackSubsetTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def make_runtime(self) -> tuple[Path, str]:
        upstream = self.root / "runtime-upstream"
        (upstream / "browse" / "dist").mkdir(parents=True)
        browse = upstream / "browse" / "dist" / "browse"
        browse.write_text("#!/usr/bin/env bash\necho 'browse help'\n", encoding="ascii")
        browse.chmod(0o755)
        (upstream / "VERSION").write_text("test-version\n", encoding="ascii")
        git("init", "-q", cwd=upstream)
        git("config", "user.name", "Test", cwd=upstream)
        git("config", "user.email", "test@example.com", cwd=upstream)
        git("add", ".", cwd=upstream)
        git("commit", "-q", "-m", "fixture", cwd=upstream)
        return upstream, git("rev-parse", "HEAD", cwd=upstream)

    def make_install_snapshot(self, upstream: Path, commit: str) -> Path:
        snapshot = self.root / "snapshot"
        if snapshot.exists():
            shutil.rmtree(snapshot)
        shutil.copytree(SNAPSHOT, snapshot)
        manifest = json.loads((snapshot / "manifest.json").read_text(encoding="utf-8"))
        manifest["upstream_repository"] = upstream.as_uri()
        manifest["upstream_commit"] = commit
        manifest["upstream_version"] = "test-version"
        (snapshot / "manifest.json").write_text(
            json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
        )
        return snapshot

    def run_setup(
        self, snapshot: Path, upstream: Path, home: Path, *args: str, check: bool = True, **extra: str
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.update(
            {
                "HOME": posix_path(home),
                "CODEX_SKILLS_DIR": posix_path(home / ".codex" / "skills"),
                "CLAUDE_SKILLS_DIR": posix_path(home / ".claude" / "skills"),
                "GSTACK_RUNTIME_ROOT": posix_path(home / ".gstack" / "runtime"),
                "GSTACK_MANIFEST_PATH": posix_path(snapshot / "manifest.json"),
                "GSTACK_UPSTREAM_URL": upstream.as_uri(),
                "GSTACK_SKIP_BUILD": "1",
                "GSTACK_SKIP_BROWSER_INSTALL": "1",
                **extra,
            }
        )
        result = subprocess.run(
            [bash_path(), posix_path(SETUP), *args],
            env=env,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if check and result.returncode != 0:
            self.fail(result.stdout)
        return result

    def test_checked_in_snapshot_validates(self) -> None:
        subprocess.run(
            ["python", str(SYNC), "--validate-only"], cwd=REPO, check=True
        )

    def test_generation_failure_keeps_previous_output(self) -> None:
        upstream = self.root / "incomplete-upstream"
        upstream.mkdir()
        output = self.root / "existing-output"
        output.mkdir()
        marker = output / "keep.txt"
        marker.write_text("keep", encoding="ascii")

        result = subprocess.run(
            [
                "python",
                str(SYNC),
                "--upstream-dir",
                str(upstream),
                "--output",
                str(output),
            ],
            cwd=REPO,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        self.assertNotEqual(0, result.returncode)
        self.assertEqual("keep", marker.read_text(encoding="ascii"))

    def test_installs_only_selected_skills_for_both_hosts(self) -> None:
        upstream, commit = self.make_runtime()
        snapshot = self.make_install_snapshot(upstream, commit)
        home = self.root / "home"
        home.mkdir()

        self.run_setup(snapshot, upstream, home, "--target", "codex")
        self.run_setup(snapshot, upstream, home, "--target", "codex")
        self.run_setup(snapshot, upstream, home, "--target", "claude")
        self.run_setup(snapshot, upstream, home, "--target", "claude")

        codex = home / ".codex" / "skills"
        claude = home / ".claude" / "skills"
        self.assertEqual(set(SKILLS) | {"gstack"}, {p.name for p in codex.iterdir() if not p.name.startswith(".")})
        self.assertEqual(set(SKILLS) | {"gstack"}, {p.name for p in claude.iterdir() if not p.name.startswith(".")})
        self.assertFalse((codex / "gstack" / "SKILL.md").exists())
        for name in SKILLS:
            self.assertTrue((codex / name / "SKILL.md").is_file())
            self.assertTrue((claude / name / "SKILL.md").is_file())
        output = subprocess.check_output(
            [bash_path(), posix_path(home / ".gstack" / "runtime" / "browse" / "dist" / "browse")],
            text=True,
        )
        self.assertIn("browse help", output)

    def test_clone_failure_preserves_existing_install(self) -> None:
        upstream, commit = self.make_runtime()
        snapshot = self.make_install_snapshot(upstream, "0" * 40)
        home = self.root / "home-clone-failure"
        existing = home / ".codex" / "skills" / "qa"
        existing.mkdir(parents=True)
        marker = existing / "keep.txt"
        marker.write_text("keep", encoding="ascii")

        result = self.run_setup(
            snapshot,
            self.root / "missing-upstream",
            home,
            "--target",
            "codex",
            check=False,
        )
        self.assertNotEqual(0, result.returncode)
        self.assertEqual("keep", marker.read_text(encoding="ascii"))
        self.assertFalse((home / ".gstack" / "runtime").exists())

    def test_publish_failure_rolls_back_runtime_and_skills(self) -> None:
        upstream, commit = self.make_runtime()
        snapshot = self.make_install_snapshot(upstream, commit)
        home = self.root / "home-rollback"
        home.mkdir()
        self.run_setup(snapshot, upstream, home, "--target", "codex")
        original_skill = (home / ".codex" / "skills" / "qa" / "SKILL.md").read_bytes()

        (upstream / "new-file").write_text("new", encoding="ascii")
        git("add", ".", cwd=upstream)
        git("commit", "-q", "-m", "new fixture", cwd=upstream)
        new_commit = git("rev-parse", "HEAD", cwd=upstream)
        snapshot = self.make_install_snapshot(upstream, new_commit)
        result = self.run_setup(
            snapshot,
            upstream,
            home,
            "--target",
            "codex",
            check=False,
            GSTACK_FAILPOINT="after-runtime-publish",
        )

        self.assertNotEqual(0, result.returncode)
        self.assertEqual(
            commit, git("rev-parse", "HEAD", cwd=home / ".gstack" / "runtime")
        )
        self.assertEqual(
            original_skill,
            (home / ".codex" / "skills" / "qa" / "SKILL.md").read_bytes(),
        )


if __name__ == "__main__":
    unittest.main()
