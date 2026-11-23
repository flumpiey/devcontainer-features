#!/usr/bin/env bash
# src/orca-server/install.sh
set -euo pipefail

DEFAULT_VERSION=1.4.271
DEFAULT_DEB_SHA256=7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755

SHARE_DIR=/usr/local/share/orca-server
DATA_DIR=/var/lib/orca-server
REPO=stablyai/orca

# fail <exit code> <message>
fail() {
  echo "orca-server: error: $2" >&2
  exit "$1"
}

VERSION="${VERSION:-$DEFAULT_VERSION}"
PAIRINGADDRESS="${PAIRINGADDRESS:-}"
PORT="${PORT:-6768}"
MOBILEPAIRING="${MOBILEPAIRING:-true}"
AUTOSTART="${AUTOSTART:-true}"
TAILSCALEWAITSECONDS="${TAILSCALEWAITSECONDS:-120}"
DEBSHA256="${DEBSHA256:-$DEFAULT_DEB_SHA256}"
REMOTE_USER="${_REMOTE_USER:-}"

# Read os-release in a subshell: it defines VERSION, which is also an option name.
os_field() { (
  # shellcheck source=/dev/null
  . /etc/os-release
  printf '%s' "${!1:-}"
); }

# FR-004: supported bases.
os_id="$(os_field ID)"
os_version_id="$(os_field VERSION_ID)"
arch="$(uname -m)"
case "$os_id:$os_version_id:$arch" in
debian:12:x86_64 | ubuntu:22.04:x86_64 | ubuntu:24.04:x86_64) ;;
*) fail 1 "unsupported base ${os_id:-unknown} ${os_version_id:-unknown} on $arch; need Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on x86_64" ;;
esac

# FR-028: option values. They are written to a file that the scripts source, so
# every value is restricted to a safe character set.
if ! [[ "$PORT" =~ ^[0-9]{1,5}$ ]] || ((10#$PORT < 1 || 10#$PORT > 65535)); then
  fail 1 "port must be an integer from 1 to 65535, got '$PORT'"
fi
PORT=$((10#$PORT))
[[ "$TAILSCALEWAITSECONDS" =~ ^[0-9]{1,9}$ ]] ||
  fail 1 "tailscaleWaitSeconds must be a non-negative integer, got '$TAILSCALEWAITSECONDS'"
TAILSCALEWAITSECONDS=$((10#$TAILSCALEWAITSECONDS))
[[ "$VERSION" == latest || "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail 1 "version must be 'latest' or look like 1.4.271, got '$VERSION'"
[[ "$PAIRINGADDRESS" =~ ^[A-Za-z0-9._:-]*$ ]] ||
  fail 1 "pairingAddress may hold only letters, digits and . _ : -, got '$PAIRINGADDRESS'"
[[ "$MOBILEPAIRING" == true || "$MOBILEPAIRING" == false ]] ||
  fail 1 "mobilePairing must be true or false, got '$MOBILEPAIRING'"
[[ "$AUTOSTART" == true || "$AUTOSTART" == false ]] ||
  fail 1 "autoStart must be true or false, got '$AUTOSTART'"
DEBSHA256="${DEBSHA256,,}"
[[ "$DEBSHA256" =~ ^[0-9a-f]{64}$ ]] ||
  fail 1 "debSha256 must be 64 hex digits, got '$DEBSHA256'"

# FR-014: Orca must not run as root.
if [ -z "$REMOTE_USER" ] || [ "$REMOTE_USER" = root ]; then
  fail 1 "remoteUser must be a non-root user, got '${REMOTE_USER:-empty}'"
fi
id -u "$REMOTE_USER" >/dev/null 2>&1 || fail 1 "remote user '$REMOTE_USER' does not exist in the image"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates jq

# FR-003: resolve the release.
ORCA_VERSION="$VERSION"
if [ "$VERSION" = latest ]; then
  api="https://api.github.com/repos/$REPO/releases/latest"
  tag="$(curl --fail --silent --show-error --location --retry 3 "$api" | jq -r '.tag_name')" ||
    fail 2 "cannot resolve the latest Orca release from $api"
  ORCA_VERSION="${tag#v}"
  [[ "$ORCA_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    fail 2 "latest Orca release has an unexpected tag '$tag'"
fi

installed="$(dpkg-query -W -f='${Version}' orca-ide 2>/dev/null || true)"
if [ "$installed" = "$ORCA_VERSION" ]; then
  echo "orca-server: orca-ide $ORCA_VERSION already installed"
else
  asset="orca-ide_${ORCA_VERSION}_amd64.deb"
  url="https://github.com/$REPO/releases/download/v$ORCA_VERSION/$asset"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  deb="$tmp_dir/$asset"

  # FR-005
  rc=0
  code="$(curl --fail --location --retry 3 --silent --show-error --output "$deb" --write-out '%{http_code}' "$url")" || rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$code" = 404 ]; then
      fail 2 "no .deb asset for tag v$ORCA_VERSION; tried $url"
    fi
    fail 2 "download of $url failed (curl exit $rc, HTTP $code)"
  fi

  # FR-024, Decision 20: a changed debSha256 is used as is. Another version with the
  # default hash takes the digest from the release API.
  expected="$DEBSHA256"
  if [ "$ORCA_VERSION" != "$DEFAULT_VERSION" ] && [ "$DEBSHA256" = "$DEFAULT_DEB_SHA256" ]; then
    api="https://api.github.com/repos/$REPO/releases/tags/v$ORCA_VERSION"
    digest="$(curl --fail --silent --show-error --location --retry 3 "$api" |
      jq -r --arg name "$asset" '[.assets[] | select(.name == $name) | .digest // empty] | first // empty')" ||
      fail 3 "cannot read the release digest from $api"
    expected="${digest#sha256:}"
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] ||
      fail 3 "release v$ORCA_VERSION gives no sha256 digest for $asset"
  fi
  actual="$(sha256sum "$deb" | cut -d' ' -f1)"
  [ "$actual" = "$expected" ] ||
    fail 3 "sha256 mismatch for $asset: expected $expected, actual $actual"

  # FR-002, FR-006: apt resolves the dependencies the .deb declares. It upgrades in place.
  apt-get install -y --no-install-recommends "$deb"
fi

# FR-022: write no pairing link and start no Orca here.
mkdir -p "$SHARE_DIR"
cat >"$SHARE_DIR/options.env" <<EOF
VERSION=$VERSION
PAIRING_ADDRESS=$PAIRINGADDRESS
PORT=$PORT
MOBILE_PAIRING=$MOBILEPAIRING
AUTO_START=$AUTOSTART
TAILSCALE_WAIT_SECONDS=$TAILSCALEWAITSECONDS
DEB_SHA256=$DEBSHA256
EOF
printf '%s\n' "$REMOTE_USER" >"$SHARE_DIR/remote-user"
chmod 0644 "$SHARE_DIR/options.env" "$SHARE_DIR/remote-user"

# FR-015, Decision 18: a new named volume inherits this owner and mode.
install -d -o "$REMOTE_USER" -g "$(id -gn "$REMOTE_USER")" -m 0700 "$DATA_DIR"

rm -rf /var/lib/apt/lists/*
