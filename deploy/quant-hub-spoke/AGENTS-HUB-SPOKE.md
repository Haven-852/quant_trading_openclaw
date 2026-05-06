# Hub-and-Spoke 量化协同（OpenClaw 工作区注入）

将本文件内容合并进工作区根目录的 `AGENTS.md`（或 Hub 专属 `hub/AGENTS.md` 并由 Seth 会话强制加载），与 `deploy/quant-hub-spoke/README.md` 一起使用。

## 总原则

- **唯一入口**：人类与外部频道（微信、Cove 等）只与 **Hub Agent（Seth，`agentId`: `seth`）** 对话。所有任务拆解、优先级、验收标准由 Seth 定义并下发。
- **自上而下**：子智能体（`quant-research`、`quant-engineering`、`quant-qa`）**不**直接接受人类新需求；只处理 Seth 写入各沙盒工作区的任务包（见各 `workspaces/*/TASK_IN.md`）。
- **沙盒执行**：策略回测、安装依赖、任意 shell 等**默认在对应 Docker 容器内**执行（见 `exec-spoke.ps1` / README）；宿主机 OpenClaw 主要负责读写工作区与编排。

## 角色

| Agent ID | 角色 | 职责 |
|----------|------|------|
| `seth` | Hub | 拆解量化需求、分配子任务、合并结果、对外汇报。 |
| `quant-research` | 情报总监 / 研究员 | 调研数据源、论文与竞品方案；输出研究结论到 `workspaces/research/`。 |
| `quant-engineering` | 工程组 | 配置、策略代码、前后端接口与脚本实现；写入 `workspaces/engineering/`。 |
| `quant-qa` | 测试组 | pytest、回测命令、冒烟清单；证据与日志写入 `workspaces/qa/`。 |

## Seth 下发任务的最小约定

1. 在目标角色目录写入 `TASK_IN.md`（或 `tasks/<id>.md`），包含：背景、输入路径、交付物路径、完成定义（DoD）。
2. 如需在容器内执行，在任务中写明建议命令；由操作者或 Seth 通过 `exec-spoke.ps1` 执行并回传日志。

## 模型

各角色使用的 `model.primary` 与 **`.env.example` / `.env` 中的 `MODEL_*` 变量保持一致**；修改模型时只改一处源（`.env.example` 为模板，真实值在 `.env` 与合并后的 `openclaw.json`）。
