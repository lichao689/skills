#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/setup-solo-ship.sh [--target codex|claude|all] [--install-local] [--strict]

Checks and optionally installs this repository's local skills for the solo-ship workflow.
External skill packs and Codex plugins are never installed by this script.

Options:
  --target        Host surface to check. Default: codex.
  --install-local Install this repo's bundled skills into the selected host(s) before checking.
  --strict        Exit 1 when a phase has neither a visible skill nor an acceptable CLI fallback.
  -h,--help       Show this help text.
USAGE
}

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="codex"
INSTALL_LOCAL=0
STRICT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --install-local)
      INSTALL_LOCAL=1
      shift
      ;;
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

short_skill_name() {
  local skill="$1"
  echo "${skill#*:}"
}

has_codex_skill() {
  local skill="$1"
  local short
  short="$(short_skill_name "$skill")"

  if [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ] && grep -F -- "- $skill:" "$CODEX_PROMPT" >/dev/null 2>&1; then
    return 0
  fi

  if [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ] && [ "$skill" != "$short" ] && grep -F -- "- $short:" "$CODEX_PROMPT" >/dev/null 2>&1; then
    return 0
  fi

  if [ -d "$HOME/.codex/skills/$skill" ] || [ -d "$HOME/.codex/skills/$short" ]; then
    return 0
  fi

  case "$skill" in
    github:*)
      find "$HOME/.codex/plugins/cache" -path "*/github/*/skills/$short/SKILL.md" -print -quit 2>/dev/null | grep . >/dev/null 2>&1
      return $?
      ;;
    superpowers:*)
      find "$HOME/.codex/plugins/cache" -path "*/superpowers/*/skills/$short/SKILL.md" -print -quit 2>/dev/null | grep . >/dev/null 2>&1
      return $?
      ;;
  esac

  return 1
}

has_claude_skill() {
  local skill="$1"
  local short
  short="$(short_skill_name "$skill")"

  if [ -d "$HOME/.claude/skills/$skill" ] || [ -d "$HOME/.claude/skills/$short" ]; then
    return 0
  fi

  if [ -d "$HOME/.agents/skills/$skill" ] || [ -d "$HOME/.agents/skills/$short" ]; then
    return 0
  fi

  return 1
}

has_skill() {
  local host="$1"
  local skill="$2"

  case "$host" in
    codex) has_codex_skill "$skill" ;;
    claude) has_claude_skill "$skill" ;;
    *)
      return 1
      ;;
  esac
}

check_stage() {
  local host="$1"
  local label="$2"
  local fallback="$3"
  shift 3
  local found=()
  local missing=()
  local skill

  for skill in "$@"; do
    if has_skill "$host" "$skill"; then
      found+=("$skill")
    else
      missing+=("$skill")
    fi
  done

  if [ "${#found[@]}" -gt 0 ]; then
    printf '  ok       %-18s %s\n' "$label:" "${found[*]}"
    return 0
  fi

  if [ -n "$fallback" ]; then
    printf '  fallback %-18s %s; missing: %s\n' "$label:" "$fallback" "${missing[*]}"
    return 0
  fi

  printf '  missing  %-18s %s\n' "$label:" "${missing[*]}"
  MISSING_ANY=1
  return 0
}

check_host() {
  local host="$1"
  MISSING_ANY=0

  echo "Solo Ship setup check ($host)"
  case "$host" in
    codex)
      if [ "$CODEX_PROMPT_AVAILABLE" -eq 1 ]; then
        echo "Source: codex debug prompt-input plus filesystem/plugin cache fallback"
      else
        echo "Source: filesystem/plugin cache fallback; Codex prompt-surface check unavailable"
      fi
      ;;
    claude)
      echo "Source: ~/.claude/skills and ~/.agents/skills filesystem check"
      ;;
  esac
  echo

  check_stage "$host" "orchestrator" "" solo-ship
  check_stage "$host" "review" "" review gstack-review
  check_stage "$host" "fix" "" superpowers:receiving-code-review receiving-code-review
  check_stage "$host" "debug" "" superpowers:systematic-debugging systematic-debugging diagnose
  check_stage "$host" "tdd" "" tdd superpowers:test-driven-development test-driven-development
  check_stage "$host" "verify" "" superpowers:verification-before-completion verification-before-completion health
  check_stage "$host" "commit/push" "manual git + gh workflow" github:yeet yeet
  check_stage "$host" "pr-review" "gh CLI manual PR inspection" github:github github github:gh-address-comments gh-address-comments
  check_stage "$host" "ci-fix" "gh CLI checks/logs workflow" github:gh-fix-ci gh-fix-ci
  check_stage "$host" "merge" "" ship
  check_stage "$host" "deploy-merge" "manual post-merge verification" land-and-deploy
  check_stage "$host" "docs" "manual changelog note" document-release changelog
  check_stage "$host" "cleanup" "" superpowers:finishing-a-development-branch finishing-a-development-branch careful guard

  echo
  if command -v gh >/dev/null 2>&1; then
    echo "CLI: gh found ($(gh --version | sed -n '1p'))"
    if gh auth status >/dev/null 2>&1; then
      echo "CLI: gh auth ok"
    else
      echo "CLI: gh auth not confirmed; run: gh auth status"
    fi
  else
    echo "CLI: gh missing; install GitHub CLI for manual GitHub fallbacks"
  fi

  if [ "$host" = "codex" ]; then
    if find "$HOME/.codex/plugins/cache" -path "*/github/*/skills/yeet/SKILL.md" -print -quit 2>/dev/null | grep . >/dev/null 2>&1; then
      echo "Plugin: Codex GitHub skills cache found"
    else
      echo "Plugin: Codex GitHub skills cache not found; enable the GitHub plugin in Codex"
    fi

    if find "$HOME/.codex/plugins/cache" -path "*/superpowers/*/skills/verification-before-completion/SKILL.md" -print -quit 2>/dev/null | grep . >/dev/null 2>&1; then
      echo "Plugin: Codex Superpowers skills cache found"
    else
      echo "Plugin: Codex Superpowers skills cache not found; enable the Superpowers plugin in Codex"
    fi
  fi

  if [ "$MISSING_ANY" -eq 1 ]; then
    cat <<'GUIDE'

Repair guidance

Local skills from this repo:
  scripts/setup-solo-ship.sh --target codex --install-local
  scripts/setup-solo-ship.sh --target claude --install-local

GStack skills:
  cd /Users/lichao/.gstack/repos/gstack
  git pull --ff-only
  ./setup --host codex --quiet
  ./setup --host claude --quiet
  gstack-config set skill_prefix false

Superpowers:
  Enable the Superpowers plugin in Codex, or install/link the matching skills for Claude.

GitHub publish/review helpers:
  In Codex, enable the GitHub plugin. In Claude, install equivalent skills if available,
  otherwise solo-ship should fall back to explicit git and gh CLI steps.

Matt skills:
  npx skills@latest add mattpocock/skills -g
  Then link or copy selected skills into the host skill directory if they are not visible.
GUIDE
  fi

  if [ "$STRICT" -eq 1 ] && [ "$MISSING_ANY" -eq 1 ]; then
    return 1
  fi
}

case "$TARGET" in
  codex|claude)
    check_host "$TARGET"
    ;;
  all)
    check_host codex
    echo
    check_host claude
    ;;
esac
