#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/setup-gstack-subset.sh --target codex|claude|all [--dry-run]

Installs the curated gstack skills and their locked shared runtime. Existing
non-managed skills are moved into a timestamped backup directory.
USAGE
}

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
TARGET=""
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$TARGET" in
  codex|claude|all) ;;
  *)
    echo "error: --target must be codex, claude, or all" >&2
    usage >&2
    exit 1
    ;;
esac

for command_name in git bun python3; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "error: required command is unavailable: $command_name" >&2
    exit 1
  fi
done

MANIFEST="${GSTACK_MANIFEST_PATH:-$REPO/external/gstack/manifest.json}"
SNAPSHOT_ROOT="$(cd "$(dirname "$MANIFEST")" && pwd -P)"
if [ ! -f "$MANIFEST" ]; then
  echo "error: gstack manifest is missing: $MANIFEST" >&2
  exit 1
fi

manifest_value() {
  python3 -c 'import json,sys; sys.stdout.write(str(json.load(open(sys.argv[1], encoding="utf-8"))[sys.argv[2]]))' "$MANIFEST" "$1"
}

manifest_skills() {
  python3 -c 'import json,sys; values=json.load(open(sys.argv[1], encoding="utf-8"))["skills"]; sys.stdout.buffer.write(("\0".join(values)+"\0").encode())' "$MANIFEST"
}

UPSTREAM_REPOSITORY="${GSTACK_UPSTREAM_URL:-$(manifest_value upstream_repository)}"
UPSTREAM_COMMIT="$(manifest_value upstream_commit)"
UPSTREAM_VERSION="$(manifest_value upstream_version)"
RUNTIME_ROOT="${GSTACK_RUNTIME_ROOT:-$HOME/.gstack/runtime}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mapfile -d '' -t SKILLS < <(manifest_skills)

if [ "${#SKILLS[@]}" -ne 13 ]; then
  echo "error: manifest must contain exactly 13 curated skills" >&2
  exit 1
fi

echo "gstack version: $UPSTREAM_VERSION ($UPSTREAM_COMMIT)"
echo "runtime: $RUNTIME_ROOT"
case "$TARGET" in
  codex) echo "skills: $CODEX_SKILLS_DIR" ;;
  claude) echo "skills: $CLAUDE_SKILLS_DIR" ;;
  all) echo "skills: $CODEX_SKILLS_DIR and $CLAUDE_SKILLS_DIR" ;;
esac

