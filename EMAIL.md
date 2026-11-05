Subject: [Security] Unclaimed PyPI names in your MCP docs — `crowdsentinel-mcp-server-es9` / `-es9` (dependency confusion, PoC included)

To: medjed@crowdsentinel.io
Cc: (repo issue / GitHub Security Advisory if enabled)

Hi,

I'm a security researcher. Short version: two install commands your README tells users to run point at PyPI names that have never been registered. Anyone can claim them, and today `uvx` resolves nothing there.

## What the docs say

`github.com/thomasxm/CrowdSentinels-AI-MCP` → README, "Run directly with uvx (no install needed)":

```bash
uvx crowdsentinel-mcp-server        # exists on PyPI, 37 releases, author medjed@crowdsentinel.io
uvx crowdsentinel-mcp-server-es9    # Elasticsearch 9.x  -> 404
uvx crowdsentinel-mcp-server-es9    # Elasticsearch 9.x  -> 404
```

`-es9` and `-es9` have never been published. Verified just now:

```
$ curl -sS -o /dev/null -w "%{http_code}\n" https://pypi.org/pypi/crowdsentinel-mcp-server-es9/json
404
$ uv tool run --refresh crowdsentinel-mcp-server-es9@latest
error: No solution found when resolving tool dependencies
  cause: Because crowdsentinel-mcp-server-es9 was not found in the package registry ... unsatisfiable
```

## Why it matters

`uvx` does not read your repository — it resolves the normalized name on the configured index and runs whatever console entry point it exposes. The name string in your docs is the only software identity involved: no URL, no commit, no hash, no lockfile.

So there are two problems at once:

1. **Today:** copy-pasting line 2 or 3 fails for every user, while line 1 works — easy to read as "their build is broken".
2. **As soon as someone registers the name:** code chosen by the registry runs inside the client, at import time, before any MCP handshake, with the developer's environment — including whatever `env` block the user configured (`ES_API_KEY` in the snippet above).

## Proof of concept

I published a harmless placeholder under `crowdsentinel-mcp-server-es9` (v0.9.0, no network calls, no file writes outside `%TEMP%\hey.txt`, source public). Three-shot reproduction, all logged:

| # | Command | Result |
|---|---|---|
| A | `uvx crowdsentinel-mcp-server-es9@latest` (real PyPI) | unsatisfiable — name unclaimed |
| B | same, with the name served from a local index | `[poc] module = ...\site-packages\crowdsentinel_mcp_server_es9\__init__.py`, `%TEMP%\hey.txt` written |
| C | `uvx crowdsentinel-mcp-server` | installs fine, exposes `--transport/--host/--port` — proves `-es9` is not an alias of the main package |

The `[poc] module=` line is the whole point: it resolves to a cache `site-packages` path, not to a checkout of your repo. A real attacker's package would behave identically, plus do whatever it wants.

Recorded output and the package source are attached / linked below.

## Suggested fix

- Reserve both names under the project, then either publish the variants there or drop the `uvx` lines and use `uvx --from crowdsentinel-mcp-server crowdsentinel-mcp-server-es9` so the distribution name is explicit
- For anything install-facing, pin a version instead of floating `@latest`
- Optional but cheap: a CI check that issues a GET against `https://pypi.org/pypi/<name>/json` for every name that appears in docs

## CVE / disclosure

`crowdsentinel-mcp-server-es9` is in a public repository and the defect is in a shipped documentation artifact, so this fits the dependency-confusion pattern that has already received CVE IDs through GitHub's CNA (e.g. CVE-2025-61774 for PyVista, CVE-2026-54232 for vLLM — both "unregistered package name in repo artifact").

If you're willing: open a GitHub Security Advisory on `thomasxm/CrowdSentinels-AI-MCP` and publish it once fixed — that gets a GHSA + CVE with your fix version attached. I'll supply the advisory text and the affected-version range; happy to keep it private until you ship.

## Ownership transfer

Name is yours whenever you want it: add `@mcpsec-lab` as collaborator on the PyPI project, or just say the word and I'll `uv publish` a release with your metadata and hand over the owner. Nothing is pinned to me.

Timeline proposal: 90 days from this mail, then public write-up either way. I'll keep the placeholder online and working for as long as it's useful to you.

Thanks — and nice work on the main server, the es9/ES9 split is a genuinely good idea.

Best,
<YOUR NAME> (@mcpsec-lab)
<YOUR SITE / H1 PROFILE>
