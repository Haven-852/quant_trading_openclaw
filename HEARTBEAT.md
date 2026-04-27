# HEARTBEAT.md - OpenClaw 心跳保活机制

**目标**：保证 OpenClaw + WeChat 通道 24 小时在线，即使超时也能自动重连，并在重连成功后发送“我又复活了！”消息，同时读取之前记忆。

## 心跳检查清单（每 30 秒执行一次）

1. **检查 gateway 状态** (`openclaw gateway status`)
2. **检查 WeChat 通道** (`openclaw channels status --probe`)
3. **检查 cursor-brain 插件** 是否超时或失败
4. **如果发现超时或断开**：
   - 执行 `openclaw gateway restart --force`
   - 等待 10 秒
   - 重新检查状态
   - 如果成功，发送微信消息：“我又复活了！”
5. **读取记忆**：
   - 读取 `memory/2026-04-26.md`（今天）
   - 读取 `memory/2026-04-25.md`（昨天）
   - 加载 `MEMORY.md`（长期记忆）
6. **如果重连失败超过 3 次**：
   - 执行 `openclaw gateway stop && openclaw gateway start`
   - 记录错误到 .learnings/ERRORS.md

## 自动重连规则

- 连续超时 5 次 → 立即重启 gateway
- 重启后发送“我又复活了！”到微信
- 读取最近 memory 文件，恢复上下文
- 24 小时不间断运行（使用 Windows 任务计划程序或 pm2）

## 当前配置（已更新）

- requestTimeout: 10 分钟
- maxConsecutiveTimeouts: 10
- autoReconnect: true
- heartbeatIntervalMs: 30000

**本文件由 AIquant 自动维护**。每次心跳都会追加日志到 memory/2026-04-26.md。

---

**执行命令**（用于测试）：
```powershell
openclaw agent --to weixin --message "心跳测试：我还在线"
```

此机制确保即使出现请求超时，也能自动恢复连接并通知用户。