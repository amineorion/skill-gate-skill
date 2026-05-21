#!/usr/bin/env bash
# submit-skill.sh — community submission for the marketplace.
#
# Modes:
#   submit <repo_url> [domain]          # submit your skill for AI + admin review
#   request "free-text description"     # request a missing skill (community backlog)
#
# Both call POST /v1/submissions on the marketplace API.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SH="${HERE}/skill-gate-api.sh"

usage() {
  cat <<EOF
usage:
  submit-skill.sh submit  <repo_url> [domain]
  submit-skill.sh request "<one-sentence description of the missing skill>"

Examples:
  submit-skill.sh submit https://github.com/you/your-skill frontend
  submit-skill.sh request "a skill that converts our product spec into a launch tweet thread"
EOF
}

err() { printf '%s\n' "$*" >&2; }
json_escape() {
  python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$1"
}

cmd="${1:-}"
case "${cmd}" in
  submit)
    repo="${2:?repo url required}"
    domain="${3:-}"
    case "${repo}" in
      https://github.com/*|https://gitlab.com/*|https://git.sr.ht/*|https://codeberg.org/*) ;;
      *)
        err "[skill-gate] only github/gitlab/sourcehut/codeberg URLs are accepted."
        exit 1
        ;;
    esac
    body="$(python3 - <<PY
import json
print(json.dumps({"kind":"submit","repo":"${repo}","domain":"${domain}"}))
PY
)"
    "${API_SH}" post /v1/submissions "${body}"
    echo
    err "[skill-gate] submitted. you'll see it appear in the marketplace once an admin accepts."
    ;;
  request)
    desc="${2:?description required}"
    body="$(python3 - <<PY
import json
print(json.dumps({"kind":"request","pitch":"${desc//\"/\\\"}"}))
PY
)"
    "${API_SH}" post /v1/submissions "${body}"
    echo
    err "[skill-gate] request queued. requests with multiple upvotes get prioritized for the official catalogue."
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    err "unknown subcommand: ${cmd}"
    usage
    exit 2
    ;;
esac
