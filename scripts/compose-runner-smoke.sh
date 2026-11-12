#!/usr/bin/env bash
# Path A smoke: pull the pinned GHCR image and run --version / --help.
# Does not perform a real scan (no API key required for these two commands).
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

if ! command -v docker >/dev/null 2>&1; then
  echo "NOT VERIFIED: Docker Engine is not installed on this host."
  echo "Install Docker 20+ with the Compose v2 plugin, then rerun:"
  echo "  ./scripts/clone-upstream.sh && ./scripts/compose-runner-smoke.sh"
  exit 2
fi
if ! docker info >/dev/null 2>&1; then
  echo "NOT VERIFIED: Docker daemon is not reachable."
  exit 2
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "NOT VERIFIED: docker compose (v2 plugin) is missing."
  exit 2
fi

UP="$(upstream_dir)"
if [[ ! -f "$UP/compose.runner.yaml" ]]; then
  echo "Upstream clone missing compose.runner.yaml. Run ./scripts/clone-upstream.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source "$ROOT/scripts/prepare-lab-dirs.sh" >/dev/null

export CODEX_SECURITY_USER="${CODEX_SECURITY_USER:-$(id -u):$(id -g)}"
export CODEX_SECURITY_IMAGE
CODEX_SECURITY_IMAGE="$(image_ref)"
export CODEX_SECURITY_RESULTS
CODEX_SECURITY_RESULTS="$(abs_under_root "$CODEX_SECURITY_RESULTS")"
export CODEX_SECURITY_STATE
CODEX_SECURITY_STATE="$(abs_under_root "$CODEX_SECURITY_STATE")"

echo "=== compose runner smoke $(date '+%Y-%m-%d %H:%M %Z') ==="
echo "image=$CODEX_SECURITY_IMAGE"
echo "user=$CODEX_SECURITY_USER"
echo "results=$CODEX_SECURITY_RESULTS"
echo "state=$CODEX_SECURITY_STATE"
echo "upstream=$UP"

cd "$UP"
echo "--- docker compose pull ---"
docker compose -f compose.runner.yaml pull
echo "--- --version ---"
docker compose -f compose.runner.yaml run --rm --no-TTY codex-security --version
echo "--- --help (first 40 lines) ---"
docker compose -f compose.runner.yaml run --rm --no-TTY codex-security --help | head -40
echo "OK: runner image answered --version/--help (no scan was performed)."
