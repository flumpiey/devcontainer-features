#!/usr/bin/env bash
set -euo pipefail
# test/node-guard/build-fails.sh
# Host-side test: the build must fail with the expected message. Run through scripts/verify.sh.
: "${DEVCONTAINER_CLI_VERSION:?run this through scripts/verify.sh}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
status=0
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

# expect_fail <name> <image> <options JSON> <message regex>
expect_fail() {
  local name="$1" image="$2" options="$3" pattern="$4"
  local dir="$work/$name" out rc=0
  mkdir -p "$dir/.devcontainer"
  cp -r "$ROOT/src/node-guard" "$dir/.devcontainer/node-guard"
  jq -n --arg image "$image" --argjson options "$options" \
    '{image: $image, features: {"./node-guard": $options}}' \
    >"$dir/.devcontainer/devcontainer.json"
  out="$(npx --yes "@devcontainers/cli@$DEVCONTAINER_CLI_VERSION" build --workspace-folder "$(native "$dir")" 2>&1)" || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "FAIL $name: the build succeeded" >&2
    status=1
  elif grep -Eq -- "$pattern" <<<"$out"; then
    echo "ok   $name"
  else
    echo "FAIL $name: no message matching '$pattern'" >&2
    tail -n 15 <<<"$out" >&2
    status=1
  fi
}

# AC7, FR-020: an unsupported base names the OS and the supported bases.
expect_fail old_base debian:11 '{}' 'node-guard: error: unsupported base debian 11.*Debian 12, Ubuntu 22\.04 or Ubuntu 24\.04'

exit "$status"
