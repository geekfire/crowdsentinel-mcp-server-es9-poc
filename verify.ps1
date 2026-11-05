# 三段对照：证明"官方那行命令现在解析不到，而我的包能接住"
# 用法: pwsh -File .\verify.ps1        （跑完全部三段，输出存到 .\evidence\）
param([string]$Out = ".\evidence")

$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force $Out | Out-Null
$env:DEMO_MARKER_DIR = (Resolve-Path $Out).Path
$env:UV_NO_CONFIG = 1
$env:PYTHONIOENCODING = "utf-8"
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$pkg = "crowdsentinel-mcp-server-es9"
$uv = "python -m uv"

function Shot($name, $cmd) {
  $log = Join-Path $Out "$name.log"
  "### $name :: $cmd" | Tee-Object -FilePath $log
  try { Invoke-Expression "$cmd 2>&1" | Tee-Object -FilePath $log -Append } catch { "  (failed: $_)" | Tee-Object -FilePath $log -Append }
  ""
}

# ---------- A：真实 PyPI，名字不存在（当前状态） ----------
$env:UV_CACHE_DIR = Join-Path $Out ".cacheA"
Shot "A-unclaimed" "$uv tool run --refresh $pkg@latest"
"A 段期望：hits 'not found in the package registry' 或 'unsatisfiable'"

# ---------- B：本地索引注入同名包，复现"被抢注"后 ----------
Remove-Item -Recurse -Force .\serve -ErrorAction SilentlyContinue
python .\build_wheel.py | Tee-Object -FilePath (Join-Path $Out "wheel.txt")
New-Item -ItemType Directory -Force .\serve\packages, .\serve\simple\$pkg | Out-Null
$whl = Get-ChildItem .\dist\*.whl | Select-Object -First 1
Copy-Item $whl.FullName .\serve\packages\
$sha = (Get-FileHash $whl.FullName -Algorithm SHA256).Hash.ToLower()
"<html><body><a href=`"../../packages/$($whl.Name)#sha256=$sha`">$($whl.Name)</a></body></html>" |
  Set-Content ".\serve\simple\$pkg\index.html" -Encoding UTF8

$job = Start-Job { Set-Location $using:PWD; python -m http.server 8766 --bind 127.0.0.1 --directory serve }
Start-Sleep -Seconds 2
$env:UV_CACHE_DIR = Join-Path $Out ".cacheB"
Shot "B-claimed" "$uv tool run --default-index http://127.0.0.1:8766/simple --refresh $pkg@latest"
"B 段期望：[poc] module= 指向 uv 缓存里的 site-packages，hey.txt 落地"

# ---------- C：回归对照，主包在真实 PyPI 上可解析（证明名字差异是真的） ----------
$env:UV_CACHE_DIR = Join-Path $Out ".cacheC"
$env:UV_TOOL_BIN_DIR = Join-Path $Out ".bin"
Shot "C-main-package-exists" "$uv tool install --force crowdsentinel-mcp-server"
Shot "C-main-entrypoint" "& (Join-Path $env:UV_TOOL_BIN_DIR 'crowdsentinel-mcp-server.exe') --help"
"C 段期望：主包安装成功、自带 --transport/--host/--port，说明 es9 那个名字不是它的别名"

Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue

"===== hey.txt ====="
Get-Content (Join-Path $Out "hey.txt") -ErrorAction SilentlyContinue
"`n证据目录: $Out"
