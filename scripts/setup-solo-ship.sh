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
  --strict        Exit 1 when solo-ship, a Matt leaf skill, Git, or route-required GitHub CLI is missing.
  -h,--help       Show this help text.
USAGE
}

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"
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
    MISSING_GIT=1
  fi
}

list_repo_files() {
  if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$PROJECT_ROOT" ls-files -co --exclude-standard
    return
  fi

  local candidate
  for candidate in \
    "$PROJECT_ROOT"/* \
    "$PROJECT_ROOT"/.github/workflows/* \
    "$PROJECT_ROOT"/docs/* \
    "$PROJECT_ROOT"/scripts/*; do
    [ -f "$candidate" ] || continue
    printf '%s\n' "${candidate#"$PROJECT_ROOT"/}"
  done
}

selected_push_remote() {
  command -v git >/dev/null 2>&1 || return 1
  local branch remote
  branch="$(git -C "$PROJECT_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  remote=""
  if [ -n "$branch" ]; then
    remote="$(git -C "$PROJECT_ROOT" config --get "branch.$branch.pushRemote" 2>/dev/null || true)"
  fi
  [ -n "$remote" ] || remote="$(git -C "$PROJECT_ROOT" config --get remote.pushDefault 2>/dev/null || true)"
  if [ -z "$remote" ] && [ -n "$branch" ]; then
    remote="$(git -C "$PROJECT_ROOT" config --get "branch.$branch.remote" 2>/dev/null || true)"
  fi
  if [ -z "$remote" ] && git -C "$PROJECT_ROOT" remote get-url origin >/dev/null 2>&1; then
    remote=origin
  fi
  [ -n "$remote" ] && [ "$remote" != "." ] || return 1
  printf '%s\n' "$remote"
}

selected_remote_is_github() {
  [ -n "$SELECTED_PUSH_REMOTE" ] || return 1
  git -C "$PROJECT_ROOT" remote get-url --push "$SELECTED_PUSH_REMOTE" 2>/dev/null |
    grep -Eiq '(^|[/:.@-])github([.-]|\.com|$)'
}

policy_requires_github_pr() {
  local configured relative lower absolute
  configured="$(git -C "$PROJECT_ROOT" config --get solo-ship.prRoute 2>/dev/null || true)"
  [ "$configured" = "github-pr" ] && return 0

  while IFS= read -r relative; do
    lower="$(printf '%s' "$relative" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      agents.md|*/agents.md|contributing.md|*/contributing.md|readme.md|*/readme.md|docs/*|.github/rulesets/*)
        absolute="$PROJECT_ROOT/$relative"
        grep -Eiq '(pull request|PR)[[:space:]]+(is[[:space:]]+)?(required|mandatory)|must[[:space:]]+(use|open|create)[[:space:]]+(a[[:space:]]+)?(pull request|PR)|required_pull_request' "$absolute" 2>/dev/null && return 0
        ;;
    esac
  done <"$REPO_FILES"
  return 1
}

github_pr_route_evidenced() {
  case "${SOLO_SHIP_PR_ROUTE:-auto}" in
    github-pr) return 0 ;;
    direct|none) return 1 ;;
    auto|'') ;;
    *)
      echo "error: unsupported SOLO_SHIP_PR_ROUTE=${SOLO_SHIP_PR_ROUTE}" >&2
      return 2
      ;;
  esac

  policy_requires_github_pr && return 0
  if command -v gh >/dev/null 2>&1 &&
    git -C "$PROJECT_ROOT" symbolic-ref --quiet HEAD >/dev/null 2>&1 &&
    (cd "$PROJECT_ROOT" && GH_PAGER=cat gh pr view --json number >/dev/null 2>&1); then
    return 0
  fi
  return 1
}

deployment_detected() {
  local relative lower absolute
  while IFS= read -r relative; do
    [ -n "$relative" ] || continue
    lower="$(printf '%s' "$relative" | tr '[:upper:]' '[:lower:]')"
    absolute="$PROJECT_ROOT/$relative"

    case "$lower" in
      *deploy*|*release*|dockerfile|*/dockerfile|compose.yml|*/compose.yml|docker-compose.yml|*/docker-compose.yml|fly.toml|*/fly.toml|vercel.json|*/vercel.json|netlify.toml|*/netlify.toml|render.yaml|*/render.yaml|railway.json|*/railway.json|procfile|*/procfile)
        return 0
        ;;
    esac

    case "$lower" in
      .github/workflows/*)
        grep -Eiq '(^|[^[:alnum:]_])(deploy|release|publish)([^[:alnum:]_]|$)|environment:|workflow_dispatch:' "$absolute" 2>/dev/null && return 0
        ;;
      package.json|*/package.json|pyproject.toml|*/pyproject.toml|makefile|*/makefile)
        grep -Eiq '(^|["[:space:]])(deploy|release|publish)(["=:[:space:]]|$)' "$absolute" 2>/dev/null && return 0
        ;;
      readme|readme.*|*/readme|*/readme.*|docs/*)
        grep -Eiq '(^|[[:space:]#])(deployment|deploy|release|publish)([[:space:]:#`]|$)' "$absolute" 2>/dev/null && return 0
        ;;
    esac
  done <"$REPO_FILES"
  return 1
}

print_repo_tools() {
  if [ -f "$PROJECT_ROOT/package.json" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/Makefile" ] || [ -d "$PROJECT_ROOT/tests" ]; then
    echo "  repo   test entry points:       detected"
  else
    echo "  repo   test entry points:       not detected by heuristic"
  fi

  if grep -Eq '^(\.github/workflows/|\.gitlab-ci\.yml$|azure-pipelines\.yml$|\.circleci/)' "$REPO_FILES"; then
    echo "  repo   CI configuration:        detected"
  else
    echo "  repo   CI configuration:        not detected by heuristic"
  fi

  if deployment_detected; then
    echo "  repo   deployment entry points: detected"
  else
    echo "  repo   deployment entry points: not detected by heuristic"
    echo "  note   heuristic absence is not proof that deployment is not applicable"
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
  if command -v gh >/dev/null 2>&1; then
    printf '  CLI    %-24s found\n' "gh:"
  elif [ "$GITHUB_PR_ROUTE_REQUIRED" -eq 1 ]; then
    printf '  CLI    %-24s missing (required by GitHub remote/PR route)\n' "gh:"
    MISSING_GH=1
  else
    printf '  CLI    %-24s unavailable capability (selected route does not require GitHub PR)\n' "gh:"
  fi
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

REPO_FILES="$TMP_DIR/repo-files.txt"
list_repo_files >"$REPO_FILES"
SELECTED_PUSH_REMOTE="$(selected_push_remote || true)"
GITHUB_PR_ROUTE_REQUIRED=0
if selected_remote_is_github; then
  pr_evidence_status=0
  github_pr_route_evidenced || pr_evidence_status=$?
  if [ "$pr_evidence_status" -eq 0 ]; then
    GITHUB_PR_ROUTE_REQUIRED=1
  elif [ "$pr_evidence_status" -eq 2 ]; then
    exit 1
  fi
fi

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
