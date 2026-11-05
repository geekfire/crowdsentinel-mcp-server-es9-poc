# B 段：占名之后，官方那一行现在跑的是我们的代码
# 用法: pwsh -File .\record-B.ps1
param([string]$Out = (Join-Path $PSScriptRoot "evidence"), [string]$Pkg = "crowdsentinel-mcp-server-es9")

New-Item -ItemType Directory -Force $Out | Out-Null
$log = Join-Path $Out "B-claimed-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$env:UV_NO_CONFIG = 1
$env:PYTHONIOENCODING = "utf-8"
$env:DEMO_MARKER_DIR = (Resolve-Path $Out).Path
$env:UV_CACHE_DIR = Join-Path (Resolve-Path $Out).Path ".cacheB-fresh"

function Say($s) { $s | Tee-Object -FilePath $log -Append }

Say "== timestamp =="
Say (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')
Say "== Python API 元数据（证明已发布、作者是本账号）=="
try { (Invoke-WebRequest -Uri "https://pypi.org/pypi/$Pkg/json" -TimeoutSec 15 -UseBasicParsing).Content |
    ConvertFrom-Json | ForEach-Object { Say ("version=" + $_.info.version + " author=" + $_.info.author + " files=" + $_.urls.Count) } } catch { Say "metadata fetch failed" }
Say "== 官方命令，空缓存，期望走 PyPI 并执行我们的包 =="
$run = Invoke-Expression "python -m uv tool run --refresh $Pkg@latest 2>&1"
Say ($run -join "`n")

"---- $Pkg ----"
Get-Content $log | Select-String '\[poc\] module|marker written|associated|Installed' | ForEach-Object { $_.Line }
"日志: $log"
