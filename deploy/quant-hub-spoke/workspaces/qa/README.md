# 测试沙盒（QA）

- **OpenClaw agent id**：`quant-qa`
- **Docker**：`quant-qa`

## TASK_IN.md（由 Seth 写入）

```markdown
## 任务 ID
Q-YYYYMMDD-001

## 目标
（例如：对某策略运行 pytest + 短回测）

## 输入
- 工程产出路径、数据夹具说明

## 交付
- `REPORT.md` 或日志片段；失败时附复现命令

## DoD
- 命令在非交互环境下可重复执行；退出码 0
```
