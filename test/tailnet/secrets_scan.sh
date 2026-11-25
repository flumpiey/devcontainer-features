#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/secrets_scan.sh
# Host-side test (AC3, FR-027): a build with a canary key in the host environment leaves no key in the image.
: "${DEVCONTAINER_CLI_VERSION:?run this through scripts/verify.sh}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_NAME=tailnet-secrets-scan:test
CANARY=tskey-auth-CANARY0000000000
work="$(mktemp -d)"
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
trap 'rm -rf "$work"; docker rmi -f "$IMAGE_NAME" >/dev/null 2>&1 || true' EXIT

# The key is in the host environment for the build and the scan. The Feature must not read it.
export TS_AUTH_KEY="$CANARY"

mkdir -p "$work/.devcontainer"
cp -r "$ROOT/src/tailnet" "$work/.devcontainer/tailnet"
jq -n '{image: "mcr.microsoft.com/devcontainers/base:bookworm", features: {"./tailnet": {}}}' \
  >"$work/.devcontainer/devcontainer.json"
npx --yes "@devcontainers/cli@$DEVCONTAINER_CLI_VERSION" build --workspace-folder "$(native "$work")" --image-name "$IMAGE_NAME"

# scan <file>: succeeds when the file holds the canary or the key prefix.
scan() { grep -Eqi -- "$CANARY|tskey-" "$1"; }

{
  docker history --no-trunc "$IMAGE_NAME"
  docker inspect "$IMAGE_NAME"
  # MSYS_NO_PATHCONV stops Git Bash on Windows from rewriting the container paths.
  MSYS_NO_PATHCONV=1 docker run --rm --entrypoint sh "$IMAGE_NAME" -c \
    'cat /usr/local/share/tailnet/options.env; grep -rIl -e tskey- /etc /usr/local /var /root /home /opt 2>/dev/null || true'
} >"$work/scan.txt"

if scan "$work/scan.txt"; then
  echo "FAIL: an auth key is in the image" >&2
  grep -Ein -- "$CANARY|tskey-" "$work/scan.txt" >&2
  exit 1
fi
echo "ok   no auth key in the image"

# FR-027: the scan must detect a key when one is there.
echo "TS_AUTH_KEY=$CANARY" >"$work/planted.txt"
if ! scan "$work/planted.txt"; then
  echo "FAIL: the scan did not detect a planted canary" >&2
  exit 1
fi
echo "ok   the scan detects a planted canary"
