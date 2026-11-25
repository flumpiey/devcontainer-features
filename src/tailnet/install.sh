#!/usr/bin/env bash
# src/tailnet/install.sh
set -euo pipefail

DEFAULT_TAGS=tag:devcontainer
DEFAULT_AUTH_KEY_VAR=TS_AUTH_KEY

SHARE_DIR=/usr/local/share/tailnet

# fail <exit code> <message>
fail() {
  echo "tailnet: error: $2" >&2
  exit "$1"
}

HOSTNAMEPREFIX="${HOSTNAMEPREFIX:-}"
TAGS="${TAGS:-$DEFAULT_TAGS}"
AUTHKEYVAR="${AUTHKEYVAR:-$DEFAULT_AUTH_KEY_VAR}"
SSH="${SSH:-true}"

# Read os-release in a subshell so its variables do not leak into this script.
os_field() { (
  # shellcheck source=/dev/null
  . /etc/os-release
  printf '%s' "${!1:-}"
); }

# FR-020: the base check and the option checks come before any write.
os_id="$(os_field ID)"
os_version_id="$(os_field VERSION_ID)"
arch="$(uname -m)"
case "$os_id:$os_version_id:$arch" in
debian:12:x86_64 | ubuntu:22.04:x86_64 | ubuntu:24.04:x86_64) ;;
*) fail 1 "unsupported base ${os_id:-unknown} ${os_version_id:-unknown} on $arch; need Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on x86_64" ;;
esac

# FR-029: the values are written to a file that the entrypoint sources, so each one is limited to a safe character set.
HOSTNAMEPREFIX="${HOSTNAMEPREFIX,,}"
[[ "$HOSTNAMEPREFIX" =~ ^[a-z0-9-]*$ ]] ||
  fail 1 "hostnamePrefix may hold only letters, digits and hyphens, got '$HOSTNAMEPREFIX'"
[[ "$TAGS" =~ ^tag:[a-z0-9-]+(,tag:[a-z0-9-]+)*$ ]] ||
  fail 1 "tags must be one or more of tag:name separated by commas, got '$TAGS'"
[[ "$AUTHKEYVAR" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] ||
  fail 1 "authKeyVar must be an environment variable name, got '$AUTHKEYVAR'"
[[ "$SSH" == true || "$SSH" == false ]] ||
  fail 1 "ssh must be true or false, got '$SSH'"

# FR-003: the file holds names and settings only. The auth key is read at container start.
install -d -o root -g root -m 0755 "$SHARE_DIR"
umask 022
cat >"$SHARE_DIR/options.env" <<EOF
HOSTNAME_PREFIX_OPT=$HOSTNAMEPREFIX
TAGS=$TAGS
AUTH_KEY_VAR=$AUTHKEYVAR
SSH=$SSH
EOF
chmod 0644 "$SHARE_DIR/options.env"

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 0755 -o root -g root "$SRC_DIR/entrypoint.sh" "$SHARE_DIR/entrypoint.sh"
