#!/usr/bin/env bash
# Shared helpers for cn-deploy-codex-security scripts. Source this file.
# shellcheck disable=SC2034

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi
if [[ -f "$ROOT/local/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/local/.env"
  set +a
fi

CODEX_SECURITY_TAG="${CODEX_SECURITY_TAG:-npm-v0.9.1}"
CODEX_SECURITY_COMMIT="${CODEX_SECURITY_COMMIT:-fe1089ab514599931ff0ce77a82dc8c4a99201ea}"
CODEX_SECURITY_NPM="${CODEX_SECURITY_NPM:-0.9.1}"
CODEX_SECURITY_DEST="${CODEX_SECURITY_DEST:-data/upstream-codex-security}"
CODEX_SECURITY_IMAGE="${CODEX_SECURITY_IMAGE:-ghcr.io/openai/codex-security:0.9.1}"
CODEX_SECURITY_IMAGE_DIGEST="${CODEX_SECURITY_IMAGE_DIGEST:-sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037}"
CODEX_SECURITY_RESULTS="${CODEX_SECURITY_RESULTS:-data/lab/results}"
CODEX_SECURITY_STATE="${CODEX_SECURITY_STATE:-data/lab/state}"
CODEX_SECURITY_CSV="${CODEX_SECURITY_CSV:-examples/repositories.csv.example}"
CODEX_SECURITY_NPM_PREFIX="${CODEX_SECURITY_NPM_PREFIX:-data/npm-prefix}"

abs_under_root() {
  local p="$1"
  if [[ "$p" = /* ]]; then
    printf '%s\n' "$p"
  else
    printf '%s\n' "$ROOT/$p"
  fi
}

upstream_dir() { abs_under_root "$CODEX_SECURITY_DEST"; }

image_ref() {
  # Digest-pinned reference for repeatable pulls.
  printf '%s\n' "ghcr.io/openai/codex-security@${CODEX_SECURITY_IMAGE_DIGEST}"
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }
