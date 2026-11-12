#!/usr/bin/env bash
# Best-effort HTTP probes (no Docker, no API key required).
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
say() { printf '%s\n' "$*"; }
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 -L -A "cn-deploy-codex-security-probe/0.1" "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  say "$name	HTTP $code	$url"
}
say "=== Codex Security network probe $(date '+%Y-%m-%d %H:%M %Z') ==="
probe "GitHub repo" "https://github.com/openai/codex-security"
probe "GitHub release npm-v0.9.1" "https://github.com/openai/codex-security/releases/tag/npm-v0.9.1"
probe "GitHub docker README raw" "https://raw.githubusercontent.com/openai/codex-security/npm-v0.9.1/docker/README.md"
probe "npm registry" "https://registry.npmjs.org/@openai/codex-security"
probe "npm tarball 0.9.1" "https://registry.npmjs.org/@openai/codex-security/-/codex-security-0.9.1.tgz"
probe "npmmirror" "https://registry.npmmirror.com/@openai/codex-security"
probe "GHCR v2 (anon)" "https://ghcr.io/v2/openai/codex-security/manifests/0.9.1"
probe "api.openai.com /v1/models" "https://api.openai.com/v1/models"
probe "chatgpt.com" "https://chatgpt.com"
probe "developers.openai.com" "https://developers.openai.com/codex/security"
probe "learn.chatgpt.com CLI docs" "https://learn.chatgpt.com/docs/security/cli"
say "Notes:"
say "- GHCR /v2 without a bearer token commonly returns HTTP 401; use ./scripts/probe-ghcr.sh."
say "- Official OpenAI / ChatGPT sites may return 403 (bot or regional policy). A 403 here is not a scan success."
say "- Yangshun translation repo (for contrast, not a dependency):"
probe "yangshun2005/codex-security-cn" "https://github.com/yangshun2005/codex-security-cn"
