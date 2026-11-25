#!/usr/bin/env bash
set -euo pipefail
# test/ts7-cli/install_twice.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

PREFIX=/usr/local/share/ts7-cli

# The harness mounts the Feature files under .devcontainer in the workspace.
feature_install() {
  local f
  for f in /workspaces/*/.devcontainer/ts7-cli/install.sh; do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  echo "install.sh not found in the container" >&2
  return 1
}

# Run install.sh again as root with the given extra environment.
reinstall() {
  sudo -n env "$@" bash "$(feature_install)"
}

# FR-030: paths, modes, owners and the link, plus the printed version.
snapshot() {
  find "$PREFIX" -printf '%P %m %u\n' | sort
  readlink -f /usr/local/bin/tsc7
  tsc7 --version
}

# AC6: a second install with the same options exits 0 and changes nothing.
reinstall_changes_nothing() {
  local before after
  before="$(snapshot)"
  reinstall VERSION=7.0.2
  after="$(snapshot)"
  [ "$before" = "$after" ]
}

# FR-030: a run with another version equals a fresh install of that version.
other_version_replaces() {
  reinstall VERSION=7.0.1-rc
  [ "$(tsc7 --version)" = "Version 7.0.1-rc" ] &&
    [ "$(find "$PREFIX/node_modules" -name package.json -path '*/node_modules/typescript/package.json' | wc -l)" = 1 ]
}

check "second install changes nothing" reinstall_changes_nothing
check "a run with another version replaces the install" other_version_replaces

reportResults
