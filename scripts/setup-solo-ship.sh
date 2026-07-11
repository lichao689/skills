#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/setup-solo-ship.sh [--target codex|claude|all] [--install-local] [--strict]

Checks and optionally installs this repository's local skills for the solo-ship workflow.
The external Matt skill pack and CLI tools are never installed by this script.

Options:
  --target        Host surface to check. Default: codex.
  --install-local Install this repo's bundled skills into the selected host(s) before checking.
  --strict        Exit 1 when solo-ship, a Matt leaf skill, Git, or GitHub CLI is missing.
  -h,--help       Show this help text.
USAGE
}

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="codex"
INSTALL_LOCAL=0
STRICT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --install-local) INSTALL_LOCAL=1; shift ;;
    --strict) STRICT=1; shift ;;
    -h|--help) usage; exit 0 ;;
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
    echo "error: unsupported target: $TARGET" >&2
    usage >&2
    exit 1
    ;;
esac

if [ "$INSTALL_LOCAL" -eq 1 ]; then
  "$REPO/scripts/link-skills.sh" --target "$TARGET"
  echo
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CODEX_PROMPT="$TMP_DIR/codex-prompt.txt"
CODEX_PROMPT_AVAILABLE=0
if { [ "$TARGET" = "codex" ] || [ "$TARGET" = "all" ]; } &&
  command -v codex >/dev/null 2>&1 &&
  codex debug prompt-input >"$CODEX_PROMPT" 2>/dev/null; then
  CODEX_PROMPT_AVAILABLE=1
fi

has_skill() {
  local host="$1"
  local skill="$2"

  if [ "$host" = "codex" ]; then
    if [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ] && grep -F -- "- $skill:" "$CODEX_PROMPT" >/dev/null 2>&1; then
      return 0
    fi
    [ -d "$HOME/.codex/skills/$skill" ] || [ -d "$HOME/.agents/skills/$skill" ]
    return $?
  fi

  [ -d "$HOME/.claude/skills/$skill" ] || [ -d "$HOME/.agents/skills/$skill" ]
}

print_skill() {
  local host="$1"
  local label="$2"
  local skill="$3"

  if has_skill "$host" "$skill"; then
    printf '  skill  %-24s found (%s)\n' "$label:" "$skill"
  else
    printf '  skill  %-24s missing (%s)\n' "$label:" "$skill"
    MISSING_ANY=1
  fi
}

print_cli() {
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    printf '  CLI    %-24s found\n' "$name:"
  else
    printf '  CLI    %-24s missing\n' "$name:"
    MISSING_ANY=1
  fi
}

print_repo_tools() {
  if [ -f "$REPO/package.json" ] || [ -f "$REPO/pyproject.toml" ] || [ -f "$REPO/Makefile" ] || [ -d "$REPO/tests" ]; then
    echo "  repo   test entry points:       detected"
  else
    echo "  repo   test entry points:       not detected"
  fi

  if [ -d "$REPO/.github/workflows" ]; then
    echo "  repo   CI configuration:        detected"
  else
    echo "  repo   CI configuration:        not detected"
  fi

  if find "$REPO" -maxdepth 3 -type f \( -iname '*deploy*' -o -iname 'Dockerfile' -o -iname 'compose.yml' -o -iname 'docker-compose.yml' \) -print -quit 2>/dev/null | grep . >/dev/null 2>&1; then
    echo "  repo   deployment entry points: detected"
  else
    echo "  repo   deployment entry points: not detected"
  fi
}

check_host() {
  local host="$1"
  MISSING_ANY=0

  echo "Solo Ship setup check ($host)"
  if [ "$host" = "codex" ] && [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ]; then
    echo "Source: codex debug prompt-input plus filesystem fallback"
  elif [ "$host" = "codex" ]; then
    echo "Source: filesystem fallback; Codex prompt-surface check unavailable"
  else
    echo "Source: ~/.claude/skills and ~/.agents/skills"
  fi
  echo

  print_skill "$host" "orchestrator" solo-ship
  print_skill "$host" "Matt review leaf" code-review
  print_skill "$host" "Matt failure leaf" diagnosing-bugs
  print_skill "$host" "Matt conflict leaf" resolving-merge-conflicts
  print_cli git
  print_cli gh
  print_repo_tools

  if [ "$MISSING_ANY" -eq 1 ]; then
    cat <<'GUIDE'

Repair guidance

Local solo-ship skill:
  scripts/setup-solo-ship.sh --target codex --install-local
  scripts/setup-solo-ship.sh --target claude --install-local

Matt leaf skills:
  npx skills@latest add mattpocock/skills -g

Install Git or GitHub CLI through the host package manager when its CLI status is missing.
GUIDE
  fi

  if [ "$STRICT" -eq 1 ] && [ "$MISSING_ANY" -eq 1 ]; then
    return 1
  fi
}

case "$TARGET" in
  codex|claude) check_host "$TARGET" ;;
  all)
    check_host codex
    echo
    check_host claude
    ;;
esac
