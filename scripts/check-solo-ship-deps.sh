#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check-solo-ship-deps.sh [--strict]

Read-only dependency and tool-capability check for the solo-ship Codex workflow.

Options:
  --strict  Apply the strict Codex-host requirements from setup-solo-ship.sh.
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

args=(--target codex)
if [ "$STRICT" -eq 1 ]; then
  args+=(--strict)
fi

exec "$(cd "$(dirname "$0")" && pwd)/setup-solo-ship.sh" "${args[@]}"
