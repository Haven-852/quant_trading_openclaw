# Cove dist/index.html: fix WebSocket blocked by CSP.
# npm's historical connect-src used "ws://*" which Chrome does not treat as a wildcard.
# Replace with scheme sources (ws: wss: http: https:) so Gateway on another port works.
$ErrorActionPreference = "Stop"
$candidates = @(
    (Join-Path $env:APPDATA "npm\node_modules\@maudecode\cove\dist\index.html"),
    (Join-Path ${env:ProgramFiles} "nodejs\node_modules\@maudecode\cove\dist\index.html")
)
$html = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $html) {
    Write-Error "Cove dist/index.html not found. Install: npm install -g @maudecode/cove"
}
$raw = Get-Content -LiteralPath $html -Raw -Encoding UTF8
$patched = $raw `
    -replace "connect-src 'self' ws://\* wss://\* https:;", "connect-src 'self' ws: wss: http: https:;"
if ($raw -eq $patched) {
    if ($raw -match "connect-src 'self' ws: wss:") {
        Write-Host "Already patched: $html"
        exit 0
    }
    Write-Error "Pattern not found in $html — Cove version may have changed; edit connect-src manually."
}
Set-Content -LiteralPath $html -Value $patched -Encoding UTF8 -NoNewline
Write-Host "Patched CSP in: $html"
Write-Host "Hard-refresh Cove in browser (Ctrl+Shift+R)."
