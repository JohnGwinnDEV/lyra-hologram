#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
bash scripts/blender.sh --background --python-exit-code 1 --python scripts/build_lyra_base.py
bash scripts/godot.sh --headless --editor --path avatar --import
