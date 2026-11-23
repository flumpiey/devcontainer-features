#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/install_twice.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

SHARE=/usr/local/share/orca-server

# FR-006: a second install with the same options exits 0 and changes nothing.
# The harness mounts the Feature files under .devcontainer in the workspace.
reinstall_changes_nothing() {
  local install before after
  install="$(find / -path '/workspaces/*/.devcontainer/orca-server/install.sh' -not -path '/proc/*' 2>/dev/null | head -n 1)"
  [ -n "$install" ] || {
    echo "install.sh not found in the container" >&2
    return 1
  }
  before="$(
    stat -c '%U %a' "$SHARE/options.env"
    cat "$SHARE/options.env"
  )"
  sudo -n env _REMOTE_USER="$(id -un)" PAIRINGADDRESS=127.0.0.1 AUTOSTART=false bash "$install"
  after="$(
    stat -c '%U %a' "$SHARE/options.env"
    cat "$SHARE/options.env"
  )"
  [ "$before" = "$after" ] && [ "$(dpkg -l orca-ide | grep -c '^ii')" = 1 ]
}

check "second install changes nothing" reinstall_changes_nothing

reportResults
