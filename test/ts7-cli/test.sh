#!/usr/bin/env bash
set -euo pipefail
# test/ts7-cli/test.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

PREFIX=/usr/local/share/ts7-cli

# The harness mounts the Feature files under .devcontainer in the workspace.
feature_json() {
  local f
  for f in /workspaces/*/.devcontainer/ts7-cli/devcontainer-feature.json; do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  echo "devcontainer-feature.json not found in the container" >&2
  return 1
}

# AC5: tsc7 prints the pinned version, which is the option default.
tsc7_prints_default() {
  [ "$(tsc7 --version)" = "Version $(jq -r '.options.version.default' "$(feature_json)")" ]
}

# AC5, FR-016: a repo with its own TypeScript 6 keeps it. The repo's tsc is the one in its node_modules.
repo_tsc_stays_6() {
  local proj
  proj="$(mktemp -d)"
  npm install --prefix "$proj" --no-audit --no-fund typescript@6 >/dev/null
  [[ "$("$proj/node_modules/.bin/tsc" --version)" == "Version 6."* ]] && [[ "$(tsc7 --version)" == "Version 7."* ]]
}

# FR-016, FR-018: no tsc on PATH comes from this Feature.
no_tsc_from_feature() {
  local found
  found="$(command -v tsc || true)"
  [[ "$found" != "$PREFIX"* ]] && [[ "$(readlink -f /usr/local/bin/tsc7)" == "$PREFIX/"* ]]
}

check "tsc7 prints the pinned version" tsc7_prints_default
check "the repo's own tsc still prints TypeScript 6" repo_tsc_stays_6
check "the Feature puts no tsc on PATH" no_tsc_from_feature

reportResults
