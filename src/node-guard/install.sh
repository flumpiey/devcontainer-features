#!/usr/bin/env bash
# src/node-guard/install.sh
set -euo pipefail

# fail <exit code> <message>
fail() {
  echo "node-guard: error: $2" >&2
  exit "$1"
}

# Read os-release in a subshell so its variables do not leak into this script.
os_field() { (
  # shellcheck source=/dev/null
  . /etc/os-release
  printf '%s' "${!1:-}"
); }

# FR-020: the base check is the only work. The values come from containerEnv in devcontainer-feature.json.
os_id="$(os_field ID)"
os_version_id="$(os_field VERSION_ID)"
arch="$(uname -m)"
case "$os_id:$os_version_id:$arch" in
debian:12:x86_64 | ubuntu:22.04:x86_64 | ubuntu:24.04:x86_64) ;;
*) fail 1 "unsupported base ${os_id:-unknown} ${os_version_id:-unknown} on $arch; need Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on x86_64" ;;
esac
