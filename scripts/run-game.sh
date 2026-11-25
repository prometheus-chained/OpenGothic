#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
game_dir="$repo_root/build/opengothic"

if [[ ! -x "$game_dir/Gothic2Notr" ]]; then
  printf 'Game executable not found: %s\n' "$game_dir/Gothic2Notr" >&2
  exit 1
fi

cd -- "$game_dir"
exec ./Gothic2Notr -g "$HOME/Library/Application Support/OpenGothic" "$@"
