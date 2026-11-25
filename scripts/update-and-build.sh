#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd -- "$repo_root"

if [[ $(git branch --show-current) != master ]]; then
  printf '%s\n' 'Switch to master before running this script.' >&2
  exit 1
fi

tracked_changes=$(git status --porcelain --untracked-files=no)
if [[ -n $tracked_changes ]]; then
  printf '%s\n' 'Commit or stash tracked changes before running this script.' >&2
  exit 1
fi

git fetch --no-recurse-submodules origin master
fork_head=$(git rev-parse --verify refs/remotes/origin/master)
if ! git merge-base --is-ancestor "$fork_head" HEAD; then
  printf '%s\n' 'Integrate the commits from origin/master before running this script.' >&2
  exit 1
fi

git fetch --no-recurse-submodules upstream master
git rebase upstream/master
git push --force-with-lease="refs/heads/master:$fork_head" origin HEAD:refs/heads/master

git submodule update --init --recursive

configure_args=(-S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo)
if [[ ! -f build/CMakeCache.txt && $(uname -s) == Darwin ]] &&
   ! printf '#include <climits>\n' | xcrun --sdk macosx clang++ -x c++ -fsyntax-only - >/dev/null 2>&1; then
  sdk_path=$(xcrun --sdk macosx --show-sdk-path)
  sdk_flags="-nostdinc++ -isystem \"$sdk_path/usr/include/c++/v1\""
  configure_args+=("-DCMAKE_OSX_SYSROOT=$sdk_path" "-DCMAKE_CXX_FLAGS=$sdk_flags" "-DCMAKE_OBJCXX_FLAGS=$sdk_flags")
fi

cmake "${configure_args[@]}"
cmake --build build --target Gothic2Notr --parallel "${OPENGOTHIC_BUILD_JOBS:-8}"
