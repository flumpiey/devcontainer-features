#!/usr/bin/env bash
set -euo pipefail
# test/ts7-cli/build-fails.sh
# Host-side test: each build must fail with the expected message. Run through scripts/verify.sh.
: "${DEVCONTAINER_CLI_VERSION:?run this through scripts/verify.sh}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE=mcr.microsoft.com/devcontainers/base:bookworm
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
status=0
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

# expect_fail <name> <image> <options JSON> <message regex>
expect_fail() {
  local name="$1" image="$2" options="$3" pattern="$4"
  local dir="$work/$name" out rc=0
  mkdir -p "$dir/.devcontainer"
  cp -r "$ROOT/src/ts7-cli" "$dir/.devcontainer/ts7-cli"
  jq -n --arg image "$image" --argjson options "$options" \
    '{image: $image, features: {"./ts7-cli": $options}}' \
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

# AC7, FR-020: an unsupported base names the OS and the supported bases. The Node Feature installs first and fails on a raw debian:11 image, so the test uses the Dev Container bullseye image.
expect_fail old_base mcr.microsoft.com/devcontainers/base:bullseye '{}' 'ts7-cli: error: unsupported base debian 11.*Debian 12, Ubuntu 22[.]04 or Ubuntu 24[.]04'
# FR-029: a bad version fails with one line.
expect_fail bad_version "$IMAGE" '{"version": "7"}' "ts7-cli: error: version must be 'latest' or look like"

exit "$status"
