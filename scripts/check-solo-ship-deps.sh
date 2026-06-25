#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check-solo-ship-deps.sh [--strict]

Read-only dependency check for the solo-ship Codex workflow.

Options:
  --strict  Exit 1 when recommended dependency skills are missing.
  -h,--help Show this help text.
USAGE
}

STRICT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      STRICT=1
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

  if [ -d "$HOME/.codex/skills/$skill" ] || [ -d "$HOME/.agents/skills/$skill" ]; then
    return 0
  fi

  if [[ "$skill" == superpowers:* ]]; then
    local short="${skill#superpowers:}"
    find "$HOME/.codex/plugins/cache" -path "*/skills/$short/SKILL.md" -print -quit 2>/dev/null | grep . >/dev/null 2>&1
    return $?
  fi

  return 1
}

has_gstack_skill() {
  local skill="$1"

  if has_visible_skill "$skill"; then
    return 0
  fi

  if [ -d "$HOME/.codex/skills/gstack-$skill" ]; then
    return 0
  fi

  return 1
}

print_group() {
  local label="$1"
  shift
  local kind="$1"
  shift
  local found=()
  local missing=()
  local skill

  for skill in "$@"; do
    case "$kind" in
      gstack)
        if has_gstack_skill "$skill"; then
          found+=("$skill")
        else
          missing+=("$skill")
        fi
        ;;
      visible)
        if has_visible_skill "$skill"; then
          found+=("$skill")
        else
          missing+=("$skill")
        fi
        ;;
      *)
        echo "error: unsupported group kind: $kind" >&2
        exit 1
        ;;
    esac
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    echo "$label: ok"
  elif [ "${#found[@]}" -eq 0 ]; then
    echo "$label: missing"
  else
    echo "$label: partial"
  fi

  if [ "${#found[@]}" -gt 0 ]; then
    printf '  found: %s\n' "${found[*]}"
  fi

  if [ "${#missing[@]}" -gt 0 ]; then
    printf '  missing: %s\n' "${missing[*]}"
    MISSING_ANY=1
  fi
}

MISSING_ANY=0

echo "Solo Ship dependency check"
echo
if [ "$PROMPT_AVAILABLE" -eq 1 ]; then
  echo "Source: codex debug prompt-input"
else
  echo "Source: filesystem fallback; Codex prompt-surface check was unavailable"
fi
echo

print_group "solo-ship" visible \
  solo-ship

echo
print_group "GStack recommended skills" gstack \
  ship \
  review \
  health \
  land-and-deploy \
  careful \
  guard

echo
print_group "Superpowers recommended skills" visible \
  superpowers:verification-before-completion \
  superpowers:receiving-code-review \
  superpowers:systematic-debugging \
  superpowers:finishing-a-development-branch \
  superpowers:test-driven-development

echo
print_group "Matt skills recommended skills" visible \
  tdd \
  diagnosing-bugs

if [ "$MISSING_ANY" -eq 1 ]; then
  cat <<'GUIDE'

Install guidance

This script is read-only and does not install external skill packs.

GStack:
  If GStack already exists on this machine:
    cd /Users/lichao/.gstack/repos/gstack
    git pull --ff-only
    ./setup --host codex --quiet
    gstack-config set skill_prefix false

  If GStack is not installed, install or clone it first, then run its Codex setup.

Superpowers:
  Install or enable the Superpowers plugin from Codex's plugin system, restart Codex if needed,
  then rerun this check. You can inspect configured marketplaces with:
    codex plugin marketplace list
    codex plugin marketplace upgrade

Matt skills:
  Use the skills.sh installer and select the skills and agents you want:
    npx skills@latest add mattpocock/skills -g

  If Codex still cannot see selected Matt skills after installation, copy or link the selected
  skill folders from ~/.agents/skills into ~/.codex/skills, then rerun:
    codex debug prompt-input | rg "tdd|diagnosing-bugs"
GUIDE
fi

if [ "$STRICT" -eq 1 ] && [ "$MISSING_ANY" -eq 1 ]; then
  exit 1
fi
