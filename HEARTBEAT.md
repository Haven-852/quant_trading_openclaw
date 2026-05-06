# HEARTBEAT.md - OpenClaw 心跳保活机制

**目标**：保证 OpenClaw + WeChat 通道 24 小时在线，即使超时也能自动重连，并在重连成功后发送“我又复活了！”消息，同时读取之前记忆。

## 心跳检查清单（每2个小时执行一次，非紧急不在心跳里跑完整 Agent）

1. **检查 gateway 状态** (`openclaw gateway status`)，如果是健康的话，就不进行任何操作。
2. **如果发现超时或断开**：
   - 执行 `openclaw gateway restart --force`
   - 等待 30 秒
   - 重新检查状态
   - 如果成功，发送微信消息：“我又复活了！”


## 自动重连规则

- 连续超时 5 次 → 立即重启 gateway
- 重启后发送“我又复活了！”到微信
- 重启之后自动读 MEMORY；人类发下一条消息时由正常会话加载
- 24 小时不间断运行（使用 Windows 任务计划程序或 pm2）

## 当前配置要点

本节为静态说明，心跳回复中不要逐条执行、不要展开全文。

- `~/.openclaw/openclaw.json` 必须包含 **`gateway.mode`**（例如 `"local"`），否则计划任务里的 Gateway **无法启动**（日志：`Gateway start blocked: set gateway.mode=local`）。
- `openclaw-cursor-brain` 的 `config` 只能使用插件 schema 允许的字段；不要随意加键，否则 CLI 会报 **invalid config**。
- **本地 Ollama**（`~/.openclaw/openclaw.json`）：已配置 `models.providers.ollama`（`http://127.0.0.1:11434`）。  
- **重要**：Cursor **用量封顶** 时，上游常返回 **HTTP 200 + 正文里的 `[Error] usage limit...`**，OpenClaw 会当作 **正常完成的一轮回复**，**不会**再走 `fallback`。因此仅靠「把 Ollama 放在 fallbacks 最后」**无法**在额度用尽后自动改答。  
- **已实现的修法**：增加独立 Agent **`weixin-ollama`**（`primary: ollama/qwen3:8b`，必要时再试 `cursor-local`），并用顶层 **`bindings`** 把 **`openclaw-weixin`** 渠道路由到该 Agent → **微信侧默认先走 Ollama**，不再先撞 Cursor 额度。其它仍走默认 `main` 的入口可继续用 `cursor-local/auto`（且 `defaults.fallbacks` 里 **Ollama 已提前到 cursor 链之前**，非微信场景也能更快切本地）。  
- **副作用**：微信会话的 agent id 变为 **`weixin-ollama`**，与旧会话 **`main`** 下的历史 **不共享同一条 session 存储**（新对话上下文从新 Agent 开始）。若需沿用旧线程，只能改回绑定或手动迁移会话（高阶）。  
- **为何重启后日志仍写 `agent model: cursor-local/auto`，微信仍走 Cursor？**  
  - 启动时那一行往往是 **默认主会话 / 合并前** 的展示；若实际会话键是 **`agent:main:main`** 且其中 **`modelProvider` 仍为 `cursor-local`**（常见于 **webchat / 旧会话合并**），会继续用 Cursor，**不会**用到 `bindings → weixin-ollama`。  
  - **已改为**：`agents.defaults.model.primary = ollama/qwen3:8b`，让 **`main` 及其默认会话也先走 Ollama**，避免被 `agent:main:main` 卡住。额度恢复后若要「优先 Cursor」，再把 **primary** 改回 `cursor-local/auto` 并把 Ollama 放进 **fallbacks** 前几项即可。  
- **18790 端口争抢**：日志若出现 **`EADDRINUSE 127.0.0.1:18790`**，说明 **多个 streaming proxy** 同时起来；先 **`openclaw gateway stop`**，确认无残留后再 **`openclaw gateway start --force`**，必要时 **`openclaw cursor-brain proxy restart`**。  
- **代理连崩 3 次**：日志若提示 `Run: openclaw cursor-brain proxy restart`，在修复配置后执行：  
  `openclaw cursor-brain proxy restart` 或 `openclaw gateway restart --force`。

**本机 Ollama 现状（示例）**：可执行 `ollama list`；本机已装 `qwen3:8b`、`deepseek-r1:8b`、`qwen3-coder:30b` 等。保证 **`11434` 通**：`(tnc 127.0.0.1 -Port 11434).TcpTestSucceeded`。若未启动，可运行仓库脚本 **`scripts\ensure-ollama.ps1`**，或从开始菜单打开 **Ollama** 桌面端（托盘常驻即会 serve）。

**想更快切到 Ollama（可选）**：若经常遇到 Cursor **用量封顶**、不想等整串 cursor fallback，可把 `ollama/qwen3:8b` 挪到 `fallbacks` **更靠前**（甚至紧跟在 `cursor-local/auto` 之后），代价是 **Cursor 可用时也会更早尝试本地模型**。

**本文件由 AIquant 自动维护**。心跳日志建议写入当天 `memory/YYYY-MM-DD.md`。

---

**执行命令**（用于测试）

