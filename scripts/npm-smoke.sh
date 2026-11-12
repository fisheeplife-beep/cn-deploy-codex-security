#!/usr/bin/env bash
# Path B smoke: --version and --help. Does not log in or start a scan.
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

PREFIX="$(abs_under_root "$CODEX_SECURITY_NPM_PREFIX")"
BIN="$PREFIX/node_modules/.bin/codex-security"
if [[ ! -x "$BIN" ]]; then
  echo "CLI not installed. Run ./scripts/npm-install.sh first."
  exit 1
fi

echo "=== npm CLI smoke $(date '+%Y-%m-%d %H:%M %Z') ==="
echo "bin=$BIN"
echo "node=$(node --version 2>/dev/null || echo missing)"
echo "--- --version ---"
"$BIN" --version
echo "--- --help (first 40 lines) ---"
"$BIN" --help | head -40
echo "--- info --json (selected fields) ---"
"$BIN" info --json | python3 -c 'import json,sys; d=json.load(sys.stdin); keys=("sdkVersion","cliVersion","codexVersion","codexSdkVersion","bundledPluginVersion","model","reasoningEffort");
print({k:d.get(k) for k in keys})'
echo "OK: local CLI answered --version/--help/info (no scan was performed)."
echo "A real scan still needs 'cs login' or OPENAI_API_KEY / CODEX_API_KEY, and a reachable provider endpoint."
