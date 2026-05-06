# 量化交易 Hub-and-Spoke（中心辐射）部署说明

本目录提供 **Seth（Hub）+ 三个 Docker 沙盒（研究员 / 工程 / 测试）** 的目录布局、Compose 与 OpenClaw 配置片段，用于 **Backtrader / 量化策略** 的多智能体协同：中心拆解任务，子智能体在隔离环境中执行。

## 架构

```
人类 / 频道 ──► Seth (seth) ──┬──► quant-research  (工作区 + 容器 quant-research)
                              ├──► quant-engineering
                              └──► quant-qa
```

- **OpenClaw**：在 `~/.openclaw/openclaw.json` 中注册多个 `agents.list` 条目；各 agent 的 `workspace` 指向本仓库下 `workspaces/<角色>`（与 Docker 卷挂载目录一致）。
- **Docker**：每个子角色一个容器，**独立文件系统与进程空间**；默认镜像 `python:3.12-slim`，可按需在 compose 中改为含 Node 的镜像以覆盖前端构建。

## 快速开始

### 1. 环境与模型（单一来源）

```powershell
cd E:\openclaw\haven-852\deploy\quant-hub-spoke
copy .env.example .env
# 编辑 .env：设置各 MODEL_* 与 OLLAMA_BASE_URL 等
```

将 `.env` 中的 **`MODEL_HUB_SETH_PRIMARY`、`MODEL_RESEARCH_PRIMARY`、…** 手工同步到 `openclaw.json` 里对应 agent 的 `model.primary`（OpenClaw 当前不会自动读取本目录 `.env`）。

### 2. 启动沙盒

```powershell
cd E:\openclaw\haven-852\deploy\quant-hub-spoke
docker compose up -d
docker compose ps
```

### 3. 合并 OpenClaw 配置

1. 打开 `openclaw-agents.fragment.json`。
2. 将所有 `REPLACE_WITH_ABSOLUTE_PATH` 替换为本机路径，例如 `E:/openclaw/haven-852`（注意 JSON 转义或统一使用正斜杠）。
3. 将 `agents` 与 `tools` 段合并进 `~/.openclaw/openclaw.json`（保留你已有的 `gateway`、`models.providers` 等；若已有 `agents.list`，需手动合并条目避免重复 `id`）。
4. 将 `AGENTS-HUB-SPOKE.md` 中的规则合并进工作区 `AGENTS.md`，确保 **仅 Seth 对外**、子智能体只接 Hub 任务。

### 4. 频道只绑定 Hub（示例）

在 `openclaw.json` 的 `bindings` 中，将微信等频道指向 `agentId: "seth"`，避免用户直连子 agent。具体 `channel` 名称以你当前配置为准。

### 5. 在沙盒内执行命令

```powershell
cd E:\openclaw\haven-852\deploy\quant-hub-spoke
.\exec-spoke.ps1 -Role research -Command "python --version"
.\exec-spoke.ps1 -Role engineering -Command "ls -la"
.\exec-spoke.ps1 -Role qa -Command "pytest -q"
```

`exec-spoke.ps1` 会在对应容器内执行命令，工作目录为 `/workspace`（即宿主机 `workspaces/<角色>`）。

## 目录说明

| 路径 | 用途 |
|------|------|
| `docker-compose.yml` | 三个子智能体沙盒服务 |
| `.env.example` / `.env` | 统一模型与环境变量模板（勿提交 `.env`） |
| `openclaw-agents.fragment.json` | `agents.list` + `tools.agentToAgent` 示例 |
| `AGENTS-HUB-SPOKE.md` | Hub 治理与工作流，可并入工作区 `AGENTS.md` |
| `workspaces/hub` | Seth 工作区（任务板、汇总） |
| `workspaces/research` | 调研产出 |
| `workspaces/engineering` | 代码与配置 |
| `workspaces/qa` | 测试与回测日志 |

## 与 Backtrader 目录的关系

策略与回测代码可放在 `E:\demo\backtrader\`（见根目录 `AGENTS.md`）；Hub 可在任务书中要求 **工程沙盒通过挂载只读或同步脚本** 访问该路径——默认 compose 未挂载 `E:\demo\backtrader`，需要时可在 `docker-compose.yml` 中为 `quant-engineering` / `quant-qa` 增加只读 `volumes` 条目。

## 校验清单

- [ ] `docker compose ps` 三个服务均为 `running`
- [ ] `openclaw.json` 中四个 `id` 唯一且 `workspace` 路径存在
- [ ] 频道 `bindings` 仅指向 `seth`（按你的安全策略）
- [ ] `model.primary` 与 `.env` 中 `MODEL_*` 一致
