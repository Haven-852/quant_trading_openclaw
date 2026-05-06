# Cove — OpenClaw 可视化管理界面

[Cove（`@maudecode/cove`）](https://www.npmjs.com/package/@maudecode/cove) 是面向 OpenClaw Gateway 的 Web 控制台（会话、配置、Cron、频道、日志等）。

## 本机已安装方式

已在当前环境执行全局安装：

```powershell
npm install -g @maudecode/cove
```

验证：

```powershell
cove --version
```

## 启动 Cove

**方式 A — 直接命令（默认端口 8080）**

```powershell
cove
```

可选自动打开浏览器：

```powershell
cove --port 8080 --open
```

**方式 B — 使用仓库脚本（可与 Gateway 端口对齐）**

```powershell
cd E:\openclaw\haven-852
.\scripts\start-cove.ps1
```

脚本会把 **Canvas 相关代理** 指向 `GATEWAY_HOST` / `GATEWAY_PORT`（默认 `127.0.0.1` / `18789`）。若你的 Gateway 端口不同：

```powershell
$env:GATEWAY_PORT = "18789"
.\scripts\start-cove.ps1 9090
```

（第一个参数为 Cove 监听端口，默认脚本内为 8080；按需修改 `start-cove.ps1`。）

## 在浏览器里连接 Gateway

1. 打开 **http://127.0.0.1:8080**（或你 `--port` 指定的端口）。
2. **网关地址必须是 OpenClaw 端口（默认 18789），不是 Cove 的 8080**。在 Cove 里填 **WebSocket**：**`ws://127.0.0.1:18789`**（或与 `openclaw.json` 里 `gateway.port` 一致）。界面里若出现 “Local gateway: ws://localhost:8080” 一类提示，**8080 是 Cove 自己的 HTTP 端口，不要当成 Gateway**。
3. **鉴权（最常见：Connection failed）**：若 `~\.openclaw\openclaw.json` 里 **`gateway.auth.mode` 为 `token`**（多数安装会自动生成 **`gateway.auth.token`**），仅用 `ws://127.0.0.1:18789` **不带令牌**会被网关拒绝 WebSocket，Cove 会显示 **connection failed**。处理步骤：
   - 用记事本/编辑器打开 **`C:\Users\Administrator\.openclaw\openclaw.json`**（路径以你机器为准）。
   - 找到 **`gateway.auth.token`**，复制那一段 **token 字符串**。
   - 回到 Cove：用 **Skip to manual login**，或向导里选择 **Token** 认证方式，把 Token **粘贴进去**后再连；或在支持 “在 URL 中带 token” 的版本里按 Cove 提示填写（勿把 Token 发到聊天或截图外传）。
4. 若你希望本机 Cove **免 Token**（仅供个人内网评估，会降低 loopback 上的口令防护），可把 `gateway.auth.mode` 改为 **`none`** 并重启 Gateway——**不推荐**在多用户或已暴露端口的机器上使用。

官方文档摘要：[npm 包页 README](https://www.npmjs.com/package/@maudecode/cove)。

### CSP 拦截 WebSocket（控制台：`violates Content Security Policy … connect-src`）

Cove 自带的 `dist/index.html` 里曾有 **`connect-src … ws://* wss://*`**。在 Chrome 里 **`ws://*` 不会像“任意 WebSocket”那样生效**，结果连 **`ws://127.0.0.1:18789`** 也会被阻止，界面一直 **Connecting…**，控制台报 CSP。

**处理方式**：把该段改成 **按协议放行**，例如：

`connect-src 'self' ws: wss: http: https:;`

本机已对全局安装目录下的 `dist/index.html` 做过一次修改。执行 **`npm update -g @maudecode\cove`** 后可能被覆盖，可在本仓库重新执行：

```powershell
cd E:\openclaw\haven-852
.\scripts\patch-cove-csp.ps1
```

然后浏览器对 **http://127.0.0.1:8080** 做一次 **硬刷新**（Ctrl+Shift+R）。

### `control ui requires device identity (use HTTPS or localhost secure context)`

Cove 跑在 **8080**，网关自带控制台在 **18789**，**不是同一站点**。网关会把 Cove 当作「独立 Control UI」：默认要求握手时带 **设备身份**（浏览器安全上下文里生成的密钥）。单独开 Cove 时往往还没有这套身份，就会报这句错。

在 **`~\.openclaw\openclaw.json`** 的 **`gateway`** 下增加（本机已加）：

```json
"controlUi": {
  "allowInsecureAuth": true
}
```

含义（与 OpenClaw 文档一致）：在 **loopback / 本机** 场景下允许 **仅网关 Token** 连接 Control UI，省略设备身份与配对。**改完后必须重启 Gateway**（例如重启 `openclaw gateway` 服务）。

仅用于本机调试、不能接受设备配对流程时，才考虑文档里的紧急项 **`dangerouslyDisableDeviceAuth`**（安全性显著降级，一般不推荐）。

## 前置条件

- **OpenClaw Gateway 已运行**且与 Cove 使用的主机/端口一致（例如 `openclaw gateway status` 中 `127.0.0.1:18789` 可连）。
- 使用 **支持 WebSocket 的 modern 浏览器**。

## 升级

```powershell
npm update -g @maudecode/cove
```

## 与内置控制面板的关系

OpenClaw 自身在 Gateway 上提供 **Dashboard**（例如 `http://127.0.0.1:18789/`）。Cove 是**另一套**更完整的独立 WebUI，通过同一 Gateway WebSocket 工作，二者可同时存在，只要端口不冲突（Cove 默认 8080，Gateway 默认 18789）。

## Windows：浏览器提示「无效响应」或 HTTP 403

上游 `cove.js` 曾用 **`baseDir + "/"`** 判断静态文件是否在 `dist` 目录内；在 **Windows** 下绝对路径多为 **`\`**，前缀判断失败会导致 **任意页面都返回 403**，浏览器表现为 **ERR_INVALID_RESPONSE / This page isn't working**。

本机已对全局安装路径  
`%AppData%\npm\node_modules\@maudecode\cove\bin\cove.js`  
中的 **`isPathSafe`** 改为基于 **`path.relative`** 的写法（跨盘符更安全）。  

执行 **`npm update -g @maudecode/cove`** 后补丁会被覆盖；若再次出现 403，需重做相同修改或向 [MaudeCode/cove](https://github.com/MaudeCode/cove) 反馈 Windows 兼容性。

自检：

```powershell
curl.exe -sI http://127.0.0.1:8080/
curl.exe -s http://127.0.0.1:8080/health   # 应输出 OK
```

两行均正常后再用浏览器打开 **http://127.0.0.1:8080/**。
