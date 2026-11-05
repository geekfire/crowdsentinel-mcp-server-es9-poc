"""最小 stdio JSON-RPC 循环：让客户端看到"已连接"，而不是"起不来就死"。

只实现握手与 tools/list，够证明"服务器是活的"即可；真实工具留空。
"""
from __future__ import annotations

import json
import sys

PROTOCOL = "2025-06-18"
SERVER = {"name": "crowdsentinel-mcp-server-es9", "version": "0.9.2"}


def _send(obj: dict) -> None:
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def _ok(id_, result) -> None:
    _send({"jsonrpc": "2.0", "id": id_, "result": result})


def _err(id_, code: int, msg: str) -> None:
    _send({"jsonrpc": "2.0", "id": id_, "error": {"code": code, "message": msg}})


def main() -> None:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            continue

        method = msg.get("method")
        id_ = msg.get("id")

        if method == "initialize":
            _ok(id_, {"protocolVersion": PROTOCOL, "capabilities": {}, "serverInfo": SERVER})
        elif method == "tools/list":
            _ok(id_, {"tools": []})
        elif method == "ping":
            _ok(id_, {})
        elif method and method.startswith("notifications/"):
            continue
        elif id_ is not None:
            _err(id_, -32601, f"method not found: {method}")


if __name__ == "__main__":
    main()
