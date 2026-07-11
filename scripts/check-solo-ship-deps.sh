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

MISSING_ANY=0
print_skill() {
  local label="$1"
  local skill="$2"

  if has_visible_skill "$skill"; then
    printf 'Skill: %-28s found (%s)\n' "$label" "$skill"
  else
    printf 'Skill: %-28s missing (%s)\n' "$label" "$skill"
    MISSING_ANY=1
  fi
}

print_cli() {
  local command_name="$1"
  local required="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'CLI:   %-28s found\n' "$command_name"
  else
    printf 'CLI:   %-28s missing\n' "$command_name"
    if [ "$required" = "required" ]; then
      MISSING_ANY=1
    fi
  fi
}

echo "Solo Ship dependency check"
if [ "$PROMPT_AVAILABLE" -eq 1 ]; then
  echo "Source: codex debug prompt-input plus filesystem fallback"
else
  echo "Source: filesystem fallback; Codex prompt-surface check unavailable"
fi
echo

print_skill "orchestrator" solo-ship
print_skill "Matt review leaf" code-review
print_skill "Matt failure leaf" diagnosing-bugs
print_skill "Matt conflict leaf" resolving-merge-conflicts

echo
print_cli git required
print_cli gh required

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

if [ "$MISSING_ANY" -eq 1 ]; then
  cat <<'GUIDE'

Repair guidance

This script is read-only and does not install external skills or tools.

Matt leaf skills:
  npx skills@latest add mattpocock/skills -g

Install Git or GitHub CLI through the host package manager when its CLI status is missing.
GUIDE
fi

if [ "$STRICT" -eq 1 ] && [ "$MISSING_ANY" -eq 1 ]; then
  exit 1
fi
