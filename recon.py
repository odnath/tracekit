mkdir -p modules output tests
touch modules/__init__.py

cat > recon.py << 'EOF'
#!/usr/bin/env python3
"""recon-toolkit: menu-driven recon for authorized targets and CTF labs."""

import sys
from pathlib import Path

from modules import deps, domain, files
from modules.scope import require_authorization, load_scope, check_target

BANNER = """
recon-toolkit
For authorized testing, bug bounty in-scope targets, and CTF labs only.
"""

MENU = """
  [4] Domain      subfinder, assetfinder, dnsx, httpx, wafw00f, testssl.sh
  [5] File        file, exiftool, pdfinfo, strings, zsteg, steghide
  [9] Check tools which tools are installed and how to install them
  [0] Exit
"""


def main() -> int:
    print(BANNER)
    require_authorization()
    scope = load_scope(Path("scope.txt"))

    while True:
        print(MENU)
        choice = input("> ").strip()

        if choice == "4":
            target = input("Domain (must be in scope.txt): ").strip()
            if check_target(target, scope):
                domain.run(target)
        elif choice == "5":
            path = input("Path to file: ").strip()
            files.run(Path(path))
        elif choice == "9":
            deps.report()
        elif choice == "0":
            return 0
        else:
            print("Unknown option.")


if __name__ == "__main__":
    sys.exit(main())
EOF

cat > modules/scope.py << 'EOF'
"""Authorization prompt and scope checks. Every scan goes through here."""

import ipaddress
import logging
from datetime import datetime, timezone
from pathlib import Path

LOG_FILE = Path("recon-toolkit.log")

NOTICE = """\
This tool is for targets you own or are explicitly authorized to test,
bug bounty programs where the target is in scope, and CTF/lab environments.
Unauthorized scanning is illegal in most jurisdictions.
"""


def _log(message: str) -> None:
    logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(message)s")
    logging.info("%s %s", datetime.now(timezone.utc).isoformat(), message)


def require_authorization() -> None:
    print(NOTICE)
    answer = input("Type 'I AGREE' to continue: ").strip()
    if answer != "I AGREE":
        raise SystemExit("Authorization not confirmed. Exiting.")
    _log("authorization accepted")


def load_scope(path: Path) -> set[str]:
    if not path.exists():
        raise SystemExit(f"Missing {path}. Add your authorized targets first.")
    entries = set()
    for line in path.read_text().splitlines():
        line = line.strip().lower()
        if line and not line.startswith("#"):
            entries.add(line)
    if not entries:
        raise SystemExit(f"{path} is empty. Add at least one authorized target.")
    return entries


def check_target(target: str, scope: set[str]) -> bool:
    """Allow a target only if it or a parent domain is listed in scope.txt."""
    target = target.strip().lower()
    if not target:
        print("No target given.")
        return False

    try:
        ipaddress.ip_address(target)
        allowed = target in scope
    except ValueError:
