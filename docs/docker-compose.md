# 路径 A：GHCR + Docker Compose

上游提供两份 Compose 文件，用途不同。**主推 runner，而不是一上来就 bulk-scan。** 这是 CLI 封装，每次 `docker compose run --rm` 跑完就退出，**不会**在后台常驻一个扫描服务，也没有要对外暴露的端口。

官方英文说明以钉 tag 为准：

- [docker/README.md @ npm-v0.9.1](https://github.com/openai/codex-security/blob/npm-v0.9.1/docker/README.md)
- [compose.runner.yaml](https://github.com/openai/codex-security/blob/npm-v0.9.1/compose.runner.yaml)
- [compose.yaml](https://github.com/openai/codex-security/blob/npm-v0.9.1/compose.yaml)（批量）

本页只补国内跟做时容易踩的差异，不替换官方文档。

## runner vs bulk：先分清

| | `compose.runner.yaml`（主推） | `compose.yaml`（批量） |
|--|--|--|
| 默认镜像 | `ghcr.io/openai/codex-security:latest`（浮动） | `codex-security:local`，并且 **带 build** |
| 默认命令 | `--help` | `bulk-scan /input/repositories.csv --output-dir /output` |
| 需要 CSV | 否 | 是，且缺文件会直接失败（`create_host_path: false`） |
| 适合 | 对已有 checkout 跑单次 `scan` / `login` / `dedupe` | 一份 CSV 里多仓库、可恢复的战役式扫描 |

**最容易踩的坑：** 直接 `docker compose -f compose.yaml up` 却没设 `CODEX_SECURITY_IMAGE`，机器会按 Dockerfile **本地编译**（还要拉 Node 26、pnpm、源码打包），国内弱网几乎必卡。要用已发布镜像，必须显式钉 digest。

## 本仓推荐顺序

```bash
./scripts/preflight.sh
./scripts/clone-upstream.sh          # 需要官方 compose 与 seccomp 文件
./scripts/probe-ghcr.sh              # 无 Docker 也能核对 digest
./scripts/compose-runner-smoke.sh    # 需要 Docker：pull + --version / --help
```

脚本会：

1. 把 `CODEX_SECURITY_IMAGE` 设成 `ghcr.io/openai/codex-security@sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037`；  
2. 预先创建 `data/lab/results` 与 `data/lab/state` 并 `chmod 700`；  
3. 设置 `CODEX_SECURITY_USER="$(id -u):$(id -g)"`。

没有这三步，常见失败是：`latest` 被换成别的版本、bind mount 因目录不存在而拒绝启动、容器内用户是 `10001:10001` 导致结果目录对宿主不可写。

## 对一个本地仓库做扫描（仍要密钥）

把要扫描的目录放到 results 下（容器里是 `/output/...`），或在 `run` 时额外挂卷。登录与密钥见 [auth-and-keys.md](./auth-and-keys.md)。示意（在上游浅克隆目录执行）：

```bash
export CODEX_SECURITY_USER="$(id -u):$(id -g)"
export CODEX_SECURITY_IMAGE=ghcr.io/openai/codex-security@sha256:947961462b918b4fa830d89772971b9a4d1423c79bd5489d5a2b33d4c6dd9037
export CODEX_SECURITY_RESULTS=/abs/path/to/cn-deploy-codex-security/data/lab/results
export CODEX_SECURITY_STATE=/abs/path/to/cn-deploy-codex-security/data/lab/state

# 可选：device-auth（工作区必须允许）
# docker compose -f compose.runner.yaml run --rm codex-security login --device-auth

docker compose -f compose.runner.yaml run --rm \
  --volume /absolute/your-repo:/input/repository \
  -e OPENAI_API_KEY \
  codex-security scan /input/repository --output-dir /output/scans/run-001 --headless
```

不要把 `results/`、`state/` 放进被扫描的 Git 工作树里再推上去。凭证目录默认会落在 results 下的 `.codex-security-state/codex-home`。

## 批量扫描

```bash
./scripts/compose-bulk-prepare.sh
```

它会复制一份示例 CSV 到 `data/lab/repositories.csv` 并打印完整命令。示例行里的仓库和 revision **是占位符**，改成你有权扫描、且 revision 为 40 位完整 commit 的地址后再跑。私有仓还要 `GH_TOKEN` 或 `GITHUB_TOKEN`；GitHub Enterprise 用 `CODEX_SECURITY_GIT_HOST`。

CSV 格式以上游 [bulk-scans](https://github.com/openai/codex-security/blob/npm-v0.9.1/sdk/typescript/docs/cli.md#bulk-scans) 为准：至少 `id,repository,revision`。

## 权限、seccomp、AppArmor

- 镜像以非 root（默认 uid 10001）、`cap_drop: ALL`、`no-new-privileges` 和项目自带 seccomp 启动。  
- 0.9.1 起 seccomp 限制部分 socket 族，并拦截 `ptrace` / `process_vm_readv` / `process_vm_writev`（见 0.9.1 Release 的 Linux Compose 升级说明）。  
- 源码检查依赖宿主支持 Bubblewrap 与 user namespace。若 Ubuntu 限制了嵌套 user namespace，需由管理员安装上游 `docker/codex-security.apparmor`，并在命令中追加 `-f compose.apparmor.yaml`。  
- `run --rm` 只删容器，**不会**删你准备的 results/state；换镜像版本后仍应复用同一对目录做去重。

## 本仓未验证的部分

作者机无 Docker Engine，因此 **镜像 pull、Compose 起容器、真实 scan / bulk-scan 均标未验证**。脚本已写好，有 Docker 的机器跑通 `compose-runner-smoke.sh` 后，可以把日志回填到 `examples/compose-runner-smoke.txt`。
