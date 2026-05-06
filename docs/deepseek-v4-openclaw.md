# OpenClaw 接入 DeepSeek V4（官方 API）

已在 `~\.openclaw\openclaw.json` 增加提供方 **`deepseek-api`**（OpenAI 兼容，`api` 为 `openai-completions`）。

## 填写 API Key 的两种方式

### 方式 A：环境变量（推荐）

1. 在 [DeepSeek 开放平台](https://platform.deepseek.com/) 创建 API Key。
2. 将密钥写入环境变量 **`DEEPSEEK_API_KEY`**（与配置里的占位名一致）。
   - **PowerShell（当前会话）**：`$env:DEEPSEEK_API_KEY = "sk-..."`  
   - **持久化**：Windows「环境变量」用户变量中新建 `DEEPSEEK_API_KEY`，或使用 `~\.openclaw\.env`（若你的 Gateway 启动方式会加载该目录下的 `.env`）。
3. 可参考 **`~\.openclaw\.env.example`** 复制为 **`.env`** 并填入真实密钥（勿提交到 Git）。

### 方式 B：直接写在配置里（不推荐）

将 `models.providers.deepseek-api.apiKey` 从 `"DEEPSEEK_API_KEY"` 改为 **`"sk-...."`** 字面量。注意备份权限与勿泄露。

## 接口与模型 ID

| 字段 | 值 |
|------|-----|
| Base URL | `https://api.deepseek.com/v1` |
| 模型（快） | `deepseek-v4-flash` → 引用名 **`deepseek-api/deepseek-v4-flash`** |
| 模型（强） | `deepseek-v4-pro` → 引用名 **`deepseek-api/deepseek-v4-pro`** |

官方文档：<https://api-docs.deepseek.com/>

## 修改后请重启

- 重启 **OpenClaw Gateway**，然后执行 **`openclaw models list`** 确认网关已加载 `deepseek-api` 等提供方。
