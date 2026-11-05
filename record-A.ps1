# A 段：上传前录"官方那一行现在解析不到" —— 一旦 publish 成功，这画面就永远没了
# 用法: pwsh -File .\record-A.ps1
param([string]$Out = (Join-Path $PSScriptRoot "evidence"), [string]$Pkg = "crowdsentinel-mcp-server-es9")

New-Item -ItemType Directory -Force $Out | Out-Null
$log = Join-Path $Out "A-unclaimed-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$env:UV_NO_CONFIG = 1
$env:UV_CACHE_DIR = Join-Path (Resolve-Path $Out).Path ".cacheA-fresh"

function Say($s) { $s | Tee-Object -FilePath $log -Append }

Say "== timestamp =="
Say (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')
Say "== PyPI 原始响应（期望 404）=="
$resp = curl.exe -sS -D - -o NUL "https://pypi.org/pypi/$Pkg/json" 2>&1
Say ($resp -join "`n")
Say "== 环境 =="
Say ("uv    : " + (python -m uv --version))
Say ("python: " + (python --version 2>&1))
Say ("os    : " + [System.Environment]::OSVersion.VersionString)
Say "== 官方命令，空缓存，期望 unsatisfiable =="
$run = Invoke-Expression "python -m uv tool run --refresh $Pkg@latest 2>&1"
Say ($run -join "`n")
Say "== exit code: $LASTEXITCODE =="

"---- $Pkg ----"
Get-Content $log | Select-Object -Last 12
"日志: $log"
