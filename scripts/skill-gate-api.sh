#!/usr/bin/env bash
# skill-gate-api.sh — talk to the skill-gate marketplace API.
# Bootstraps a device token on first call. Token + AES key live at
# ~/.skill-gate/{token,key} (mode 0600). Best-effort: if the API is
# unreachable, the calling skill should fall back gracefully.

set -euo pipefail

API_URL="${SKILL_GATE_API:-https://api.skill-gate.dev}"
API_URL="${API_URL%/}"
CONFIG_DIR="${HOME}/.skill-gate"
TOKEN_FILE="${CONFIG_DIR}/token"
KEY_FILE="${CONFIG_DIR}/key"

mkdir -p "${CONFIG_DIR}"
chmod 700 "${CONFIG_DIR}" 2>/dev/null || true

usage() {
  cat <<EOF
usage: skill-gate-api.sh <verb> <path> [body]

verbs:
  get   <path>              GET <path>
  post  <path> [@file|-|json]   POST <path> with body
  ping                      check the API is reachable
  whoami                    print device id

env:
  SKILL_GATE_API   override the API base URL (default: https://api.skill-gate.dev)
EOF
}

err() { printf '%s\n' "$*" >&2; }

ensure_token() {
  if [[ -s "${TOKEN_FILE}" ]]; then
    return 0
  fi
  err "[skill-gate] no device token; bootstrapping…"
  local fp
  # device fingerprint = hostname + first 16 bytes of /etc/machine-id or a random uuid
  fp="$(hostname 2>/dev/null || echo unknown)"
  if [[ -r /etc/machine-id ]]; then
    fp="${fp}.$(head -c 16 /etc/machine-id 2>/dev/null || true)"
  else
    fp="${fp}.$(uuidgen 2>/dev/null | tr -d '-' | head -c 16 || date +%s%N)"
  fi
  local resp
  resp="$(curl -sS -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"fingerprint\":\"${fp}\",\"client\":\"skill-gate-skill\"}" \
    "${API_URL}/v1/auth/device" || true)"
  if [[ -z "${resp}" ]]; then
    err "[skill-gate] auth/device unreachable. set SKILL_GATE_API or check connectivity."
    return 1
  fi
  local tok key
  tok="$(printf '%s' "${resp}" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')"
  key="$(printf '%s' "${resp}" | sed -n 's/.*"encryptionKey":"\([^"]*\)".*/\1/p')"
  if [[ -z "${tok}" ]]; then
    err "[skill-gate] auth/device response missing token: ${resp}"
    return 1
  fi
  umask 077
  printf '%s' "${tok}" > "${TOKEN_FILE}"
  [[ -n "${key}" ]] && printf '%s' "${key}" > "${KEY_FILE}"
  chmod 600 "${TOKEN_FILE}" "${KEY_FILE}" 2>/dev/null || true
  err "[skill-gate] device registered."
}

body_data() {
  # Accept @file, "-" (stdin), or a raw json/string. Echoes the resolved body.
  local b="$1"
  if [[ -z "${b:-}" ]]; then
    printf ''
    return 0
  fi
  if [[ "${b}" == "@"* ]]; then
    cat "${b:1}"
    return 0
  fi
  if [[ "${b}" == "-" ]]; then
    cat
    return 0
  fi
  printf '%s' "${b}"
}

cmd="${1:-}"
case "${cmd}" in
  ping)
    curl -sS -o /dev/null -w '%{http_code}\n' "${API_URL}/health"
    ;;
  whoami)
    if [[ -s "${TOKEN_FILE}" ]]; then
      printf 'device-token: %s…%s\n' \
        "$(head -c 6 "${TOKEN_FILE}")" "$(tail -c 4 "${TOKEN_FILE}")"
    else
      printf 'no token yet — call any API to bootstrap.\n'
    fi
    ;;
  get)
    path="${2:?path required}"
    ensure_token
    curl -sS -H "Authorization: Bearer $(cat "${TOKEN_FILE}")" \
      -H 'Accept: application/json' \
      "${API_URL}${path}"
    ;;
  post)
    path="${2:?path required}"
    body="$(body_data "${3:-}")"
    ensure_token
    curl -sS -X POST \
      -H "Authorization: Bearer $(cat "${TOKEN_FILE}")" \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -d "${body}" \
      "${API_URL}${path}"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    err "unknown verb: ${cmd}"
    usage
    exit 2
    ;;
esac
