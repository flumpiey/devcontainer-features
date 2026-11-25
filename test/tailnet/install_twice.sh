#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/install_twice.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The harness mounts the Feature files under .devcontainer in the workspace.
feature_install() {
  local f
  for f in /workspaces/*/.devcontainer/tailnet/install.sh; do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  echo "install.sh not found in the container" >&2
  return 1
}

# Run install.sh again as root with the given option variables.
reinstall() { sudo -n env "$@" bash "$(feature_install)"; }

# FR-030: paths, owners, modes and content.
snapshot() {
  stat -c '%n %U %a' "$SHARE/options.env" "$SHARE/entrypoint.sh"
  cat "$SHARE/options.env"
  sha256sum "$SHARE/entrypoint.sh"
}

# AC6: a second install with the same options exits 0 and changes nothing.
reinstall_changes_nothing() {
  local before after
  before="$(snapshot)"
  reinstall TAGS=tag:devcontainer
  after="$(snapshot)"
  [ "$before" = "$after" ]
}

# FR-030: a run with other options equals a fresh install with those options.
other_options_replace() {
  reinstall TAGS=tag:other HOSTNAMEPREFIX=Dru AUTHKEYVAR=MY_KEY SSH=false
  [ "$(cat "$SHARE/options.env")" = "$(printf 'HOSTNAME_PREFIX_OPT=dru\nTAGS=tag:other\nAUTH_KEY_VAR=MY_KEY\nSSH=false')" ]
}

check "second install changes nothing" reinstall_changes_nothing
check "a run with other options replaces the options file" other_options_replace

reportResults
