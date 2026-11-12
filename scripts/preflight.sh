#!/usr/bin/env bash
# Codex Security CN preflight — Compose/GHCR (path A) + npm/CLI (path B) readiness.
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

ok=0; warn=0; bad=0
say() { printf '%s\n' "$*"; }
pass() { say "✅ $*"; ok=$((ok+1)); }
warn_() { say "⚠️  $*"; warn=$((warn+1)); }
fail() { say "❌ $*"; bad=$((bad+1)); }

say "=== Codex Security CN preflight (Compose/GHCR + npm/CLI) ==="
say ""
say "Host: $(uname -s) $(uname -m)"
say "Time: $(date '+%Y-%m-%d %H:%M %Z')"
say "Pin: npm ${CODEX_SECURITY_NPM} / git ${CODEX_SECURITY_TAG} / image digest ${CODEX_SECURITY_IMAGE_DIGEST}"
say "Note: this is a CLI/CI scanner, not a long-running self-hosted service."
say ""

arch=$(uname -m)
case "$arch" in
  x86_64|amd64|aarch64|arm64) pass "CPU arch $arch (GHCR Debian image is linux/amd64 + linux/arm64)" ;;
  *) fail "Unsupported arch $arch — official GHCR Debian image is linux/amd64 and linux/arm64 only" ;;
esac

cpus=$(nproc 2>/dev/null || echo 0)
if [[ "$cpus" -ge 2 ]]; then pass "CPUs $cpus"; else warn_ "CPUs $cpus — scans can run, but Deep Scan workers prefer more cores"; fi

if [[ -r /proc/meminfo ]]; then
  avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
  avail_gib=$((avail_kb / 1024 / 1024))
  total_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
  total_gib=$((total_kb / 1024 / 1024))
  if [[ "$avail_gib" -ge 2 ]]; then
    pass "RAM available ~${avail_gib} GiB (total ~${total_gib} GiB)"
  else
    warn_ "RAM available ~${avail_gib} GiB / total ~${total_gib} GiB — leave headroom for Docker + Node"
  fi
fi

if df -Pk . >/dev/null 2>&1; then
  avail_kb=$(df -Pk . | awk 'NR==2{print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [[ "$avail_gb" -ge 8 ]]; then pass "Disk free ~${avail_gb} GB"; else warn_ "Disk free ~${avail_gb} GB — GHCR image + npm prefix need several GB"; fi
fi

for t in git curl jq; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t present"; else fail "$t missing"; fi
done

if command -v python3 >/dev/null 2>&1; then
  pyver=$(python3 --version 2>&1)
  # Upstream asks Python 3.10+ (3.10 also needs tomli).
  if python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)'; then
    pass "python3: $pyver (≥3.10)"
  else
    warn_ "python3: $pyver — upstream CLI asks 3.10+"
  fi
else
  warn_ "python3 missing — needed by the official CLI/SDK runtime"
fi

if command -v node >/dev/null 2>&1; then
  nodever=$(node --version 2>/dev/null || echo unknown)
  if node -e 'const m=+process.versions.node.split(".")[0]; const min=process.versions.node.split(".").map(Number); const ok=(m===22 && min[1]>=13)||m===24||m===26; process.exit(ok?0:1)'; then
    pass "node: $nodever (engines: ^22.13 || ^24 || ^26)"
  else
    warn_ "node: $nodever — path B needs Node ^22.13.0 || ^24 || ^26 (20/23/25 are not in engines)"
  fi
else
  warn_ "node missing — required for path B (npm/CLI); path A uses the image instead"
fi

if command -v npm >/dev/null 2>&1; then
  pass "npm: $(npm --version 2>/dev/null)"
else
  warn_ "npm missing — required for path B"
fi

if command -v docker >/dev/null 2>&1; then
  pass "docker: $(docker --version 2>/dev/null | head -1)"
  if docker info >/dev/null 2>&1; then pass "docker daemon reachable"; else fail "docker daemon not reachable — path A cannot pull/run"; fi
  if docker compose version >/dev/null 2>&1; then
    pass "docker compose: $(docker compose version 2>/dev/null | head -1)"
  else
    fail "docker compose plugin missing — path A needs Compose v2 for compose.runner.yaml"
  fi
else
  fail "Docker Engine missing — path A (GHCR / Compose runner) needs Docker 20+ with Compose v2"
fi

if [[ -n "${OPENAI_API_KEY:-}${CODEX_API_KEY:-}" ]]; then
  warn_ "An API key is present in the environment (value hidden). Do not commit it. Full scans still need a reachable OpenAI/Codex endpoint."
else
  warn_ "No OPENAI_API_KEY / CODEX_API_KEY in this shell — --help/--version work without it; real scans need login or a key"
fi

say ""
say "--- network (best-effort) ---"
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 12 -L -A "cn-deploy-codex-security-preflight/0.1" "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then pass "Reachable: $name (HTTP $code)"; else warn_ "Unreachable/slow: $name ($url → HTTP $code)"; fi
}
probe "GitHub openai/codex-security" "https://github.com/openai/codex-security"
probe "GitHub release npm-v0.9.1" "https://github.com/openai/codex-security/releases/tag/npm-v0.9.1"
probe "npm registry 0.9.1" "https://registry.npmjs.org/@openai/codex-security"
probe "npmmirror 0.9.1" "https://registry.npmmirror.com/@openai/codex-security"
probe "GHCR manifests (anon, 401 expected)" "https://ghcr.io/v2/openai/codex-security/manifests/0.9.1"
probe "api.openai.com" "https://api.openai.com/v1/models"
probe "developers.openai.com docs" "https://developers.openai.com/codex/security"

say ""
say "=== summary: ${ok} ok / ${warn} warn / ${bad} bad ==="
say "Path A needs Docker Compose + GHCR pull + a login or API key for a real scan."
say "Path B needs Node engines above + npm + the same credentials."
say "HTTP 401 on GHCR without a bearer token is normal; use ./scripts/probe-ghcr.sh to complete the anonymous token exchange."
[[ "$bad" -gt 0 ]] && exit 1
exit 0
