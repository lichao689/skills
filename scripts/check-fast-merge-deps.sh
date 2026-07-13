#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check-fast-merge-deps.sh [--strict]

Read-only dependency and Git-capability check for fast-merge.
USAGE
}

args=(--target codex)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict) args+=(--strict); shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

exec "$(cd "$(dirname "$0")" && pwd)/setup-fast-merge.sh" "${args[@]}"
