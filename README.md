# cn-deploy-codex-security

Chinese, follow-along **deployment companion** for [openai/codex-security](https://github.com/openai/codex-security) (CLI / CI scanner with a GHCR image and Compose runner) — not an official fork, and not a verbatim copy of upstream docs or third-party translations.

**Start here (ZH):** [README.zh-CN.md](./README.zh-CN.md)

This is a **CLI/CI security scanner**, not a long-running self-hosted app. Compose `run --rm` exits when the command finishes.

### What you get

- Preflight + network / GHCR digest probes for the official **Compose runner** (path A) and **npm CLI** (path B)
- Pin-tag shallow clone (`npm-v0.9.1`) and helpers that refuse to auto-create missing bind mounts
- Notes on China npm / GHCR / OpenAI reachability, API keys vs device-auth, and `compose.yaml` accidentally building `codex-security:local`
- Honest verification boundary (author box has no Docker Engine and no OpenAI credentials)

### Verification snapshot (author box, 2026-11-12, Asia/Shanghai, Linux x86_64)

| Path | Status |
|------|--------|
| Upstream Apache-2.0 identity + pin `npm-v0.9.1` / npm `0.9.1` / GHCR digest `sha256:94796146…` | **Confirmed** |
| Network probes (GitHub / npm / npmmirror; GHCR anonymous 401; OpenAI sites 403) | **Verified** |
| GHCR index via anonymous token (`0.9.1` = `latest` = `sha-fe1089ab…`) | **Verified** |
| Shallow clone `npm-v0.9.1` | **Verified** |
| Path B: local npm install `@openai/codex-security@0.9.1` + `--version` / `--help` / `info` | **Verified** (`0.9.1`, Codex `0.167.0`) |
| Path A: Docker pull + Compose runner smoke / real scan | **Not verified** (no Docker Engine; no API key) |
| Bulk Compose campaign / GitHub Action / live OpenAI scan | **Not verified** |

Pinned baseline: source **`npm-v0.9.1`** (`fe1089ab514599931ff0ce77a82dc8c4a99201ea`), npm **`0.9.1`**, image **`ghcr.io/openai/codex-security@sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037`**. Details in `examples/`.

A newer git tag `npm-v0.10.0` existed on 2026-11-12 but had **no GitHub Release and was not on npm/GHCR**; this companion does not pin it.

### Quick start (path A intent)

```bash
./scripts/preflight.sh
./scripts/clone-upstream.sh
./scripts/probe-ghcr.sh
./scripts/compose-runner-smoke.sh   # needs Docker
```

### License

Companion scripts/docs: **MIT**. Upstream Codex Security: **Apache-2.0**.
