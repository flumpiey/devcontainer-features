#!/usr/bin/env bash
set -euo pipefail
# test/node-guard/install_twice.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

# The harness mounts the Feature files under .devcontainer in the workspace.
feature_install() {
  local f
  for f in /workspaces/*/.devcontainer/node-guard/install.sh; do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  echo "install.sh not found in the container" >&2
  return 1
}

# AC6, FR-030: node-guard writes no file, so the result is the exit code and the environment.
state() { printenv NODE_OPTIONS NX_PARALLEL NX_DAEMON VITEST_MAX_WORKERS; }

reinstall_changes_nothing() {
  local before after
  before="$(state)"
  sudo -n bash "$(feature_install)"
  sudo -n bash "$(feature_install)"
  after="$(state)"
  [ "$before" = "$after" ]
}

check "two more installs exit 0 and change nothing" reinstall_changes_nothing

reportResults
