#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
export XDG_DATA_HOME="$PWD/.tools/runtime/data"
export XDG_CONFIG_HOME="$PWD/.tools/runtime/config"
export XDG_CACHE_HOME="$PWD/.tools/runtime/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec .tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 "$@"
