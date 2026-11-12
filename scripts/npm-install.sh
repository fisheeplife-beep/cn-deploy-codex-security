#!/usr/bin/env bash
# Path B: install the pinned npm package into a local prefix (not a global install).
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_cmd npm
need_cmd node

if ! node -e 'const m=+process.versions.node.split(".")[0]; const min=process.versions.node.split(".").map(Number); const ok=(m===22 && min[1]>=13)||m===24||m===26; process.exit(ok?0:1)'; then
  die "Node $(node --version) is outside engines ^22.13.0 || ^24 || ^26"
fi

PREFIX="$(abs_under_root "$CODEX_SECURITY_NPM_PREFIX")"
mkdir -p "$PREFIX"
PKG="@openai/codex-security@${CODEX_SECURITY_NPM}"
echo "Installing $PKG into $PREFIX (Node $(node --version), npm $(npm --version))"
echo "This also pulls @openai/codex and may take several minutes on a slow npm mirror."
npm install --prefix "$PREFIX" --no-fund --no-audit "$PKG"
echo "OK. Binaries:"
ls -l "$PREFIX/node_modules/.bin/codex-security" "$PREFIX/node_modules/.bin/cs"
echo "Next: ./scripts/npm-smoke.sh"
