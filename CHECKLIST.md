# 上线清单

按顺序打勾。**第 1 步是硬阻塞**，没它后面全做不了。

## 0. 先把占位符换掉

- [ ] `pyproject.toml`：`mcpsec-lab`、GitHub URL
- [ ] `README.md`：`@mcpsec-lab`
- [ ] `EMAIL.md`：`<YOUR NAME>` `@mcpsec-lab` `<YOUR SITE>`

## 1. 账号（只有你能做）

- [ ] pypi.org 注册
- [ ] **开 2FA**（PyPI 强制，且转 ownership 需要）
- [ ] 用户名记下来，填进 README 的移交段

## 2. 动手前最后复查

- [ ] `curl -s -o NUL -w "%{http_code}" https://pypi.org/pypi/crowdsentinel-mcp-server-es9/json` → 必须还是 404
- [ ] 顺手查 `-es9`：还在，就一起占了（成对维护，别只占一个）

## 3. 构建

```powershell
pwsh -File .\verify.ps1          # 本地三段全绿再往下走
uv build                          # 或 python -m build
```

- [ ] 三段日志都在 `evidence\`
- [ ] wheel sha256 记进备忘录（披露时要给）
- [ ] 推公开 GitHub 仓库（**先推再发 PyPI**，PyPI 项目页要填源码地址）

## 4. 发布

```powershell
uv publish                        # 或 twine upload dist/*
```

- [ ] 上传后立刻验：`uvx crowdsentinel-mcp-server-es9@latest` 能跑出 `[poc]`
- [ ] 项目页填 Homepage = 你的仓库，Description 带 "security research PoC"
- [ ] 同样处理 `-es9`（复用同一份骨架，改名字与 entry point）

## 5. 录屏（三段，一次过别剪）

- [ ] A：干净目录 + 空 `UV_CACHE_DIR`，跑 `uvx crowdsentinel-mcp-server-es9@latest` → 失败
- [ ] A2（可选但建议）：先录这段**在占名之前**，否则 A 段要拿本地索引伪造
- [ ] B：占名后同命令 → `[poc] module=` 指向 site-packages
- [ ] C：`uvx crowdsentinel-mcp-server` → 主包正常，说明不是别名
- [ ] 录屏里带上终端时间戳 / `date` 输出

> 顺序提醒：A 段最好**占名前**录，那是唯一能录到真 404 的时刻。已经占了就退而用本地空索引复现。

## 6. 通知（GitHub 为主，邮件为备）

> 2026-11-05 实测：`medjed@crowdsentinel.io` bounce，域名无 MX 且不解析。别把邮件当主渠道。

- [ ] 先在上游仓库开 issue，标题只写 "Two install commands in README point at unclaimed PyPI names"
- [ ] 正文 @ 维护者（`@thomasxm`），GitHub 会替他发通知信
- [ ] 再发一次邮件（`EMAIL.md` + `REPORT.zip`），**保存 NDR 原文**当已尽通知义务的证据
- [ ] 拿到 NDR 后，在 issue 里补一条渠道说明，并请他给一个能用的地址

## 7. 跟进

| 时间 | 动作 |
|---|---|
| +7 天 | 无回复 → 在 issue 里再 @ 一次，一句 "still open, any update?" |
| +30 天 | 仍无回复 → 提 MITRE cveform，附录屏与仓库链接 |
| +90 天 | 无论结果，公开写复盘 |

- [ ] 他们发了 GHSA → 补 advisory 文本、受影响版本区间（`<= 0.6.0` 之类），别让号挂在没有修复版本的状态
- [ ] 他们要名字 → 加 collaborator 或整包转交，转完在 README 上注明

## 别做的事

- 别一次占九条，只做 es9 / es9
- 别在包里加网络请求（评审者要一眼看完）
- 别改一版就换个版本号刷存在感，0.9.0 停着就行
- 别公开时间早于修复；名字被抢的风险低于打草惊蛇的成本