1. **网关 + 通道**（需 Gateway 已监听 `127.0.0.1:18789`）：

```powershell
openclaw gateway status
openclaw channels status --probe
```

2. **直发微信**（不经过 Agent/LLM，适合「链路是否通」；`--target` 填你的微信会话 id，可从 `openclaw sessions --json` 里会话 key 末尾复制）：

```powershell
openclaw message send --channel openclaw-weixin --target "你的id@im.wechat" -m "心跳测试：我还在线"
```

3. **Agent 带回执**（需指定 `--session-id` 或 `--reply-to` 等；向微信投递时通常还要带 **`--reply-to`/`--target`**，否则会报 *requires target*）：

```powershell
openclaw agent --help
```

此机制确保在 Gateway 正常时，通道探测与直发消息可用于验证「是否在线」；超时与自动恢复仍依赖 Gateway 进程与计划任务。

---

## 先分辨：微信里出现 `usage limit` / `Spend Limit`（与超时不同）

若回复里类似：**「You've hit your usage limit」**、**「Switch to a different model」**、**「set a Spend Limit」**——这是 **Cursor Pro / 账户用量或消费上限** 触发的拒绝，**不是** OpenClaw 或微信通道坏了。

此时日志里常见：**`Streaming proxy exited (code 1)`**、**`Proxy crashed`**。本质是 **`cursor-agent` 向上游要模型时被 Cursor 侧拒了**，代理进程异常退出，Gateway 再按策略重启。

**处理（三选一或组合）：**

1. 在 **Cursor 客户端**：打开 **设置 → 订阅 / 用量 / Spend limit**，按官方提示 **提高消费上限**、**换可用模型**，或 **等到用量重置**。  
2. 在 **`~/.openclaw/openclaw.json`**：给主会话增加 **不依赖 Cursor 额度的 provider**（例如本机 **Ollama**），并把 `agents.defaults.model.primary` 或 **`fallbacks` 里靠前** 写上 `ollama/你的模型`，避免额度用尽时整串 `cursor-local` 全挂。  
3. 临时只发说明、不走 LLM：用本文 **`message send`** 向自己发一条纯文本（不经过 Agent）。

---

## 修理：`LLM request timed out` / `cursor-local` 整链超时

本节仅在网关/微信已故障时由人类触发；例行心跳不得执行本节任何命令。

**原因简述**：微信通道正常时，失败多半出在 **`http://127.0.0.1:18790`（Cursor Brain 流式代理）→ `cursor-agent` / Cursor**（含 **用量封顶** 见上一节）。`model-fallback` 刷屏是因为 **所有 fallback 仍走同一 provider**，一个挂就全挂。

### 按顺序做（建议一条条试）

1. **只留一个 Gateway，清掉 18790 争抢**  
   - 执行：`openclaw gateway stop`，等 5 秒。  
   - 再执行：`openclaw gateway start --force`（或 `restart --force`）。  
   - **30 秒内不要**再开第二个会拉插件的 `openclaw status` / `channels probe`（它们会再起代理、容易和 Gateway 抢 **18790**）。  
   - 验证：`Test-NetConnection 127.0.0.1 -Port 18789` 与 `18790` 均为 `True`（或 `tnc 127.0.0.1 -Port 18790`）。

2. **保证 Cursor 真能干活**  
   - 本机 **打开 Cursor**，能正常使用 **Agent/Composer**；必要时 **完全退出 Cursor 再打开**。  
   - 确认 `C:\Users\Administrator\AppData\Local\cursor-agent\agent.cmd` 存在（日志里 Brain 会找这个路径）。

3. **减轻流式代理「过早判失败」**（已在 `openclaw.json` 的 `openclaw-cursor-brain.config` 做了一版稳妥值，可按需微调）  
   - `instantResult: false`：避免为「抢首包」把流式搞得太激进。  
   - `streamResolveGraceMs` 适当加大（例如 15000–30000）：给首 token / 握手留时间。  
   - `forwardThinking` 与 `streamSpeed` 与插件文档保持一致即可。

4. **少触发 `openclaw.json` 反复写入**  
   - 每次 CLI 同步都会改 `meta.lastTouchedAt`，Gateway 会 **reload**。排查时 **集中执行一次** `gateway status`，不要多终端狂刷。

5. **要「先能回微信」、不依赖 LLM 时**  
   - 用 **`openclaw message send`**（见上文测试），不经过 Agent，可区分「通道问题」还是「模型问题」。

6. **仍全超时：加第二条模型路（推荐长期方案）**  
   - 在 `openclaw.json` 的 `models.providers` 里增加 **Ollama**（或别的 API），并在 `agents.defaults.model.fallbacks` **最前面或最后面**插入 `ollama/qwen3:8b` 等；这样 **18790 挂掉时** 还能有一条不依赖 Cursor 的路。（需本机 `ollama serve` 与模型已拉取。）

若按 1–2 后 **18790 仍 EADDRINUSE**，在**管理员 PowerShell** 里查占用：`Get-NetTCPConnection -LocalPort 18790 | Select OwningProcess`，只结束**确认为多余**的进程（勿乱杀系统进程）。