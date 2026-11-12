# Codex Security 国内可跟做部署配套

> 上游仓库：[openai/codex-security](https://github.com/openai/codex-security)（**Apache-2.0**）  
> 产品页：[developers.openai.com/codex/security](https://developers.openai.com/codex/security)  
> 容器说明：[`docker/README.md` @ npm-v0.9.1](https://github.com/openai/codex-security/blob/npm-v0.9.1/docker/README.md)  
> npm：[`@openai/codex-security@0.9.1`](https://www.npmjs.com/package/@openai/codex-security/v/0.9.1)（与 Release [`npm-v0.9.1`](https://github.com/openai/codex-security/releases/tag/npm-v0.9.1) 对齐）  
> GHCR：`ghcr.io/openai/codex-security`（本仓钉 digest **`sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037`**）  
> 本仓性质：**独立中文部署配套**（预检 / 钉 tag 浅克隆 / GHCR 探针 / Compose 与 npm 脚本 / 国内网络与密钥踩坑），**不是**官方镜像或 fork，也**不会**整页搬运上游 README 或他人译文。

Codex Security 是用 Codex 工作流 **查找、核验、修复代码漏洞** 的 **CLI / CI 扫描器**（另有 TypeScript SDK 与 GitHub Action）。它**不是**常驻的自托管 Web 应用：Compose 用法是 `docker compose run --rm`，命令结束容器即退出，默认不暴露服务端口。

系列索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)

---

## 验证边界（请先看）

| 路径 | 本仓作者环境验证状态（2026-11-12，Asia/Shanghai，Linux x86_64） |
|------|----------------------------------------------------------------|
| **上游身份 / 许可证** | ✅ **已确认** — `openai/codex-security` Apache-2.0；钉源码 **`npm-v0.9.1`**（`fe1089ab5145`）；npm **`0.9.1`**；GHCR 多架构索引 digest **`sha256:94796146…`**（与 `:0.9.1` / `:latest` / `sha-fe1089ab…` 一致） |
| **文档 / GitHub / npm / npmmirror HTTP** | ✅ **已验证** — 见 [`examples/network-probe.txt`](./examples/network-probe.txt) |
| **GHCR 匿名 token 读索引** | ✅ **已验证** — 见 [`examples/ghcr-probe.txt`](./examples/ghcr-probe.txt) |
| **浅克隆钉 tag** | ✅ **已验证** — 见 [`examples/clone-upstream.txt`](./examples/clone-upstream.txt) |
| **路径 B：本地 npm 安装 + `--version` / `--help` / `info`** | ✅ **已验证** — `@openai/codex-security@0.9.1`（附带 `@openai/codex@0.167.0`），见 [`examples/npm-cli-smoke.txt`](./examples/npm-cli-smoke.txt) |
| **路径 A：Docker pull + Compose runner 冒烟** | ⚠️ **未验证** — 作者机 **无 Docker Engine**。脚本已写好，待有 Docker 的机器回填 [`examples/compose-runner-smoke.txt`](./examples/compose-runner-smoke.txt) |
| **真实扫描 / bulk-scan / GitHub Action** | ⚠️ **未验证** — 无 OpenAI / Codex 凭证，且作者环境访问 `api.openai.com` 返回 403 |
| **`npm-v0.10.0`** | ⚠️ **不钉** — 2026-11-12 已有 git tag，但尚无 GitHub Release，也未出现在 npm / GHCR |

摘要：[`examples/verification-boundary.txt`](./examples/verification-boundary.txt) · 主机快照：[`examples/host-snapshot.txt`](./examples/host-snapshot.txt)

---

## 相对官方英文文档和已有中文翻译仓，本仓多写什么？

官方 [README](https://github.com/openai/codex-security/blob/npm-v0.9.1/README.md) 与 [docker/README.md](https://github.com/openai/codex-security/blob/npm-v0.9.1/docker/README.md) 已经把 Compose、镜像校验和登录写得很完整。另有一份 1 星翻译仓 [yangshun2005/codex-security-cn](https://github.com/yangshun2005/codex-security-cn)（**2026-08-19** 译了当时的 README，不是实测部署教程，命令和模型名已过时）。**请去上游看功能说明**；本仓刻意错位，补跟做时国内更容易踩、而译文不会提醒的点：

1. **钉已发布的 `0.9.1` + 多架构 digest**，并写明当天出现但尚未发布的 `npm-v0.10.0` tag 不要当生产钉；  
2. **`compose.runner.yaml`（主推）vs `compose.yaml`（bulk）**：后者默认镜像是 `codex-security:local` 会触发本地 build；  
3. **bind mount**：`create_host_path: false` 必须先建 `results/` / `state/` / CSV；`CODEX_SECURITY_USER="$(id -u):$(id -g)"` 避免 uid `10001` 把目录写死；  
4. **国内网络**：npm 官方源 / GHCR token 交换 / `api.openai.com` 与文档站 403，以及「镜像拉下来仍扫不动」；  
5. **密钥与登录**：环境变量 vs `login --with-api-key` vs device-auth，state 目录不可提交；  
6. **诚实验证边界**（作者机无 Docker、无 API Key 则标未验证）。

本仓**不整页翻译**上游或该翻译仓。需要 CLI 全量选项时请打开钉 tag 的英文文档。

---

## 选哪条路？

| 场景 | 推荐 |
|------|------|
| **有 Docker，想用官方镜像跑单次 CLI** | **路径 A：GHCR + `compose.runner.yaml`**（主推） |
| **要对一份 CSV 做多仓库可恢复扫描** | 路径 A 的 bulk：`compose.yaml` + 自备 CSV（先读差异表） |
| **本机已有受支持的 Node，先装 CLI** | **路径 B：npm 本地前缀安装** |
| **仓库已在 GitHub，想跟官方 Action 跑周扫** | 可选路径 C：钉 [`action-v0.9.1`](https://github.com/openai/codex-security/releases/tag/action-v0.9.1)，密钥放 Actions Secret |
| **只测网络 / 拉源码 / 核对 digest** | `./scripts/probe-network.sh` / `./scripts/probe-ghcr.sh` / `./scripts/clone-upstream.sh` |

**主推：路径 A。** 这仍是一次性扫描命令，不是部署一个 7×24 的安全平台。

---

## 环境要求（路径 A）

| 项 | 建议 |
|----|------|
| OS | Linux / macOS / Windows + Docker（Linux 上沙箱 / Bubblewrap 最接近上游设计） |
| 资源 | ≥2 CPU、建议 ≥4 GiB RAM、≥8 GiB 磁盘余量 |
| 软件 | Docker 20+（**Compose v2**）、git、curl、jq |
| 出网 | GitHub、GHCR、以及扫描时的 OpenAI（或你改用的官方支持 provider）；见 [`docs/china-network.md`](./docs/china-network.md) |
| 身份 | ChatGPT 登录（含可选 device-auth）或 `OPENAI_API_KEY` / `CODEX_API_KEY` |

路径 B 另需 **Node 22.13+（22.x）、24.x 或 26.x** 与 Python 3.10+（官方要求；3.10 还需 `tomli`）。Node 20 / 23 / 25 不在 engines 里。

```bash
git clone https://github.com/fisheeplife-beep/cn-deploy-codex-security.git
cd cn-deploy-codex-security
./scripts/preflight.sh
```

---

## 路径 A｜GHCR + Compose runner（本仓主推）

```bash
./scripts/clone-upstream.sh          # 默认 CODEX_SECURITY_TAG=npm-v0.9.1
./scripts/probe-ghcr.sh              # 无 Docker 也可核对 digest
./scripts/compose-runner-smoke.sh    # 需要 Docker：pull + --version / --help
```

真实扫描、bind mount、seccomp / AppArmor、bulk 与「切勿误用 compose.yaml 默认本地 build」见 [`docs/docker-compose.md`](./docs/docker-compose.md)。密钥见 [`docs/auth-and-keys.md`](./docs/auth-and-keys.md)。Lab 环境变量模板：[`local/.env.example`](./local/.env.example)（**勿提交真密钥**）。

批量扫描可先 `./scripts/compose-bulk-prepare.sh`（会复制占位 CSV 并打印命令；**先改仓库地址和 40 位 revision** 再跑）。

---

## 路径 B｜本机 npm / CLI

```bash
./scripts/npm-install.sh    # 安装到 data/npm-prefix，避免全局 cs 短名冲突
./scripts/npm-smoke.sh      # --version / --help
# 然后（不要把 key 写在命令行参数里）：
# data/npm-prefix/node_modules/.bin/codex-security login
# data/npm-prefix/node_modules/.bin/codex-security scan /path/to/repo
```

也可用 `npx @openai/codex-security@0.9.1`。短名 `cs` 若与其他命令冲突，一律用 `codex-security`。

---

## 国内网络 / 排障

- [`docs/china-network.md`](./docs/china-network.md) — npm 镜像、GHCR digest、OpenAI 出口、save/load  
- [`docs/troubleshooting.md`](./docs/troubleshooting.md)

---

## 安全注意

1. **不要提交 API Key、ChatGPT 登录态、`GH_TOKEN`。** 只用 `local/.env`（已在 `.gitignore`）。  
2. `data/lab/state` 与 `results/.codex-security-state` 在登录后等同密钥目录，权限 `700`，不要放进要推送的 Git 树。  
3. 扫描报告含漏洞与源码片段，输出目录同样按敏感数据处理。  
4. 上游 Apache-2.0；本配套脚本与文档 **MIT**，不重新授权上游代码、镜像或 npm 包。  
5. 本仓不提供绕过地区限制或未授权扫描他人仓库的方法。只扫你有权检测的代码。

---

## 开源边界

- 行为以 [openai/codex-security](https://github.com/openai/codex-security) 钉 tag `npm-v0.9.1` 的文档为准。  
- 商标与产品名归各自权利人；本仓仅为社区跟做笔记。  
- **未向上游开 Issue / Discussion**：OpenAI 仓库空贴「又一份中文配套」容易变成 spam。有 Compose 全栈或真实扫描日志后再考虑用 Discussion 回馈英文复现信息。

---

## 系列

- 索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)  
- 体检：[cn-deploy-doctor](https://github.com/fisheeplife-beep/cn-deploy-doctor)  
- 选题：[trending-gap-radar](https://github.com/fisheeplife-beep/trending-gap-radar)  
- 同系列：[cn-deploy-ruview](https://github.com/fisheeplife-beep/cn-deploy-ruview) · [cn-deploy-nvke](https://github.com/fisheeplife-beep/cn-deploy-nvke) · [cn-deploy-n8n](https://github.com/fisheeplife-beep/cn-deploy-n8n) · [cn-deploy-openclaw](https://github.com/fisheeplife-beep/cn-deploy-openclaw) · [cn-deploy-firecrawl](https://github.com/fisheeplife-beep/cn-deploy-firecrawl)
