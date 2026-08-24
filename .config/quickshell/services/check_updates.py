#!/usr/bin/env python3
"""Check Arch and AUR for available updates.

Emits a single JSON object for the bar widget:

    {
      "repos": [
        { "id", "name", "count", "pkgCount", "updateCmd", "installed" },
        ...
      ],
      "total": N
    }

Only the Arch (pacman) and AUR repos are emitted, matching what this bar
uses. pacman counts come from `checkupdates` (pacman-contrib); AUR counts
come from whichever helper is installed (yay / paru / checkupdates-aur).
"""

from __future__ import annotations

import json
import shutil
import subprocess
from typing import Any


def count_lines(command: list[str]) -> int:
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            return 0
        return len([line for line in result.stdout.strip().split("\n") if line.strip()])
    except Exception:
        return 0


def aur_helper() -> str | None:
    for helper in ("checkupdates-aur",):
        if shutil.which(helper):
            return helper
    for helper in ("yay", "paru"):
        if shutil.which(helper):
            return helper
    return None


def installed_pkg_names() -> set[str]:
    try:
        result = subprocess.run(["pacman", "-Qq"], capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            return set()
        return set(result.stdout.split())
    except Exception:
        return set()


def aur_pkg_count() -> int:
    return count_lines(["pacman", "-Qqm"])


def check_pacman() -> int:
    if shutil.which("checkupdates") is None:
        return 0
    return count_lines(["checkupdates"])


def check_aur(helper: str | None) -> int:
    if helper is None:
        return 0
    if helper == "checkupdates-aur":
        return count_lines([helper])
    return count_lines([helper, "-Qua"])


def aur_update_cmd(helper: str | None) -> str:
    if helper is None:
        return ""
    if helper == "checkupdates-aur":
        return f"{helper}; echo; read -n 1 -s -r -p 'Done. Press any key to close'"
    return f"{helper} -Sua; echo; read -n 1 -s -r -p 'Done. Press any key to close'"


def collect_repo(id: str, name: str, count: int, pkg_count: int, update_cmd: str, installed: bool) -> dict[str, Any]:
    return {
        "id": id,
        "name": name,
        "count": count,
        "pkgCount": pkg_count,
        "updateCmd": update_cmd,
        "installed": installed,
    }


def main() -> int:
    helper = aur_helper()
    pacman_count = check_pacman()
    aur_count = check_aur(helper)

    installed = installed_pkg_names()
    pacman_pkgs = len(installed)
    aur_pkgs = aur_pkg_count() if helper is not None else 0

    repos = [
        collect_repo("pacman", "Arch", pacman_count, pacman_pkgs,
            "sudo pacman -Syu; echo; read -n 1 -s -r -p 'Done. Press any key to close'",
            True),
        collect_repo("aur", "AUR", aur_count, aur_pkgs,
            aur_update_cmd(helper),
            helper is not None),
    ]

    total = pacman_count + aur_count

    print(json.dumps({"repos": repos, "total": total}, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
