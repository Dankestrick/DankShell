#!/usr/bin/env python3
"""List installed Omarchy plugins for DankShell's Plugins window. Prints JSON:
[{"id", "name", "kinds", "enabled", "active", "firstParty", "description", "version"}]
State comes from `omarchy plugin list --json`; description and version from
each plugin's manifest.json."""
import json, os, subprocess
from pathlib import Path

HOME = Path.home()
DIRS = [HOME / ".config/omarchy/plugins",
        Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "shell/plugins"]

manifests = {}
for root in DIRS:
    if not root.is_dir():
        continue
    for m in root.glob("*/manifest.json"):
        try:
            d = json.loads(m.read_text())
        except (OSError, ValueError):
            continue
        if isinstance(d, dict) and d.get("id") and d["id"] not in manifests:
            manifests[d["id"]] = d

try:
    out = subprocess.run(["omarchy", "plugin", "list", "--json"], capture_output=True, text=True, timeout=20).stdout
    plugins = json.loads(out)
except (OSError, ValueError, subprocess.SubprocessError):
    plugins = []

result = []
for p in plugins if isinstance(plugins, list) else []:
    m = manifests.get(p.get("id"), {})
    result.append({
        "id": p.get("id", ""), "name": p.get("name", ""), "kinds": p.get("kinds", []),
        "enabled": bool(p.get("enabled")), "active": bool(p.get("active")),
        "firstParty": bool(p.get("firstParty")),
        "description": str(m.get("description", ""))[:300], "version": str(m.get("version", "")),
    })
print(json.dumps(result))
