#!/bin/bash

set -euo pipefail

python3 - <<'PY'
import json
from pathlib import Path

home = Path.home()
config_path = home / ".dotfiles/config/.playwright/cli.config.json"

config = (
    json.loads(config_path.read_text())
    if config_path.exists()
    else {}
)
config.setdefault("browser", {}).setdefault("contextOptions", {})[
    "storageState"
] = str(home / ".local/state/opencode/playwright/storage-state.json")

config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(json.dumps(config, indent=2) + "\n")
PY
