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
grep -F 'reachable from local `main`' "$SKILL" >/dev/null
grep -F 'Do not fetch or push on this default route' "$SKILL" >/dev/null
grep -F 'Explicit `push` or remote-sync intent' "$SKILL" >/dev/null
grep -F 'PR route is enabled only' "$SKILL" >/dev/null
grep -F '`deploy-local`' "$SKILL" >/dev/null
grep -F 'Remote synchronization is not a prerequisite' "$SKILL" >/dev/null
grep -F 'packaging operations and never raise validation depth' "$SKILL" >/dev/null
grep -F 'task agent:merge-local' "$(dirname "$SKILL")/references/repository-profiles/waver.md" >/dev/null
grep -F 'task agent:finish' "$(dirname "$SKILL")/references/repository-profiles/waver.md" >/dev/null
grep -F 'multi-task runtime-code integration' "$(dirname "$SKILL")/references/repository-profiles/waver.md" >/dev/null

if grep -RIE 'solo-ship|Solo Ship|goal=deploy|production deployment' "$(dirname "$SKILL")" >/dev/null; then
  echo "legacy solo-ship or automatic deployment semantics remain" >&2
  exit 1
fi

for scenario in \
  'E1 — 默认本地集成' \
  'E2 — 文档任务保持 quick' \
  'E3 — 显式 push' \
  'E4 — PR 是升级路线' \
  'E5 — 显式本机部署' \
  'E6 — 保留并行修改' \
  'E7 — strict 运行时代码'; do
  grep -F "$scenario" "$EVALUATIONS" >/dev/null || {
    echo "missing evaluation scenario: $scenario" >&2
    exit 1
  }
done

echo "fast-merge contract: ok"
