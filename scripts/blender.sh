#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
export XDG_DATA_HOME="$PWD/.tools/authoring/user/data"
export XDG_CONFIG_HOME="$PWD/.tools/authoring/user/config"
export XDG_CACHE_HOME="$PWD/.tools/authoring/user/cache"
export BLENDER_USER_CONFIG="$PWD/.tools/authoring/user/blender/config"
export BLENDER_USER_SCRIPTS="$PWD/.tools/authoring/user/blender/scripts"
export BLENDER_USER_EXTENSIONS="$PWD/.tools/authoring/user/blender/extensions"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$BLENDER_USER_CONFIG" "$BLENDER_USER_SCRIPTS" "$BLENDER_USER_EXTENSIONS"
exec .tools/authoring/blender-4.5.15-linux-x64/blender "$@"
