#!/usr/bin/env bash
# analyze-workflow.sh — produce a workflow-signals JSON envelope for the
# skill-gate recommender. Reads only files in $PWD. Public dep names and
# framework markers only — never paths, never source bodies, never
# private-looking names.

set -euo pipefail

CWD="$(pwd)"

# ---------- helpers ----------
has() { [[ -e "$1" ]]; }
has_any() { for p in "$@"; do [[ -e "$p" ]] && return 0; done; return 1; }
read_pkg_field() {
  # node-friendly: read a top-level field from package.json without jq
  local field="$1"
  [[ -f package.json ]] || return 1
  python3 -c "
import json, sys
try:
  d = json.load(open('package.json'))
  v = d.get('${field}', {})
  if isinstance(v, dict):
    print('\n'.join(v.keys()))
  elif isinstance(v, list):
    print('\n'.join(map(str, v)))
  else:
    print(v)
except Exception:
  sys.exit(0)
" 2>/dev/null || true
}

# Strip names that look private (scoped to your org). Heuristic: anything
# scoped that isn't a well-known public scope.
PUBLIC_SCOPES="@anthropic-ai|@aws-sdk|@azure|@babel|@types|@typescript-eslint|@vercel|@next|@nestjs|@redis|@radix-ui|@sentry|@shopify|@slack|@stripe|@supabase|@tanstack|@trpc|@vitest|@vue"
public_only() {
  awk -v re="^(${PUBLIC_SCOPES})" '
    /^@/ {
      if ($0 ~ re) print
      next
    }
    { print }
  '
}

# ---------- language detection ----------
detect_lang() {
  local lang=""
  has package.json && lang="node"
  if [[ -z "$lang" ]]; then
    has_any pyproject.toml setup.py requirements.txt Pipfile poetry.lock && lang="python"
  fi
  if [[ -z "$lang" ]]; then
    has go.mod && lang="go"
  fi
  if [[ -z "$lang" ]]; then
    has Cargo.toml && lang="rust"
  fi
  if [[ -z "$lang" ]]; then
    has_any pom.xml build.gradle build.gradle.kts && lang="java"
  fi
  if [[ -z "$lang" ]]; then
    has Gemfile && lang="ruby"
  fi
  if [[ -z "$lang" ]]; then
    has_any composer.json && lang="php"
  fi
  echo "$lang"
}

