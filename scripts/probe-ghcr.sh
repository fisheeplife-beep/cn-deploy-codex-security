#!/usr/bin/env bash
# Probe the public GHCR OCI index for the pinned Codex Security image (no Docker required).
set -euo pipefail
# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
need_cmd python3

python3 - "$CODEX_SECURITY_NPM" "$CODEX_SECURITY_COMMIT" "$CODEX_SECURITY_IMAGE_DIGEST" <<'PY'
import json, sys, urllib.request, datetime

version, commit, expect_digest = sys.argv[1], sys.argv[2], sys.argv[3]
repo = "openai/codex-security"
tags = [version, "latest", f"sha-{commit}", f"{version}-wolfi-amd64"]
lines = [f"=== GHCR probe {datetime.datetime.now().astimezone().strftime('%Y-%m-%d %H:%M %Z')} ==="]
ok = True

def token():
    url = f"https://ghcr.io/token?service=ghcr.io&scope=repository:{repo}:pull"
    with urllib.request.urlopen(url, timeout=30) as r:
        return json.load(r)["token"]

def probe(tag):
    global ok
    tok = token()
    req = urllib.request.Request(
        f"https://ghcr.io/v2/{repo}/manifests/{tag}",
        headers={
            "Authorization": f"Bearer {tok}",
            "Accept": "application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            body = r.read()
            digest = r.headers.get("Docker-Content-Digest") or r.headers.get("ETag", "").strip('"')
            media = r.headers.get("Content-Type", "")
            status = r.status
    except Exception as e:
        lines.append(f"FAIL ghcr.io/{repo}:{tag} {e}")
        ok = False
        return
    idx = json.loads(body)
    plats = []
    for m in idx.get("manifests") or []:
        p = m.get("platform") or {}
        if p.get("os") and p.get("os") != "unknown":
            plats.append(f"{p.get('os')}/{p.get('architecture')}")
    ann = idx.get("annotations") or {}
    ver = ann.get("org.opencontainers.image.version", "")
    rev = ann.get("org.opencontainers.image.revision", "")
    match = "DIGEST_MATCH" if digest == expect_digest else "DIGEST_DIFF"
    lines.append(
        f"OK ghcr.io/{repo}:{tag} HTTP {status} digest={digest} {match} media={media.split(';',1)[0]} plats={','.join(plats) or 'n/a'} version={ver} revision={rev[:12]}"
    )
    if tag in (version, "latest", f"sha-{commit}") and digest != expect_digest:
        # latest may move after a newer Debian release; record it but do not
        # fail the probe for latest alone.
        if tag != "latest":
            ok = False
            lines.append(f"ERROR pinned tag {tag} digest differs from expected {expect_digest}")
        else:
            lines.append(f"NOTE :latest digest differs from the pinned 0.9.1 digest {expect_digest} — do not deploy floating latest")

for t in tags:
    probe(t)

lines.append(f"expected_pin_digest={expect_digest}")
lines.append("Use CODEX_SECURITY_IMAGE=ghcr.io/openai/codex-security@" + expect_digest + " for a repeatable pull.")
lines.append("unknown/unknown index entries are SBOM/provenance, not runnable platforms.")
lines.append("NOTE: the *-wolfi-amd64 tag is a different (amd64-only) image; DIGEST_DIFF vs the Debian multi-arch index is expected.")
text = "\n".join(lines) + "\n"
sys.stdout.write(text)
sys.exit(0 if ok else 1)
PY
