<#!
  在指定子智能体 Docker 沙盒内执行 shell 命令。
  用法：.\exec-spoke.ps1 -Role research -Command "python --version"
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('research', 'engineering', 'qa')]
  [string] $Role,

  [Parameter(Mandatory = $true)]
  [string] $Command
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$composeFile = Join-Path $here 'docker-compose.yml'

$serviceMap = @{
  research    = 'quant-research'
  engineering = 'quant-engineering'
  qa          = 'quant-qa'
}
$service = $serviceMap[$Role]

if (-not (Test-Path $composeFile)) {
  throw "Missing docker-compose.yml at $composeFile"
}

Push-Location $here
try {
  & docker compose -f $composeFile exec -T $service sh -c $Command
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
