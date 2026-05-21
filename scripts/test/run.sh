#!/usr/bin/env bash
# Self-test for skill-gate scripts. Runs analyze-workflow.sh against a set of
# fixture projects and asserts the JSON envelope matches expectations.
#
# Run:
#   bash scripts/test/run.sh        # all fixtures
#   bash scripts/test/run.sh node   # just one
#
# Exit 0 on success. Each fixture lives at scripts/test/fixtures/<name>/.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${HERE}/../.." && pwd)"
ANALYZE="${SKILL_ROOT}/scripts/analyze-workflow.sh"

FIXTURES_DIR="${HERE}/fixtures"
PASS=0
FAIL=0
ONLY="${1:-}"

assert_contains() {
  # $1 = json, $2 = field, $3 = expected substring
  local json="$1" field="$2" expected="$3"
  local actual
  actual="$(printf '%s' "$json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
v=d.get('${field}')
if isinstance(v,list):
  print(','.join(map(str,v)))
elif isinstance(v,dict):
  print(json.dumps(v))
else:
  print(v if v is not None else '')
")"
  if [[ "$actual" == *"$expected"* ]]; then
    return 0
  fi
  echo "  FAIL: ${field} expected to contain '${expected}', got '${actual}'"
  return 1
}

run_fixture() {
  local name="$1"; shift
  local fixture_dir="${FIXTURES_DIR}/${name}"
  if [[ ! -d "$fixture_dir" ]]; then
    echo "MISSING: ${name} fixture at ${fixture_dir}"
    FAIL=$((FAIL+1)); return
  fi
  echo "=== ${name} ==="
  local out
  out="$(cd "$fixture_dir" && SKILL_GATE_NO_BEHAVIOR=1 "$ANALYZE")"
  # validate JSON shape
  if ! printf '%s' "$out" | python3 -m json.tool >/dev/null 2>&1; then
    echo "  FAIL: output is not valid JSON"
    printf '%s\n' "$out" | head -20
    FAIL=$((FAIL+1)); return
  fi
  local ok=1
  for assertion in "$@"; do
    IFS='=' read -r field expected <<< "$assertion"
    if ! assert_contains "$out" "$field" "$expected"; then
      ok=0
    fi
  done
  if (( ok == 1 )); then
    echo "  PASS"
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
  fi
}

# ---- runs ----
if [[ -z "$ONLY" || "$ONLY" == "node" ]]; then
  run_fixture node \
    "language=node" \
    "frameworks=next" \
    "deps=react"
fi

if [[ -z "$ONLY" || "$ONLY" == "python" ]]; then
  run_fixture python \
    "language=python" \
    "frameworks=fastapi"
fi

if [[ -z "$ONLY" || "$ONLY" == "go" ]]; then
  run_fixture go \
    "language=go"
fi

if [[ -z "$ONLY" || "$ONLY" == "docker" ]]; then
  run_fixture docker \
    "secondary_languages=docker"
fi

echo
echo "PASS=${PASS} FAIL=${FAIL}"
[[ "${FAIL}" -eq 0 ]]
