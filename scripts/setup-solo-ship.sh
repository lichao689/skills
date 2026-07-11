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
  local kind="$4"

  if has_skill "$host" "$skill"; then
    printf '  skill  %-24s found (%s)\n' "$label:" "$skill"
  else
    printf '  skill  %-24s missing (%s)\n' "$label:" "$skill"
    if [ "$kind" = "local" ]; then
      MISSING_LOCAL=1
    else
      MISSING_MATT=1
    fi
  fi
}

print_cli() {
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    printf '  CLI    %-24s found\n' "$name:"
  else
    printf '  CLI    %-24s missing\n' "$name:"
    case "$name" in
      git) MISSING_GIT=1 ;;
      gh) MISSING_GH=1 ;;
    esac
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
  MISSING_LOCAL=0
  MISSING_MATT=0
  MISSING_GIT=0
  MISSING_GH=0

  echo "Solo Ship setup check ($host)"
  if [ "$host" = "codex" ] && [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ]; then
    echo "Source: codex debug prompt-input plus filesystem fallback"
  elif [ "$host" = "codex" ]; then
    echo "Source: filesystem fallback; Codex prompt-surface check unavailable"
  else
    echo "Source: ~/.claude/skills and ~/.agents/skills"
  fi
  echo

  print_skill "$host" "orchestrator" solo-ship local
  print_skill "$host" "Matt review leaf" code-review matt
  print_skill "$host" "Matt failure leaf" diagnosing-bugs matt
  print_skill "$host" "Matt conflict leaf" resolving-merge-conflicts matt
  print_cli git
  print_cli gh
  print_repo_tools

  if [ "$MISSING_LOCAL" -eq 1 ] || [ "$MISSING_MATT" -eq 1 ] || [ "$MISSING_GIT" -eq 1 ] || [ "$MISSING_GH" -eq 1 ]; then
    printf '\nRepair guidance\n'
  fi

  if [ "$MISSING_LOCAL" -eq 1 ]; then
    printf '\nLocal solo-ship skill:\n  scripts/setup-solo-ship.sh --target %s --install-local\n' "$host"
  fi

  if [ "$MISSING_MATT" -eq 1 ]; then
    cat <<'GUIDE'
Matt leaf skills:
  npx skills@latest add mattpocock/skills -g
GUIDE
  fi

  if [ "$MISSING_GIT" -eq 1 ]; then
    printf 'Git CLI:\n  Install Git with the host package manager, then rerun: scripts/setup-solo-ship.sh --target %s\n' "$host"
  fi

  if [ "$MISSING_GH" -eq 1 ]; then
    printf 'GitHub CLI:\n  Install GitHub CLI with the host package manager, then rerun: scripts/setup-solo-ship.sh --target %s\n' "$host"
  fi

  if [ "$STRICT" -eq 1 ] && { [ "$MISSING_LOCAL" -eq 1 ] || [ "$MISSING_MATT" -eq 1 ] || [ "$MISSING_GIT" -eq 1 ] || [ "$MISSING_GH" -eq 1 ]; }; then
    return 1
  fi
}

case "$TARGET" in
  codex|claude) check_host "$TARGET" ;;
  all)
    codex_status=0
    check_host codex || codex_status=$?
    echo
    claude_status=0
    check_host claude || claude_status=$?
    if [ "$codex_status" -ne 0 ] || [ "$claude_status" -ne 0 ]; then
      exit 1
    fi
    ;;
esac