if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry-run: would fetch/build the locked runtime and publish ${#SKILLS[@]} curated skills"
  exit 0
fi

runtime_is_current() {
  [ -d "$RUNTIME_ROOT/.git" ] || return 1
  [ "$(git -C "$RUNTIME_ROOT" rev-parse HEAD 2>/dev/null || true)" = "$UPSTREAM_COMMIT" ] || return 1
  find "$RUNTIME_ROOT/browse/dist" -maxdepth 1 -type f -name 'browse*' -print -quit 2>/dev/null | grep -q .
}

mkdir -p "$(dirname "$RUNTIME_ROOT")"
WORK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gstack-subset.XXXXXX")"
RUNTIME_STAGE=""
PUBLISHED_TARGETS=()
PUBLISHED_BACKUPS=()
PUBLISHED_OWNED=()
PUBLISHED_KINDS=()
COMMITTED=0

remove_published_path() {
  local path="$1"
  local kind="$2"
  if [ "$kind" = "junction" ]; then
    MSYS2_ARG_CONV_EXCL='*' cmd.exe /c rmdir "$(cygpath -w "$path")" >/dev/null 2>&1 || true
  else
    rm -rf "$path"
  fi
}

rollback() {
  local status=$?
  if [ "$status" -ne 0 ] && [ "$COMMITTED" -eq 0 ]; then
    echo "install failed; restoring the previous installation" >&2
    local index
    for ((index=${#PUBLISHED_TARGETS[@]}-1; index>=0; index--)); do
      remove_published_path "${PUBLISHED_TARGETS[$index]}" "${PUBLISHED_KINDS[$index]}"
      if [ -n "${PUBLISHED_BACKUPS[$index]}" ] && [ -e "${PUBLISHED_BACKUPS[$index]}" -o -L "${PUBLISHED_BACKUPS[$index]}" ]; then
        mv "${PUBLISHED_BACKUPS[$index]}" "${PUBLISHED_TARGETS[$index]}"
      fi
    done
  fi
  rm -rf "$WORK_ROOT"
  exit "$status"
}
trap rollback EXIT INT TERM

if runtime_is_current; then
  echo "reusing the locked runtime"
else
  echo "checking upstream access"
  git ls-remote "$UPSTREAM_REPOSITORY" HEAD >/dev/null
  RUNTIME_STAGE="$(dirname "$RUNTIME_ROOT")/.runtime-stage-$$"
  rm -rf "$RUNTIME_STAGE"
  git init -q "$RUNTIME_STAGE"
  git -C "$RUNTIME_STAGE" remote add origin "$UPSTREAM_REPOSITORY"
  git -C "$RUNTIME_STAGE" fetch -q --depth 1 origin "$UPSTREAM_COMMIT"
  git -C "$RUNTIME_STAGE" checkout -q --detach FETCH_HEAD
  if [ "$(git -C "$RUNTIME_STAGE" rev-parse HEAD)" != "$UPSTREAM_COMMIT" ]; then
    echo "error: fetched runtime does not match the manifest commit" >&2
    exit 1
  fi

  if [ "${GSTACK_SKIP_BUILD:-0}" != "1" ]; then
    (
      cd "$RUNTIME_STAGE"
      bun install --frozen-lockfile
      bun run build
      if [ "${GSTACK_SKIP_BROWSER_INSTALL:-0}" != "1" ]; then
        bunx playwright install chromium
      fi
    )
  fi
  if ! find "$RUNTIME_STAGE/browse/dist" -maxdepth 1 -type f -name 'browse*' -print -quit 2>/dev/null | grep -q .; then
    echo "error: built browse executable is missing" >&2
    exit 1
  fi
  printf '%s\n' "$UPSTREAM_COMMIT" > "$RUNTIME_STAGE/.lichao689-gstack-runtime"
fi

prepare_host() {
  local host="$1"
  local host_stage="$WORK_ROOT/$host"
  local name
  mkdir -p "$host_stage"
  for name in "${SKILLS[@]}"; do
    local source="$SNAPSHOT_ROOT/skills/$name"
    local destination="$host_stage/$name"
    if [ ! -f "$source/SKILL.$host.md" ]; then
      echo "error: missing $host snapshot for $name at $source" >&2
      exit 1
    fi
    mkdir -p "$destination"
    cp -R "$source/." "$destination/"
    cp "$source/SKILL.$host.md" "$destination/SKILL.md"
    rm -f "$destination/SKILL.codex.md" "$destination/SKILL.claude.md" "$destination/SKILL.claude.md.tmpl"
    if [ "$host" = "claude" ]; then
      rm -rf "$destination/agents"
    fi
    printf '%s %s\n' "$UPSTREAM_VERSION" "$UPSTREAM_COMMIT" > "$destination/.lichao689-gstack-managed"
  done
  if [ "$host" = "codex" ]; then
    mkdir -p "$host_stage/gstack"
    printf '%s\n' "$RUNTIME_ROOT" > "$host_stage/gstack/RUNTIME_ROOT"
    printf '%s\n' "$UPSTREAM_VERSION" > "$host_stage/gstack/VERSION"
    printf '%s\n' "$UPSTREAM_COMMIT" > "$host_stage/gstack/.lichao689-gstack-managed"
  fi
}

case "$TARGET" in
  codex) prepare_host codex ;;
  claude) prepare_host claude ;;
  all)
    prepare_host codex
    prepare_host claude
    ;;
esac

publish_path() {
  local source="$1"
  local target="$2"
  local backup_root="$3"
  local kind="${4:-directory}"
  local backup=""
  local owned=0
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -f "$target/.lichao689-gstack-managed" ] || [ -f "$target/.lichao689-gstack-runtime" ]; then
      owned=1
    fi
    mkdir -p "$backup_root"
    backup="$backup_root/$(basename "$target")"
    remove_published_path "$backup" "$kind"
    mv "$target" "$backup"
  fi
  mv "$source" "$target"
  PUBLISHED_TARGETS+=("$target")
  PUBLISHED_BACKUPS+=("$backup")
  PUBLISHED_OWNED+=("$owned")
  PUBLISHED_KINDS+=("$kind")
}

