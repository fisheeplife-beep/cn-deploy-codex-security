#!/usr/bin/env bash
# Shallow clone openai/codex-security at the pinned release tag.
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_cmd git

TAG="$CODEX_SECURITY_TAG"
DEST="$(upstream_dir)"
mkdir -p "$(dirname "$DEST")"

if [[ -d "$DEST/.git" ]]; then
  echo "Already cloned: $DEST"
  git -C "$DEST" fetch --depth 1 origin "refs/tags/${TAG}:refs/tags/${TAG}" 2>/dev/null || \
    git -C "$DEST" fetch --depth 1 origin "refs/tags/${TAG}" || true
  git -C "$DEST" checkout -q "tags/${TAG}" 2>/dev/null || git -C "$DEST" checkout -q "$TAG" || true
else
  git -c advice.detachedHead=false clone --depth 1 --branch "$TAG" https://github.com/openai/codex-security.git "$DEST"
fi

echo "OK $TAG → $DEST"
git -C "$DEST" describe --tags --always
HEAD=$(git -C "$DEST" rev-parse HEAD)
echo "$HEAD"
if [[ "$HEAD" != "$CODEX_SECURITY_COMMIT" ]]; then
  echo "WARNING: HEAD $HEAD does not match pinned commit $CODEX_SECURITY_COMMIT" >&2
  exit 2
fi
