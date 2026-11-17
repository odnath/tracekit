"""Run external tools with a timeout and capture output safely."""

import shutil
import subprocess


def run_tool(args: list[str], timeout: int = 300) -> str:
    if shutil.which(args[0]) is None:
        return f"[skipped] {args[0]} not installed"
    try:
        out = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return out.stdout
    except subprocess.TimeoutExpired:
        return f"[timeout] {args[0]} exceeded {timeout}s"
