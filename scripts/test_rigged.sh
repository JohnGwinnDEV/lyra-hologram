#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
python3 -m unittest discover -s tests -v
for suite in test_rigged_preview test_portrait; do
    timeout 30s bash scripts/godot.sh --headless --path avatar --script "res://tests/$suite.gd"
done
