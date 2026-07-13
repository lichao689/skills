#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/skills/workflow/fast-merge/SKILL.md"
EVALUATIONS="$ROOT/tests/fast-merge-evaluations.md"

required_files=(
  references/risk-levels.md
  references/scope-fence.md
  references/evidence-policy.md
  references/git-topology-and-cleanup.md
  references/repository-profiles/waver.md
  agents/openai.yaml
)

test -f "$SKILL" || {
  echo "missing fast-merge skill" >&2
  exit 1
}

for relative in "${required_files[@]}"; do
  test -f "$(dirname "$SKILL")/$relative" || {
    echo "missing fast-merge resource: $relative" >&2
    exit 1
  }
done

grep -F 'name: fast-merge' "$SKILL" >/dev/null
grep -F 'local-first Fast Merge' "$SKILL" >/dev/null
grep -F 'remote integration branch' "$SKILL" >/dev/null
grep -F 'PR route is an escalation' "$SKILL" >/dev/null
grep -F '`deploy-local`' "$SKILL" >/dev/null
grep -F 'current host' "$SKILL" >/dev/null
grep -F 'task agent:finish' "$(dirname "$SKILL")/references/repository-profiles/waver.md" >/dev/null

if grep -RIE 'solo-ship|Solo Ship|goal=deploy|production deployment' "$(dirname "$SKILL")" >/dev/null; then
  echo "legacy solo-ship or automatic deployment semantics remain" >&2
  exit 1
fi

stage_count="$(grep -Ec '^### [1-5]\. ' "$SKILL")"
[ "$stage_count" -eq 5 ] || {
  echo "expected exactly 5 ordered stages, found $stage_count" >&2
  exit 1
}

completion_count="$(grep -c '^Completion:' "$SKILL")"
[ "$completion_count" -eq 5 ] || {
  echo "expected exactly 5 Completion clauses, found $completion_count" >&2
  exit 1
}

for scenario in \
  'E1 — 默认本地集成' \
  'E2 — PR 是升级路线' \
  'E3 — 显式本机部署' \
  'E4 — 保留并行修改'; do
  grep -F "$scenario" "$EVALUATIONS" >/dev/null || {
    echo "missing evaluation scenario: $scenario" >&2
    exit 1
  }
done

echo "fast-merge contract: ok"
