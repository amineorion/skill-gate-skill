#!/usr/bin/env bash
# install-skill.sh <skill_id> [install_url]
#
# Installs an accepted skill into ~/.claude/skills/<skill_id>/. Idempotent:
# if already installed, refuses to overwrite unless --force is passed.
#
# If <install_url> is omitted, fetches it from the marketplace
# (GET /v1/skills/<id>).
#
# Logs the install anonymously via POST /v1/install/log (best-effort).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SH="${HERE}/skill-gate-api.sh"

usage() {
  cat <<EOF
usage: install-skill.sh <skill_id> [install_url] [--force]

Examples:
  install-skill.sh design-review
  install-skill.sh design-review https://github.com/owner/repo
  install-skill.sh design-review --force
EOF
}

err() { printf '%s\n' "$*" >&2; }

FORCE=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) ARGS+=("$a") ;;
  esac
done

SKILL_ID="${ARGS[0]:-}"
INSTALL_URL="${ARGS[1]:-}"

if [[ -z "${SKILL_ID}" ]]; then
  usage
  exit 2
fi

SKILLS_DIR="${HOME}/.claude/skills"
TARGET="${SKILLS_DIR}/${SKILL_ID}"

mkdir -p "${SKILLS_DIR}"

if [[ -d "${TARGET}" && "${FORCE}" -ne 1 ]]; then
  err "[skill-gate] ${SKILL_ID} already installed at ${TARGET}. pass --force to re-install."
  exit 0
fi

# Resolve install URL via the API if not provided
if [[ -z "${INSTALL_URL}" ]]; then
  resp="$("${API_SH}" get "/v1/skills/${SKILL_ID}" || true)"
  INSTALL_URL="$(printf '%s' "${resp}" | sed -n 's/.*"install_url":"\([^"]*\)".*/\1/p')"
  if [[ -z "${INSTALL_URL}" ]]; then
    err "[skill-gate] could not resolve install_url for ${SKILL_ID}. Response:"
    err "${resp}"
    exit 1
  fi
fi

# Sanity: only allow https git URLs from github / gitlab / sr.ht / codeberg
case "${INSTALL_URL}" in
  https://github.com/*|https://gitlab.com/*|https://git.sr.ht/*|https://codeberg.org/*) ;;
  *)
    err "[skill-gate] refusing install from non-canonical URL: ${INSTALL_URL}"
    err "[skill-gate] only github/gitlab/sourcehut/codeberg are accepted. submit yours for review."
    exit 1
    ;;
esac

# Clone (or, on --force, replace)
if [[ -d "${TARGET}" && "${FORCE}" -eq 1 ]]; then
  rm -rf "${TARGET}"
fi

err "[skill-gate] git clone ${INSTALL_URL} → ${TARGET}"
git clone --depth 1 "${INSTALL_URL}" "${TARGET}" 1>&2

# Verify it actually contains a SKILL.md
if [[ ! -f "${TARGET}/SKILL.md" ]]; then
  err "[skill-gate] cloned ${SKILL_ID} but no SKILL.md found. left in place at ${TARGET}."
  err "[skill-gate] flag this skill for re-review via skill-gate-api.sh post /v1/install/log with status=missing_skill_md"
fi

# Log the install (best-effort, never fatal)
"${API_SH}" post /v1/install/log "{\"skill_id\":\"${SKILL_ID}\",\"status\":\"installed\"}" >/dev/null 2>&1 || true

echo "installed → ${TARGET}"
