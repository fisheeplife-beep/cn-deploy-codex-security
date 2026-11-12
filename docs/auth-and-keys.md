# 登录与 API Key

真实扫描一定要有身份：ChatGPT 登录，或环境变量里的 `OPENAI_API_KEY` / `CODEX_API_KEY`。`--version` / `--help` 不需要。官方细节以 [CLI Authentication @ npm-v0.9.1](https://github.com/openai/codex-security/blob/npm-v0.9.1/sdk/typescript/docs/cli.md#authentication) 为准。

## 三种常见方式

1. **交互登录（本机有浏览器）**  
   路径 B：`cs login` 或 `npx @openai/codex-security@0.9.1 login`。  
   路径 A：`docker compose -f compose.runner.yaml run --rm codex-security login`（通常不如 device-auth / 环境变量适合容器）。
2. **无头 / SSH / 容器：device auth**  
   `codex-security login --device-auth`  
   工作区必须允许 device auth。被禁用时不要反复重试，改用 API Key 或 SSH 把本机 `1455` 端口转到远程（见官方 “Remote login with SSH forwarding”）。
3. **CI / 无人值守：只设环境变量**  
   `OPENAI_API_KEY` 优先于 `CODEX_API_KEY`。环境变量只对当前进程有效；只有 `login --with-api-key`（从 stdin 读入）才会把密钥写入状态目录。

```bash
# 把已有环境变量写入 CLI 状态目录（注意：state/ 从此成为密钥文件）
printenv OPENAI_API_KEY | codex-security login --with-api-key
```

GitHub Action 路径把密钥放在仓库 Secret `CODEX_SECURITY_API_KEY`，不要写进 workflow 文件。本仓主推仍是本机 Compose / CLI，Action 只作可选项，钉 `action-v0.9.1`。

## 优先级与 `--auth`

非交互命令的默认顺序：`OPENAI_API_KEY` → `CODEX_API_KEY` → 已保存的登录。可用 `--auth chatgpt` 或 `--auth api-key` 强制选择。交互扫描在两者都存在时会提问。

同时使用 Codex 与 Codex Security 的文件版 ChatGPT 登录时，官方提醒二者可能共享一次性 refresh token，一边刷新会导致另一边表面上仍显示已登录、实际下一跳失败。此时应分别 `logout` 再 `login`，不要手动硬链接两份 `auth.json` 后不清理。

## 国内特别容易踩的点

- **密钥没问题，但 `api.openai.com` 不通。** 见 [china-network.md](./china-network.md)。先测出口，再怀疑 CLI。  
- **ChatGPT 账号与 API 项目权限不同。** 有的安全工作流还要求 [Trusted Access for Cyber](https://chatgpt.com/cyber)。本仓不解释申请流程。  
- **把 key 写进 compose 文件或示例 CSV。** 不要这样做。本仓只提供 `local/.env.example`。  
- **把 `data/lab/state` 或 `results/.codex-security-state` 提交到 Git。** `.gitignore` 已排除 `data/`、`state/`、`.env`；请确认你没有用 `-f` 强加。  
- **Windows 路径与凭据家目录 ACL。** 官方要求凭据目录的属主与权限受信任；在 WSL2 里跑路径 A/B 通常比原生 Windows 容器少一层坑。

## 其他模型提供商

上游还支持 Amazon Bedrock、OpenRouter、Fireworks AI、Cheaper Inference。Bedrock 走 AWS 凭证，不额外要求 OpenAI 登录。配置方式见官方 CLI「other providers」与 `docs/bedrock.md`。换 provider 不能自动获得与默认 OpenAI 模型完全相同的扫描质量或功能开关（例如部分 Cyber / Daybreak 能力绑定官方 provider）。

## 私有 Git 仓库

容器批量扫描检出私有仓时设置 `GH_TOKEN` 或 `GITHUB_TOKEN`，GitHub Enterprise 再加 `CODEX_SECURITY_GIT_HOST`。这些令牌同样只能进 `local/.env` 或 CI Secrets，且权限应尽量只读。
