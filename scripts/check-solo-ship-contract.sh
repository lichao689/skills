#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$ROOT/skills/workflow/solo-ship/SKILL.md"
EVALUATIONS="$ROOT/tests/solo-ship-evaluations.md"
SCOPE_FENCE="$(dirname "$SKILL")/references/scope-fence.md"

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

for forbidden in github:yeet land-and-deploy finishing-a-development-branch gstack-review 'GStack `ship`' 'GitHub `yeet`'; do
  if grep -F "$forbidden" "$SKILL" >/dev/null; then
    echo "nested orchestrator remains: $forbidden" >&2
    exit 1
  fi
done

description="$(sed -n '/^---$/,/^---$/p' "$SKILL" | sed -n 's/^description:[[:space:]]*//p')"
case "$description" in
  *commit*|*push*)
    echo "frontmatter must not trigger on commit/push-only requests" >&2
    exit 1
    ;;
esac

grep -F 'sole orchestrator' "$SKILL" >/dev/null
grep -F 'Matt Leaf Skills' "$SKILL" >/dev/null
grep -F 'host or repository rules prohibit subagents' "$SKILL" >/dev/null
grep -F 'Standards axis' "$SKILL" >/dev/null
grep -F 'Spec axis' "$SKILL" >/dev/null
grep -F 'deployment: not applicable' "$SKILL" >/dev/null
grep -F 'secure host temporary directory' "$SCOPE_FENCE" >/dev/null
grep -F '0700' "$SCOPE_FENCE" >/dev/null
grep -F '0600' "$SCOPE_FENCE" >/dev/null
grep -F 'snapshot resource' "$SKILL" >/dev/null

stage_count="$(grep -Ec '^### [1-8]\. ' "$SKILL")"
[ "$stage_count" -eq 8 ] || {
  echo "expected exactly 8 ordered workflow stages, found $stage_count" >&2
  exit 1
}

completion_count="$(grep -c '^Completion:' "$SKILL")"
[ "$completion_count" -eq 8 ] || {
  echo "expected exactly 8 Completion clauses, found $completion_count" >&2
  exit 1
}

awk '
  /^### [1-8]\. / {
    if (in_stage && completions != 1) exit 1
    expected++
    if ($2 != expected ".") exit 1
    in_stage=1
    completions=0
    next
  }
  /^Completion:/ && in_stage { completions++ }
  END {
    if (expected != 8 || completions != 1) exit 1
  }
' "$SKILL" || {
  echo "each ordered stage must contain exactly one Completion clause" >&2
  exit 1
}

for run_id in /root/green_merge /root/green_dirty /root/green_orchestrator; do
  grep -F "Run identifier: \`$run_id\`" "$EVALUATIONS" >/dev/null || {
    echo "missing GREEN transcript: $run_id" >&2
    exit 1
  }
done

green_pass_count="$(grep -c '^GREEN_RESULT: PASS$' "$EVALUATIONS")"
[ "$green_pass_count" -eq 3 ] || {
  echo "expected exactly 3 GREEN_RESULT: PASS records, found $green_pass_count" >&2
  exit 1
}

set +e
grep -F 'current-skill' "$EVALUATIONS" >/dev/null
absence_status=$?
set -e
case "$absence_status" in
  0)
    echo "evaluation artifact must label the RED source as the pre-refactor skill" >&2
    exit 1
    ;;
  1) ;;
  *)
    echo "contract check failed while scanning evaluation terminology (grep exit $absence_status)" >&2
    exit 1
    ;;
esac

red_end="$(grep -nF 'Run identifier: `/root/red_orchestrator' "$EVALUATIONS" | cut -d: -f1)"
green_start="$(grep -nF '## GREEN observations' "$EVALUATIONS" | cut -d: -f1)"
[ -n "$red_end" ] && [ -n "$green_start" ] && [ "$red_end" -lt "$green_start" ] || {
  echo "complete RED E1-E3 block must precede the GREEN block" >&2
  exit 1
}

echo "solo-ship contract: ok"
