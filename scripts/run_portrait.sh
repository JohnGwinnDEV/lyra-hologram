#!/usr/bin/env bash
set -euo pipefail
exec bash "$(dirname -- "$0")/godot.sh" --path avatar res://scenes/portrait.tscn "$@"
