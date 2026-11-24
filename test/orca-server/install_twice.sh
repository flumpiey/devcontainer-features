#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/install_twice.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

SHARE=/usr/local/share/orca-server

# The harness mounts the Feature files under .devcontainer in the workspace.
feature_install() {
  local f
  for f in /workspaces/*/.devcontainer/orca-server/install.sh; do
    if [ -f "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  echo "install.sh not found in the container" >&2
  return 1
}

# Run install.sh again as root with the given extra environment, same options otherwise.
reinstall() {
  sudo -n env _REMOTE_USER="$(id -un)" PAIRINGADDRESS=127.0.0.1 AUTOSTART=false "$@" bash "$(feature_install)"
}

# FR-006: a second install with the same options exits 0 and changes nothing.
reinstall_changes_nothing() {
  local before after
  before="$(
    stat -c '%U %a' "$SHARE/options.env"
    cat "$SHARE/options.env"
  )"
  reinstall
  after="$(
    stat -c '%U %a' "$SHARE/options.env"
    cat "$SHARE/options.env"
  )"
  [ "$before" = "$after" ] && [ "$(dpkg -l orca-ide | grep -c '^ii')" = 1 ]
}

# FR-006, FR-024: another version installs in place. It is not the default, so the
# hash comes from the release API (Decision 20). The API is unauthenticated: a rate limit fails this check.
upgrade_in_place() {
  local want
  want="$(curl -fsSL --retry 3 https://api.github.com/repos/stablyai/orca/releases/latest | jq -r '.tag_name | ltrimstr("v")')"
  reinstall VERSION=latest
  [ "$(dpkg-query -W -f='${Version}' orca-ide)" = "$want" ] && [ "$(dpkg -l orca-ide | grep -c '^ii')" = 1 ]
}

check "second install changes nothing" reinstall_changes_nothing
check "a run with another version installs it in place" upgrade_in_place

reportResults
