# 国内网络说明（Codex Security）

这是 CLI / CI 扫描器，不是常驻服务。你要通的不只是「把镜像拉下来」，还有 **运行扫描时访问的模型端点**。

## 你需要通的几条链路

| 用途 | 地址 | 国内常见情况 |
|------|------|----------------|
| 源码 / Release / tag | `github.com/openai/codex-security` | clone 常慢；可用代理。本仓 `./scripts/clone-upstream.sh` 只浅克隆钉 tag |
| 官方英文文档 | `developers.openai.com/codex/security`、`learn.chatgpt.com/docs/security/cli` | 可能被拦截或返回 403（CDN/风控）。以 [上游仓库文档](https://github.com/openai/codex-security/blob/npm-v0.9.1/README.md) 为准最稳 |
| npm 包 | `registry.npmjs.org/@openai/codex-security` | 官方源偶发慢或超时。可用 `registry.npmmirror.com` 等镜像（**镜像会失效，本仓不绑死一家**） |
| 容器镜像 | `ghcr.io/openai/codex-security` | GHCR 匿名拉取要先换 token（`./scripts/probe-ghcr.sh` 已封装）。国内常慢或失败，见下方策略 |
| ChatGPT 登录 / device-auth | `chatgpt.com` 及相关认证域 | 工作区若关闭 device auth，容器里 `login --device-auth` 会失败，改用 API Key |
| 扫描推理 | `api.openai.com`（默认）或其他已配置的 provider | **这是国内最常见的硬门槛**。拉得下镜像不等于扫得动。需合规可达的出网路径，或改用上游支持的其他 provider（Bedrock / OpenRouter / Fireworks / Cheaper Inference，见官方 CLI 文档） |
| 私有仓库检出（可选） | `github.com` + `GH_TOKEN` / `GITHUB_TOKEN` | 仅当 CSV / scan 目标是私有仓时需要 |
| GitHub Action（可选） | GitHub-hosted runner 出网访问 OpenAI | 跑在 GitHub 云上时，网络问题通常比自建机房小，但仍要仓库 Secrets |

作者环境（2026-11-12，Asia/Shanghai）上：GitHub、npm、npmmirror 返回 200；GHCR 无 token 时 401（正常），完成匿名 token 交换后可读取 `0.9.1` 索引；`api.openai.com` / `chatgpt.com` / 官方文档站返回 **403**。403 只说明「这一跳在该环境被拒绝或风控」，不代表你的浏览器或公司出口一定不通。

## 推荐策略

1. **先探针，再 pull / install。**  
   `./scripts/probe-network.sh` 看 HTTP；`./scripts/probe-ghcr.sh` 核对钉住的 digest。
2. **镜像钉 digest，不要用浮动 `latest`。**  
   本仓默认：

   ```bash
   export CODEX_SECURITY_IMAGE=ghcr.io/openai/codex-security@sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037
   ```

   写作时（2026-11-12）该 digest 与标签 `0.9.1`、`latest`、`sha-fe1089ab514599931ff0ce77a82dc8c4a99201ea` 一致。以后 `latest` 会漂移。
3. **GHCR / npm 拉不动：** 给 Docker 和 npm 配 `HTTPS_PROXY`，或在能访问的机器上 `docker pull` + `docker save`，再拷到目标机 `docker load`。社区加速前缀经常更换，**不要把某一家写进生产配置后忘记复查**。
4. **npm 官方源慢：**  

   ```bash
   npm install --prefix data/npm-prefix --registry https://registry.npmmirror.com @openai/codex-security@0.9.1
   ```

   装完用 `./scripts/npm-smoke.sh` 确认 CLI 能回答 `--version`。
5. **扫描阶段仍访问不到 OpenAI：** 这不是 Compose 配错。先在同一出口跑 `curl -I https://api.openai.com/v1/models`，再考虑官方支持的其他 provider，或把扫描放到能合规访问该 API 的 CI / 海外 runner。本仓不提供任何「翻墙」教程。

## 不要把密钥写进镜像或脚本

- 密钥只放 `local/.env`（已 gitignore），或 CI Secrets。  
- 不要把 `OPENAI_API_KEY` 写在命令行参数里（会出现在 `ps` 和 shell 历史）。  
- `state/` 在 device-auth / `login --with-api-key` 之后会保存登录态，目录权限应为 `700`，不要提交、不要同步到共享盘。
