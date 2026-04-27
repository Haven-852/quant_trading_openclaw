# OpenClaw auto-reconnect / heartbeat script
# Monitors gateway, restarts on failure, sends WeChat notice, touches memory log

$ErrorActionPreference = "Continue"
$logFile = "E:\openclaw\haven-852\memory\2026-04-26.md"
$memoryPath = "E:\openclaw\haven-852\memory\2026-04-26.md"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "**[$timestamp] Heartbeat/Reconnect** - $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

Write-Log "Script started (WeChat monitor)"

while ($true) {
    try {
        $status = & openclaw status 2>&1 | Out-String
        $weixinStatus = & openclaw channels status --probe 2>&1 | Out-String

        $needReconnect = $false
        if ($status -match "error|timeout|unhealthy|failed") { $needReconnect = $true }
        if ($weixinStatus -match "error|timeout|failed") { $needReconnect = $true }

        if ($needReconnect) {
            Write-Log "Abnormal status, reconnecting..."

            & openclaw gateway stop 2>&1 | Out-Null
            Start-Sleep -Seconds 5
            & openclaw gateway start --force 2>&1 | Out-Null

            Start-Sleep -Seconds 10

            $newStatus = & openclaw channels status --probe 2>&1 | Out-String
            if ($newStatus -match "OK|running|enabled") {
                Write-Log "Reconnect OK, sending WeChat"
                # UTF-8 bytes only (ASCII source) so default-encoding PS parses reliably
                $msg = [System.Text.Encoding]::UTF8.GetString([byte[]]@(
                    0xE6,0x88,0x91,0xE5,0x8F,0x88,0xE5,0xA4,0x8D,0xE6,0xB4,0xBB,0xE4,0xBA,0x86,0xEF,0xBC,0x81,
                    0xE5,0xB7,0xB2,0xE6,0x81,0xA2,0xE5,0xA4,0x8D,0xE8,0xBF,0x9E,0xE6,0x8E,0xA5,0xE5,0xB9,0xB6,0xE8,0xAF,0xBB,0xE5,0x8F,0x96,0xE6,0x9C,0x80,0xE8,0xBF,0x91,0xE8,0xAE,0xB0,0xE5,0xBF,0x86,0xE3,0x80,0x82
                ))
                & openclaw message send --channel openclaw-weixin --message $msg 2>&1 | Out-Null

                Get-Content -Path $memoryPath -Tail 50 -ErrorAction SilentlyContinue | Out-Null
                Write-Log "Memory tail read done"
            }
            else {
                Write-Log "Channel still bad after reconnect, retry in 30s"
            }
        }
        else {
            Write-Log "Connection OK"
        }
    }
    catch {
        Write-Log ("Exception: " + $_.Exception.Message)
    }

    Start-Sleep -Seconds 30
}
