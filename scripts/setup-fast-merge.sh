#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/setup-fast-merge.sh [--target codex|claude|all] [--install-local] [--strict]

Checks and optionally installs this repository's skills for fast-merge.
The external Matt skill pack and CLI tools are never installed by this script.
USAGE
}

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"
TARGET=codex
INSTALL_LOCAL=0
STRICT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --install-local) INSTALL_LOCAL=1; shift ;;
    --strict) STRICT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$TARGET" in codex|claude|all) ;; *) echo "error: unsupported target: $TARGET" >&2; exit 1 ;; esac

if [ "$INSTALL_LOCAL" -eq 1 ]; then
  "$REPO/scripts/link-skills.sh" --target "$TARGET"
  echo
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
CODEX_PROMPT="$TMP_DIR/codex-prompt.txt"
CODEX_PROMPT_AVAILABLE=0
if { [ "$TARGET" = codex ] || [ "$TARGET" = all ]; } && command -v codex >/dev/null 2>&1 && codex debug prompt-input >"$CODEX_PROMPT" 2>/dev/null; then
  CODEX_PROMPT_AVAILABLE=1
fi

has_skill() {
  local host="$1" skill="$2"
  if [ "$host" = codex ]; then
    if [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ] && grep -F -- "- $skill:" "$CODEX_PROMPT" >/dev/null 2>&1; then return 0; fi
    [ -d "$HOME/.codex/skills/$skill" ] || [ -d "$HOME/.agents/skills/$skill" ]
  else
    [ -d "$HOME/.claude/skills/$skill" ] || [ -d "$HOME/.agents/skills/$skill" ]
  fi
}

repo_requires_github_pr() {
  local configured relative lower absolute
  configured="$(git -C "$PROJECT_ROOT" config --get fast-merge.prRoute 2>/dev/null || true)"
  case "${FAST_MERGE_PR_ROUTE:-$configured}" in
    github-pr) return 0 ;;
    direct|none) return 1 ;;
    auto|'') ;;
    *) echo "error: unsupported FAST_MERGE_PR_ROUTE=${FAST_MERGE_PR_ROUTE:-$configured}" >&2; return 2 ;;
  esac

  while IFS= read -r relative; do
    lower="$(printf '%s' "$relative" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      agents.md|*/agents.md|contributing.md|*/contributing.md|readme.md|*/readme.md|docs/*|.github/rulesets/*)
        absolute="$PROJECT_ROOT/$relative"
        grep -Eiq '(pull request|PR)[[:space:]]+(is[[:space:]]+)?(required|mandatory)|must[[:space:]]+(use|open|create)[[:space:]]+(a[[:space:]]+)?(pull request|PR)|required_pull_request' "$absolute" 2>/dev/null && return 0
        ;;
    esac
  done < <(git -C "$PROJECT_ROOT" ls-files -co --exclude-standard 2>/dev/null)
  return 1
}

PR_REQUIRED=0
pr_status=0
repo_requires_github_pr || pr_status=$?
if [ "$pr_status" -eq 0 ]; then PR_REQUIRED=1; elif [ "$pr_status" -eq 2 ]; then exit 1; fi

check_host() {
  local host="$1" missing=0
  echo "Fast Merge setup check ($host)"

  for entry in 'fast-merge:orchestrator' 'code-review:review leaf' 'diagnosing-bugs:failure leaf' 'resolving-merge-conflicts:conflict leaf'; do
    local skill="${entry%%:*}" label="${entry#*:}"
    if has_skill "$host" "$skill"; then
      printf '  skill  %-20s found (%s)\n' "$label:" "$skill"
    else
      printf '  skill  %-20s missing (%s)\n' "$label:" "$skill"
      missing=1
    fi
  done

  if command -v git >/dev/null 2>&1; then echo '  CLI    git:                 found'; else echo '  CLI    git:                 missing'; missing=1; fi
  if [ "$PR_REQUIRED" -eq 1 ]; then
    if command -v gh >/dev/null 2>&1; then echo '  CLI    gh:                  found (PR route required)'; else echo '  CLI    gh:                  missing (PR route required)'; missing=1; fi
  else
    echo '  CLI    gh:                  optional (local integration route)'
  fi

  if [ "$missing" -eq 1 ]; then
    printf '\nRepair bundled skills:\n  scripts/setup-fast-merge.sh --target %s --install-local\n' "$host"
    echo 'Repair Matt leaf skills (requires confirmation):'
    echo '  npx skills@latest add mattpocock/skills -g'
  fi
  if [ "$STRICT" -eq 1 ] && [ "$missing" -eq 1 ]; then return 1; fi
}

case "$TARGET" in
  codex|claude) check_host "$TARGET" ;;
  all)
    status=0
    check_host codex || status=1
    echo
    check_host claude || status=1
    exit "$status"
    ;;
esac
