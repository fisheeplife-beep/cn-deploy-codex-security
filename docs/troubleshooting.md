# 排障（CN 配套摘要）

上游完整行为以钉 tag 的 [docker/README.md](https://github.com/openai/codex-security/blob/npm-v0.9.1/docker/README.md) 和 [CLI 文档](https://github.com/openai/codex-security/blob/npm-v0.9.1/sdk/typescript/docs/cli.md) 为准。这里只收跟做高频项。

## `docker compose` 要编译，而不是拉 GHCR

**原因：** 你用了 `compose.yaml`，它的默认镜像是 `codex-security:local` 并且声明了 `build:`。  
**处理：** 设置 `CODEX_SECURITY_IMAGE=ghcr.io/openai/codex-security@sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037`，或改走 `compose.runner.yaml`。单次试用不要在国内弱网下从 Dockerfile 现场 build。

## 容器立刻退出：bind 源路径不存在

**原因：** 两份 Compose 都把 `create_host_path` 设为 `false`。`results/`、`state/`，以及 bulk 路径的 CSV，必须事先存在。  
**处理：** `./scripts/prepare-lab-dirs.sh`；bulk 再用 `./scripts/compose-bulk-prepare.sh`。

## 结果目录是 root 或 `10001` 所有，宿主写不进去

**原因：** 未设 `CODEX_SECURITY_USER`，容器默认 `10001:10001`。  
**处理：** `export CODEX_SECURITY_USER="$(id -u):$(id -g)"` 后再 `run`。不要用 `chmod 777` 作为长期方案。

## `login --device-auth` 失败

**原因：** 工作区关闭了 device auth，或容器出网到 ChatGPT 认证失败。  
**处理：** 改设 `OPENAI_API_KEY` / `CODEX_API_KEY`；本机可交互时用浏览器登录；远程用官方文档的 SSH `1455` 转发。不要把失败日志里的一次性码贴到公共渠道。

## 命令成功拉起，但扫描立刻报认证 / 网络错误

**原因：** 常见于大陆出口访问不到 `api.openai.com`，或 key 属于没有权限的项目。  
**处理：** 在**同一台机器、同一代理**上 `curl -sS -o /dev/null -w '%{http_code}\n' https://api.openai.com/v1/models`（未带 key 时 401 表示 TCP/TLS 是通的，403/000 则先查网络）。详见 [china-network.md](./china-network.md) 与 [auth-and-keys.md](./auth-and-keys.md)。

## npm 报 `EEXIST` 或 `cs` 不是这个包

**原因：** 全局 `cs` 短名可能与其他命令冲突。  
**处理：** 用 `codex-security`，或 `npx @openai/codex-security@0.9.1`。本仓路径 B 默认装到 `data/npm-prefix`，不污染全局 PATH。

## Node 版本不被接受

**原因：** 官方 engines 是 `^22.13.0 || ^24.0.0 || ^26.0.0`。Node 20 / 23 / 25 会失败。  
**处理：** 换官方支持的主版本。路径 A 不依赖宿主 Node。

## GHCR 匿名 `401`

**原因：** 未做 token 交换。这是注册表的正常挑战，不是包不存在。  
**处理：** `./scripts/probe-ghcr.sh`。若探针成功而 `docker pull` 失败，多半是 Docker 出网/代理问题，而不是 tag 写错。

## AppArmor / user namespace / Bubblewrap

**原因：** 部分 Ubuntu 默认限制嵌套 user namespace，容器内沙箱起不来。  
**处理：** 管理员安装上游 `docker/codex-security.apparmor`，命令追加 `-f compose.apparmor.yaml`。不要为了图方便关掉整机 AppArmor。seccomp 拦截 `ptrace` 是 0.9.1 的预期行为。

## 想「接着上次的扫描目录」却路径全乱

**原因：** 把宿主编译产物或旧 state 挪到新挂载点，不会改写已保存的绝对路径。  
**处理：** 在 runner 里重新扫，或保持当初的容器内路径不变。

## 对照翻译仓却对不上命令

**原因：** [yangshun2005/codex-security-cn](https://github.com/yangshun2005/codex-security-cn) 是 2026-08-19 的 README 翻译，当时的 CLI 示例、模型名和扫描选项已过时，也不是部署实测。  
**处理：** 以官方 `npm-v0.9.1` 文档和本仓脚本为准。
