# Start Cove WebUI for OpenClaw (https://www.npmjs.com/package/@maudecode/cove)
# Usage: .\start-cove.ps1 [CovePort]   (default 8080)
# Optional: $env:GATEWAY_HOST / $env:GATEWAY_PORT for canvas proxy (default 127.0.0.1 / 18789)

if (-not $env:GATEWAY_HOST) { $env:GATEWAY_HOST = "127.0.0.1" }
if (-not $env:GATEWAY_PORT) { $env:GATEWAY_PORT = "18789" }

[int]$CovePort = 8080
if ($args[0] -match '^\d+$') { $CovePort = [int]$args[0] }

Write-Host "Cove WebUI: http://127.0.0.1:$CovePort/"
Write-Host "In Cove, connect Gateway to: ws://$($env:GATEWAY_HOST):$($env:GATEWAY_PORT) (see ~\.openclaw\openclaw.json)"
& cove --port $CovePort
