#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check-solo-ship-deps.sh [--strict]

Read-only dependency and tool-capability check for the solo-ship Codex workflow.

Options:
  --strict  Exit 1 when solo-ship, a Matt leaf skill, Git, or GitHub CLI is missing.
  -h,--help Show this help text.
USAGE
}

STRICT=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

PROMPT_FILE="$(mktemp)"
trap 'rm -f "$PROMPT_FILE"' EXIT

PROMPT_AVAILABLE=0
if command -v codex >/dev/null 2>&1 && codex debug prompt-input >"$PROMPT_FILE" 2>/dev/null; then
  PROMPT_AVAILABLE=1
fi

has_visible_skill() {
  local skill="$1"

  if [ "$PROMPT_AVAILABLE" -eq 1 ] && grep -F -- "- $skill:" "$PROMPT_FILE" >/dev/null 2>&1; then
    return 0
  fi

  [ -d "$HOME/.codex/skills/$skill" ] || [ -d "$HOME/.agents/skills/$skill" ]
}

MISSING_LOCAL=0
MISSING_MATT=0
MISSING_GIT=0
MISSING_GH=0
print_skill() {
  local label="$1"
  local skill="$2"
  local kind="$3"

  if has_visible_skill "$skill"; then
    printf 'Skill: %-28s found (%s)\n' "$label" "$skill"
  else
    printf 'Skill: %-28s missing (%s)\n' "$label" "$skill"
    if [ "$kind" = "local" ]; then
      MISSING_LOCAL=1
    else
      MISSING_MATT=1
    fi
  fi
}

print_cli() {
  local command_name="$1"

  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'CLI:   %-28s found\n' "$command_name"
  else
    printf 'CLI:   %-28s missing\n' "$command_name"
    case "$command_name" in
      git) MISSING_GIT=1 ;;
      gh) MISSING_GH=1 ;;
    esac
  fi
}

echo "Solo Ship dependency check"
if [ "$PROMPT_AVAILABLE" -eq 1 ]; then
  echo "Source: codex debug prompt-input plus filesystem fallback"
else
  echo "Source: filesystem fallback; Codex prompt-surface check unavailable"
fi
echo

print_skill "orchestrator" solo-ship local
print_skill "Matt review leaf" code-review matt
print_skill "Matt failure leaf" diagnosing-bugs matt
print_skill "Matt conflict leaf" resolving-merge-conflicts matt

echo
print_cli git
print_cli gh

if [ -f package.json ] || [ -f pyproject.toml ] || [ -f Makefile ] || [ -d tests ]; then
  echo "Repo:  test entry points             detected"
else
  echo "Repo:  test entry points             not detected"
fi

if [ -d .github/workflows ]; then
  echo "Repo:  CI configuration              detected"
else
  echo "Repo:  CI configuration              not detected"
fi

if find . -maxdepth 3 -type f \( -iname '*deploy*' -o -iname 'Dockerfile' -o -iname 'compose.yml' -o -iname 'docker-compose.yml' \) -print -quit 2>/dev/null | grep . >/dev/null 2>&1; then
  echo "Repo:  deployment entry points       detected"
else
  echo "Repo:  deployment entry points       not detected"
fi

if [ "$MISSING_LOCAL" -eq 1 ] || [ "$MISSING_MATT" -eq 1 ] || [ "$MISSING_GIT" -eq 1 ] || [ "$MISSING_GH" -eq 1 ]; then
  printf '\nRepair guidance\n'
fi

if [ "$MISSING_LOCAL" -eq 1 ]; then
  cat <<'GUIDE'

Local solo-ship skill:
  scripts/setup-solo-ship.sh --target codex --install-local
GUIDE
fi

if [ "$MISSING_MATT" -eq 1 ]; then
  cat <<'GUIDE'
Matt leaf skills:
  npx skills@latest add mattpocock/skills -g
GUIDE
fi

if [ "$MISSING_GIT" -eq 1 ]; then
  cat <<'GUIDE'
Git CLI:
  Install Git with the host package manager, then rerun: scripts/check-solo-ship-deps.sh
GUIDE
fi

if [ "$MISSING_GH" -eq 1 ]; then
  cat <<'GUIDE'
GitHub CLI:
  Install GitHub CLI with the host package manager, then rerun: scripts/check-solo-ship-deps.sh
GUIDE
fi

if [ "$STRICT" -eq 1 ] && { [ "$MISSING_LOCAL" -eq 1 ] || [ "$MISSING_MATT" -eq 1 ] || [ "$MISSING_GIT" -eq 1 ] || [ "$MISSING_GH" -eq 1 ]; }; then
  exit 1
fi
