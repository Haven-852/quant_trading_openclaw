# 依赖子项目

本目录用于放置与主仓库一同维护的 **可选** 子依赖说明。

**claw-auto-router** 已从本仓库移除。模型与提供方请直接在 **`%USERPROFILE%\.openclaw\openclaw.json`**（及 `agents/*/agent/models.json`）中配置，例如 **`ollama/qwen3:8b`**、**`deepseek-api/...`**、**`cursor-local/...`** 等；不再需要本地 **43123** 路由进程。

若你仍需要上游项目，可自行克隆：<https://github.com/yuga-hashimoto/claw-auto-router>（与本仓库无强制关联）。
