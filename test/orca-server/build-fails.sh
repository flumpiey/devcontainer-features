#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/build-fails.sh
# Host-side test: each build must fail with the expected message. Run through scripts/verify.sh.
: "${DEVCONTAINER_CLI_VERSION:?run this through scripts/verify.sh}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE=mcr.microsoft.com/devcontainers/base:bookworm
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
status=0
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

# expect_fail <name> <image> <remoteUser or empty> <options JSON> <message regex>
expect_fail() {
  local name="$1" image="$2" user="$3" options="$4" pattern="$5"
  local dir="$work/$name" out rc=0
  mkdir -p "$dir/.devcontainer"
  cp -r "$ROOT/src/orca-server" "$dir/.devcontainer/orca-server"
  jq -n --arg image "$image" --arg user "$user" --argjson options "$options" \
    '{image: $image, features: {"./orca-server": $options}} + (if $user != "" then {remoteUser: $user} else {} end)' \
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

# AC10: a version with no .deb asset names the tag.
expect_fail no_asset "$IMAGE" "" '{"version": "0.0.1"}' 'no \.deb asset for tag v0\.0\.1'
# AC15: a wrong hash names both hashes.
expect_fail bad_hash "$IMAGE" "" '{"debSha256": "0000000000000000000000000000000000000000000000000000000000000000"}' \
  'sha256 mismatch for orca-ide_1\.4\.271_amd64\.deb: expected 0{64}, actual [0-9a-f]{64}'
# FR-004: an unsupported base names the OS.
expect_fail old_base debian:11 "" '{}' 'unsupported base debian 11'
# FR-014: a root remote user is refused.
expect_fail root_user "$IMAGE" root '{}' 'remoteUser must be a non-root user'
# FR-028: bad option values fail with one line. The address filter also guards options.env, which is sourced.
expect_fail bad_port "$IMAGE" "" '{"port": "99999"}' 'port must be an integer from 1 to 65535'
expect_fail bad_wait "$IMAGE" "" '{"tailscaleWaitSeconds": "-1"}' 'tailscaleWaitSeconds must be a non-negative integer'
expect_fail bad_version "$IMAGE" "" '{"version": "1.4"}' "version must be 'latest' or look like"
expect_fail bad_address "$IMAGE" "" '{"pairingAddress": "a;b"}' 'pairingAddress may hold only'

exit "$status"
