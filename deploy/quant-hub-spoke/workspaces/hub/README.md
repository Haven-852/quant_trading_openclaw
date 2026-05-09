# Hub（Seth）任务板：仅 Hub 维护；子智能体通过各自目录的 TASK_IN.md 接收任务。

## 当前焦点

- （由 Seth 填写）需求摘要、里程碑、风险。

## 与子智能体协作

- 向 `../research/TASK_IN.md`、`../engineering/TASK_IN.md`、`../qa/TASK_IN.md`、`../doc-writer/TASK_IN.md` 写入由 Seth 签发的任务包；子 agent **不**在此文件反向修改 Hub 策略（仅可追加执行备注到各自目录的 `TASK_OUT.md`）。
- **Research → Engineering**：研究员交付中须包含给工程的 **`REQUIREMENTS_FOR_ENGINEERING.md`**（或任务书内等价路径）；工程任务 `TASK_IN.md` 应引用该文件。
- **QA**：仅在任务书中确认 **回测已可执行** 后再派发 QA；QA 按 **策略规格** 做回测与验收（见 `../qa/README.md`）。
