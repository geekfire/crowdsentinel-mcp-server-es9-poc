# crowdsentinel-mcp-server-es9

> **SECURITY RESEARCH PoC — dependency-confusion placeholder package.**
> 用于证明 `CrowdSentinels-AI-MCP` 文档里已公开的 `uvx crowdsentinel-mcp-server-es9`
> 指向一个在 PyPI 上从未被注册的名字。维护者看这里即可接手（见文末"移交"）。

## 这是什么

`thomasxm/CrowdSentinels-AI-MCP` 的 README 并列给出了三条安装命令：

```
uvx crowdsentinel-mcp-server        # 主包，PyPI 上存在，作者 medjed@crowdsentinel.io
uvx crowdsentinel-mcp-server-es9    # Elasticsearch 9.x —— PyPI 上不存在
uvx crowdsentinel-mcp-server-es9    # Elasticsearch 9.x —— PyPI 上不存在
```

主包在 PyPI 上有 37 个版本，两个变体名字一直是空的。任何人在客户端里照抄第二、三行，
解析都会失败；一旦名字被人注册，跑的就是注册者上传的代码，而不是仓库里的源码。

## 会做什么（故意做得很少）

- import 期打印：模块真实路径、解释器、cwd、`~/.ssh` 存在性、敏感形 env 变量名（不打印值）
- 往 `%TEMP%\hey.txt` 写一行标记
- 之后起一个最小 stdio JSON-RPC 循环，回应 `initialize` / `tools/list` / `ping`
- **不发任何网络请求**、不改用户文件、不读凭据内容

## 本地验证

```powershell
pwsh -File .\verify.ps1
```

三段对照：真实 PyPI 上解析失败 → 本地索引命中并执行 → 主包可正常安装但名字不同。

## 移交

维护者若要接手，两种方式任选：

1. 在 PyPI 项目 Settings → Collaborators 里加 `@mcpsec-lab`，或
2. 直接在 GitHub issue / 邮件里说要，我用 `uv publish` 发一个新版本后把 owner 转过去

版本号停在 `0.9.2`：低于主包当前线，但远高于"不存在"，占位期不会被任何 pin 挡住。

上游：<https://github.com/thomasxm/CrowdSentinels-AI-MCP>
报告渠道：GitHub issue + @thomasxm（主）／`medjed@crowdsentinel.io`（域名已失效，仅作记录）
