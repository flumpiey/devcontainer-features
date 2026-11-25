#!/usr/bin/env bash
# src/ts7-cli/install.sh
set -euo pipefail

DEFAULT_VERSION=7.0.2

PREFIX=/usr/local/share/ts7-cli
LINK=/usr/local/bin/tsc7
NVM_BIN=/usr/local/share/nvm/current/bin

# fail <exit code> <message>
fail() {
  echo "ts7-cli: error: $2" >&2
  exit "$1"
}

VERSION="${VERSION:-$DEFAULT_VERSION}"

# Read os-release in a subshell: it defines VERSION, which is also an option name.
os_field() { (
  # shellcheck source=/dev/null
  . /etc/os-release
  printf '%s' "${!1:-}"
); }

# FR-020: the base check and the option check come before any write.
os_id="$(os_field ID)"
os_version_id="$(os_field VERSION_ID)"
arch="$(uname -m)"
case "$os_id:$os_version_id:$arch" in
debian:12:x86_64 | ubuntu:22.04:x86_64 | ubuntu:24.04:x86_64) ;;
*) fail 1 "unsupported base ${os_id:-unknown} ${os_version_id:-unknown} on $arch; need Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on x86_64" ;;
esac

# FR-029: the value is used in an npm package spec.
[[ "$VERSION" == latest || "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]] ||
  fail 1 "version must be 'latest' or look like 7.0.2, got '$VERSION'"

# The Node Feature installs first (dependsOn). Its bin directory is not on PATH while the image builds.
if [ -d "$NVM_BIN" ]; then PATH="$NVM_BIN:$PATH"; fi
command -v npm >/dev/null || fail 2 "npm not found; the node Feature must install before ts7-cli"

# FR-015: a new version replaces the old one. No file of the old install stays.
cache_dir="$(mktemp -d)"
trap 'rm -rf "$cache_dir"' EXIT
rm -rf "$PREFIX"
npm install --prefix "$PREFIX" --cache "$cache_dir" --ignore-scripts --no-audit --no-fund "typescript@$VERSION" ||
  fail 2 "npm install of typescript@$VERSION failed"

# FR-016, FR-018: the CLI is tsc7. Nothing named tsc goes on PATH.
ln -sf "$PREFIX/node_modules/.bin/tsc" "$LINK"
echo "ts7-cli: installed typescript $(node -p "require('$PREFIX/node_modules/typescript/package.json').version") as $LINK"
