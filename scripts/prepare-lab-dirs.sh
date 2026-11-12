#!/usr/bin/env bash
# Create Compose bind-mount directories. Upstream sets create_host_path: false,
# so a missing host path fails the run instead of auto-creating it.
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"

RESULTS="$(abs_under_root "$CODEX_SECURITY_RESULTS")"
STATE="$(abs_under_root "$CODEX_SECURITY_STATE")"
mkdir -p "$RESULTS" "$STATE"
chmod 700 "$RESULTS" "$STATE"
echo "results=$RESULTS"
echo "state=$STATE"
echo "NOTE: state/ can hold login credentials after device-auth or login --with-api-key."
echo "Keep it private; do not copy it into a git worktree you will push."
