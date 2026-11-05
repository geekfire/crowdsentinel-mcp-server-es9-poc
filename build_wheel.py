"""离线手搓 wheel：不依赖 hatchling、不需要网络。

只用于本地验证（verify.ps1）。真正发 PyPI 时用 `uv build` 走正常后端，
产物内容与此等价，但带上 hatchling 生成的 RECORD 明细。
"""
from __future__ import annotations

import base64
import hashlib
import pathlib
import shutil
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent
DIST = ROOT / "dist"
NAME = "crowdsentinel_mcp_server_es9"
DISTNAME = "crowdsentinel-mcp-server-es9"
VERSION = "0.9.0"

SRC = ROOT / "src" / NAME

FILES = {
    f"{NAME}/__init__.py": (SRC / "__init__.py").read_bytes(),
    f"{NAME}/server.py": (SRC / "server.py").read_bytes(),
    f"{NAME}-{VERSION}.dist-info/METADATA": (
        "Metadata-Version: 2.1\n"
        f"Name: {DISTNAME}\n"
        f"Version: {VERSION}\n"
        "Summary: Security research PoC for an unclaimed PyPI name\n"
        "Requires-Python: >=3.10\n"
    ).encode(),
    f"{NAME}-{VERSION}.dist-info/WHEEL": (
        "Wheel-Version: 1.0\nGenerator: poc-builder\nRoot-Is-Purelib: true\nTag: py3-none-any\n"
    ).encode(),
    f"{NAME}-{VERSION}.dist-info/entry_points.txt": (
        f"[console_scripts]\n{DISTNAME} = {NAME}.server:main\n"
    ).encode(),
}


def main() -> int:
    shutil.rmtree(DIST, ignore_errors=True)
    DIST.mkdir(parents=True)
    out = DIST / f"{NAME}-{VERSION}-py3-none-any.whl"

    records = []
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for path, body in FILES.items():
            z.writestr(path, body)
            digest = base64.urlsafe_b64encode(hashlib.sha256(body).digest()).rstrip(b"=").decode()
            records.append(f"{path},sha256={digest},{len(body)}")
        records.append(f"{NAME}-{VERSION}.dist-info/RECORD,,")
        z.writestr(f"{NAME}-{VERSION}.dist-info/RECORD", "\n".join(records) + "\n")

    print(out)
    print(hashlib.sha256(out.read_bytes()).hexdigest(), " sha256")
    return 0


if __name__ == "__main__":
    sys.exit(main())