publish_runtime_link() {
  local target="$1"
  local backup_root="$2"
  local kind="$3"
  local backup=""
  local owned=0
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -f "$target/.lichao689-gstack-runtime" ]; then
      owned=1
    fi
    mkdir -p "$backup_root"
    backup="$backup_root/$(basename "$target")"
    remove_published_path "$backup" "$kind"
    mv "$target" "$backup"
  fi
  if [ "$kind" = "junction" ]; then
    MSYS2_ARG_CONV_EXCL='*' cmd.exe /c mklink /J "$(cygpath -w "$target")" "$(cygpath -w "$RUNTIME_ROOT")" >/dev/null
  else
    ln -s "$RUNTIME_ROOT" "$target"
  fi
  PUBLISHED_TARGETS+=("$target")
  PUBLISHED_BACKUPS+=("$backup")
  PUBLISHED_OWNED+=("$owned")
  PUBLISHED_KINDS+=("$kind")
}

timestamp="$(date +%Y%m%d%H%M%S)-$$"
if [ -n "$RUNTIME_STAGE" ]; then
  publish_path "$RUNTIME_STAGE" "$RUNTIME_ROOT" "$(dirname "$RUNTIME_ROOT")/.backup-$timestamp"
fi

if [ "${GSTACK_FAILPOINT:-}" = "after-runtime-publish" ]; then
  echo "error: requested publish failpoint" >&2
  false
fi

publish_host() {
  local host="$1"
  local skills_dir="$2"
  local name
  mkdir -p "$skills_dir"
  for name in "${SKILLS[@]}"; do
    publish_path "$WORK_ROOT/$host/$name" "$skills_dir/$name" "$skills_dir/.backup-$timestamp"
  done
  if [ "$host" = "codex" ]; then
    publish_path "$WORK_ROOT/codex/gstack" "$skills_dir/gstack" "$skills_dir/.backup-$timestamp"
  fi
}

case "$TARGET" in
  codex) publish_host codex "$CODEX_SKILLS_DIR" ;;
  claude) publish_host claude "$CLAUDE_SKILLS_DIR" ;;
  all)
    publish_host codex "$CODEX_SKILLS_DIR"
    publish_host claude "$CLAUDE_SKILLS_DIR"
    ;;
esac

# Keep the official Claude runtime path available without duplicating the runtime.
if [ "$TARGET" = "claude" ] || [ "$TARGET" = "all" ]; then
  compatibility="$CLAUDE_SKILLS_DIR/gstack"
  if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
    publish_runtime_link "$compatibility" "$CLAUDE_SKILLS_DIR/.backup-$timestamp" junction
  else
    publish_runtime_link "$compatibility" "$CLAUDE_SKILLS_DIR/.backup-$timestamp" symlink
  fi
fi

COMMITTED=1
for ((index=0; index<${#PUBLISHED_TARGETS[@]}; index++)); do
  backup="${PUBLISHED_BACKUPS[$index]}"
  if [ -n "$backup" ]; then
    if [ "${PUBLISHED_OWNED[$index]}" -eq 1 ]; then
      remove_published_path "$backup" "${PUBLISHED_KINDS[$index]}"
    else
      echo "backed up existing ${PUBLISHED_TARGETS[$index]} -> $backup"
    fi
  fi
done

rm -rf "$WORK_ROOT"
trap - EXIT INT TERM
echo "installed ${#SKILLS[@]} curated gstack skills for $TARGET"
