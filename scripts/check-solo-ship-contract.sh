#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/skills/workflow/solo-ship/SKILL.md"

required_files=(
  references/risk-levels.md
  references/scope-fence.md
  references/evidence-policy.md
  references/git-topology-and-cleanup.md
  references/repository-profiles/waver.md
)

for relative in "${required_files[@]}"; do
  test -f "$(dirname "$SKILL")/$relative" || {
    echo "missing solo-ship reference: $relative" >&2
    exit 1
  }
done

for required in code-review diagnosing-bugs resolving-merge-conflicts; do
  grep -F "$required" "$SKILL" >/dev/null || {
    echo "missing Matt leaf skill: $required" >&2
    exit 1
  }
done

for forbidden in github:yeet land-and-deploy finishing-a-development-branch gstack-review; do
  if grep -F "$forbidden" "$SKILL" >/dev/null; then
    echo "nested orchestrator remains: $forbidden" >&2
    exit 1
  fi
done

grep -F 'Deploy' "$SKILL" >/dev/null
grep -F 'Post-deploy verify' "$SKILL" >/dev/null
grep -F 'deployment: not applicable' "$SKILL" >/dev/null

echo "solo-ship contract: ok"