detect_secondary_langs() {
  local out=()
  has Dockerfile && out+=("docker")
  has_any *.tf terraform.tf && out+=("terraform")
  has_any *.tsx tsconfig.json && out+=("typescript")
  has_any *.sql && out+=("sql")
  has_any *.sh scripts/*.sh && out+=("shell")
  if [[ ${#out[@]} -gt 0 ]]; then
    ( IFS=,; echo "${out[*]}" )
  else
    echo ""
  fi
}

# ---------- framework detection ----------
detect_frameworks() {
  local fws=()
  # node
  if [[ -f package.json ]]; then
    local deps; deps="$(read_pkg_field dependencies; read_pkg_field devDependencies)"
    for f in next nuxt remix astro express fastify koa nest svelte vue react vite tailwindcss prisma drizzle-orm mongoose typeorm; do
      printf '%s\n' "$deps" | grep -qE "^${f}\b" && fws+=("$f")
    done
  fi
  # python
  for f in fastapi flask django starlette pyramid sanic uvicorn pydantic sqlalchemy alembic celery; do
    if [[ -f requirements.txt ]] && grep -qiE "^${f}\b" requirements.txt; then fws+=("$f"); fi
    if [[ -f pyproject.toml ]] && grep -qiE "${f}[^a-z]" pyproject.toml; then fws+=("$f"); fi
  done
  # go
  if [[ -f go.mod ]]; then
    for f in gin fiber chi echo cobra gorm; do grep -qiE "/${f}\b" go.mod && fws+=("$f"); done
  fi
  # ruby
  [[ -f Gemfile ]] && grep -qE "^gem ['\"]rails['\"]" Gemfile 2>/dev/null && fws+=("rails")
  # java
  if has pom.xml; then grep -qE 'spring-boot' pom.xml && fws+=("spring-boot"); fi
  if [[ ${#fws[@]} -gt 0 ]]; then
    ( IFS=,; echo "${fws[*]}" )
  else
    echo ""
  fi
}

# ---------- public deps (top 20) ----------
detect_deps() {
  if [[ -f package.json ]]; then
    { read_pkg_field dependencies; read_pkg_field devDependencies; } \
      | grep -v '^$' | public_only | head -n 20
  elif [[ -f requirements.txt ]]; then
    awk -F'[<>=]' '{print $1}' requirements.txt | grep -v '^$' | head -n 20
  elif [[ -f pyproject.toml ]]; then
    grep -E '^\s*[a-z0-9._-]+\s*=' pyproject.toml | awk -F'=' '{gsub(/[ "]/,"",$1); print $1}' | head -n 20
  elif [[ -f go.mod ]]; then
    grep -E '^[[:space:]]+[a-zA-Z0-9./_-]+ v' go.mod | awk '{print $1}' | head -n 20
  elif [[ -f Cargo.toml ]]; then
    awk -F'=' '/^\[dependencies\]/{f=1;next} /^\[/{f=0} f && /=/ {gsub(/[ "]/,"",$1); print $1}' Cargo.toml | head -n 20
  fi
}

# ---------- signals (project shape) ----------
signal_has_ci()      { has_any .github/workflows .gitlab-ci.yml circle.yml .circleci/config.yml; }
signal_has_docker()  { has_any Dockerfile docker-compose.yml docker-compose.yaml; }
signal_has_tests()   { has_any tests test __tests__ spec; }
signal_has_db_migr() { has_any prisma/migrations migrations db/migrate alembic; }
signal_deploys_to() {
  has fly.toml && echo "fly" && return
  has vercel.json && echo "vercel" && return
  has netlify.toml && echo "netlify" && return
  has render.yaml && echo "render" && return
  has app.yaml && echo "gcp" && return
  has_any .github/workflows/deploy*.yml && echo "github-actions" && return
  echo ""
}
repo_size_kloc() {
  # crude line-count of source files (top 5 languages); fast and conservative
  find . -type f \
    \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
      -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \
      -o -name '*.rb' -o -name '*.php' \) \
    -not -path './node_modules/*' -not -path './.next/*' -not -path './dist/*' \
    -not -path './build/*' -not -path './target/*' -not -path './.venv/*' \
    -not -path './vendor/*' 2>/dev/null \
    | head -n 5000 \
    | xargs wc -l 2>/dev/null \
    | tail -n 1 \
    | awk '{printf "%.1f", $1/1000}'
}

# ---------- behavior (recent prompts → verbs/nouns) ----------
# Best effort: scan ~/.claude.json (if it exists, JSON) for the last 50
# user prompts and emit a small bag-of-words. The recommender uses these
# as soft signals. Skip silently if not available or opted-out.
detect_behavior() {
  if [[ "${SKILL_GATE_NO_BEHAVIOR:-0}" == "1" ]]; then return; fi
  local f="${HOME}/.claude.json"
  [[ -f "$f" ]] || return
  python3 - "$f" <<'PY' 2>/dev/null || true
import json, sys, re, collections
try:
  d = json.load(open(sys.argv[1]))
except Exception:
  sys.exit(0)
# heuristic: collect last 50 user-message strings under any "history" / "messages" arrays
def walk(o, out):
  if isinstance(o, dict):
    for k, v in o.items():
      if k in ("content", "text", "prompt") and isinstance(v, str): out.append(v)
      else: walk(v, out)
  elif isinstance(o, list):
    for v in o: walk(v, out)
buf = []
walk(d, buf)
buf = buf[-50:]
STOP = set("the a an and or but if then for of to in on at as is be it i you we my your this that with".split())
words = collections.Counter()
for line in buf:
  for w in re.findall(r"[a-z][a-z0-9-]{3,20}", line.lower()):
    if w in STOP: continue
    words[w] += 1
top = [w for w, _ in words.most_common(20)]
print(",".join(top))
PY
}

# ---------- emit ----------
LANG="$(detect_lang)"
SEC_LANGS="$(detect_secondary_langs)"
FWS="$(detect_frameworks)"
DEPS_RAW="$(detect_deps || true)"
DEPLOY="$(signal_deploys_to)"
KLOC="$(repo_size_kloc 2>/dev/null || echo 0)"
BEHAVIOR="$(detect_behavior || true)"

# JSON-encode arrays from comma/newline-separated values
to_json_arr() {
  python3 -c "
import sys, json
items = [x.strip() for x in sys.stdin.read().replace(',', '\n').splitlines() if x.strip()]
print(json.dumps(items))
"
}

DEPS_JSON="$(printf '%s\n' "$DEPS_RAW" | to_json_arr)"
SEC_JSON="$(printf '%s\n' "$SEC_LANGS" | to_json_arr)"
FWS_JSON="$(printf '%s\n' "$FWS" | to_json_arr)"
BEHAVIOR_JSON="$(printf '%s\n' "$BEHAVIOR" | to_json_arr)"

# Bool signals: pass as "1"/"0" env vars so Python sees real ints, not the
# literal shell words `true`/`false` (which are not valid Python literals).
SG_HAS_CI="0";      signal_has_ci      && SG_HAS_CI="1"
SG_HAS_DOCKER="0";  signal_has_docker  && SG_HAS_DOCKER="1"
SG_HAS_TESTS="0";   signal_has_tests   && SG_HAS_TESTS="1"
SG_HAS_MIGR="0";    signal_has_db_migr && SG_HAS_MIGR="1"
CWD_BASE="$(basename "${CWD}")"

LANG="$LANG" SEC_JSON="$SEC_JSON" FWS_JSON="$FWS_JSON" DEPS_JSON="$DEPS_JSON" \
BEHAVIOR_JSON="$BEHAVIOR_JSON" DEPLOY="$DEPLOY" KLOC="${KLOC:-0}" \
SG_HAS_CI="$SG_HAS_CI" SG_HAS_DOCKER="$SG_HAS_DOCKER" \
SG_HAS_TESTS="$SG_HAS_TESTS" SG_HAS_MIGR="$SG_HAS_MIGR" CWD_BASE="$CWD_BASE" \
python3 <<'PY'
import json, os
def to_bool(s): return s == "1"
def to_arr(s):
  try: return json.loads(s) if s else []
  except: return []
lang = os.environ.get("LANG", "")
print(json.dumps({
  "language": lang or None,
  "secondary_languages": to_arr(os.environ.get("SEC_JSON","[]")),
  "frameworks":          to_arr(os.environ.get("FWS_JSON","[]")),
  "deps":                to_arr(os.environ.get("DEPS_JSON","[]")),
  "signals": {
    "has_ci":            to_bool(os.environ.get("SG_HAS_CI","0")),
    "has_docker":        to_bool(os.environ.get("SG_HAS_DOCKER","0")),
    "has_tests":         to_bool(os.environ.get("SG_HAS_TESTS","0")),
    "has_db_migrations": to_bool(os.environ.get("SG_HAS_MIGR","0")),
    "deploys_to":        os.environ.get("DEPLOY",""),
    "repo_size_kloc":    float(os.environ.get("KLOC","0") or 0),
  },
  "behavior":     to_arr(os.environ.get("BEHAVIOR_JSON","[]")),
  "cwd_basename": os.environ.get("CWD_BASE",""),
}, indent=2))
PY
