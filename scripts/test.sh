#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
for suite in run_tests test_desktop; do
    bash scripts/godot.sh --headless --path avatar --script "res://tests/$suite.gd"
done
if [ -f avatar/assets/lyra/lyra-base.glb ]; then
    bash scripts/test_rigged.sh
else
    echo "SKIP: rigged asset tests; generate the local preview with bash scripts/build_rigged.sh"
fi
