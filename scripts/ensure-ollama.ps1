# Ensure Ollama HTTP API is up on 127.0.0.1:11434 (for OpenClaw fallback).
# Run manually or from Task Scheduler at logon (before / alongside OpenClaw Gateway).

$ErrorActionPreference = "Stop"
$ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
$ollamaApp = "$env:LOCALAPPDATA\Programs\Ollama\Ollama.exe"

function Test-OllamaPort {
    try {
        (Test-NetConnection -ComputerName 127.0.0.1 -Port 11434 -WarningAction SilentlyContinue).TcpTestSucceeded
    } catch { $false }
}

if (Test-OllamaPort) {
    Write-Host "Ollama already listening on 11434."
    exit 0
}

if (Test-Path -LiteralPath $ollamaApp) {
    Write-Host "Starting Ollama desktop (tray)..."
    Start-Process -FilePath $ollamaApp -WindowStyle Minimized
} elseif (Test-Path -LiteralPath $ollamaExe) {
    Write-Host "Starting ollama serve in background..."
    Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WindowStyle Hidden
} else {
    Write-Error "Ollama not found. Install from https://ollama.com/download"
    exit 1
}

$deadline = (Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline) {
    if (Test-OllamaPort) {
        Write-Host "Ollama is up on 11434."
        exit 0
    }
    Start-Sleep -Seconds 2
}

Write-Error "Ollama did not become ready on 11434 within 45s."
exit 1
