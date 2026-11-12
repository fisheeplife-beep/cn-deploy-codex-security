#!/usr/bin/env bash
# Prepare host paths and print the official bulk-scan Compose command.
# Does not start a scan (that would need a real repositories.csv + credentials).
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

UP="$(upstream_dir)"
if [[ ! -f "$UP/compose.yaml" ]]; then
  echo "Upstream clone missing compose.yaml. Run ./scripts/clone-upstream.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source "$ROOT/scripts/prepare-lab-dirs.sh"

CSV_SRC="$(abs_under_root "$CODEX_SECURITY_CSV")"
CSV_DEST="$(abs_under_root "data/lab/repositories.csv")"
if [[ ! -f "$CSV_DEST" ]]; then
  cp "$CSV_SRC" "$CSV_DEST"
  echo "copied example CSV → $CSV_DEST"
  echo "WARNING: the example row uses a placeholder repo/revision. Edit it before a real bulk-scan."
else
  echo "CSV already present: $CSV_DEST (left unchanged)"
fi

USER="${CODEX_SECURITY_USER:-$(id -u):$(id -g)}"
IMAGE="$(image_ref)"
RESULTS="$(abs_under_root "$CODEX_SECURITY_RESULTS")"
STATE="$(abs_under_root "$CODEX_SECURITY_STATE")"

echo ""
echo "IMPORTANT: compose.yaml defaults to image codex-security:local and will try to BUILD"
echo "unless you set CODEX_SECURITY_IMAGE to the published GHCR digest."
echo ""
echo "From $UP, after editing $CSV_DEST:"
cat <<CMD
export CODEX_SECURITY_USER='$USER'
export CODEX_SECURITY_IMAGE='$IMAGE'
export CODEX_SECURITY_RESULTS='$RESULTS'
export CODEX_SECURITY_STATE='$STATE'
export CODEX_SECURITY_CSV='$CSV_DEST'
# For unattended runs, also export OPENAI_API_KEY or CODEX_API_KEY (not printed here).
cd '$UP'
docker compose pull
# Optional login (device-auth must be allowed on the workspace):
# docker compose run --rm codex-security login --device-auth
docker compose run --rm codex-security
CMD
echo ""
echo "On Ubuntu hosts that block nested user namespaces, install the AppArmor profile"
echo "from upstream docker/codex-security.apparmor and add -f compose.apparmor.yaml."
