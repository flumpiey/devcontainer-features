#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/secrets_scan.sh
# Host-side test (FR-022): a default build leaves no pairing link or Tailscale key in the image.
: "${DEVCONTAINER_CLI_VERSION:?run this through scripts/verify.sh}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_NAME=orca-server-secrets-scan:test
work="$(mktemp -d)"
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
trap 'rm -rf "$work"; docker rmi -f "$IMAGE_NAME" >/dev/null 2>&1 || true' EXIT

mkdir -p "$work/.devcontainer"
cp -r "$ROOT/src/orca-server" "$work/.devcontainer/orca-server"
jq -n '{image: "mcr.microsoft.com/devcontainers/base:bookworm", features: {"./orca-server": {}}}' \
  >"$work/.devcontainer/devcontainer.json"
npx --yes "@devcontainers/cli@$DEVCONTAINER_CLI_VERSION" build --workspace-folder "$(native "$work")" --image-name "$IMAGE_NAME"

{
  docker run --rm --entrypoint cat "$IMAGE_NAME" /usr/local/share/orca-server/options.env /usr/local/share/orca-server/remote-user
  docker history --no-trunc "$IMAGE_NAME"
} >"$work/scan.txt"

if grep -Ein 'orca://pair|TS_AUTH_KEY|tskey-' "$work/scan.txt"; then
  echo "FAIL: a pairing link or Tailscale key is in the image" >&2
  exit 1
fi
echo "ok   no pairing link or Tailscale key in the image"
