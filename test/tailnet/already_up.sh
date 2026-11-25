#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/already_up.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-008, US1 scenario 5: a node that is already Running, with another hostname, gets the computed values again. The key is not needed.
settings_replaced() {
  install_stub
  sudo -n bash -c 'echo Running >/var/tmp/tailscale-stub-state'
  join_now HOSTNAME_PREFIX=old
  join_now HOSTNAME_PREFIX=new
  local want
  want="new-$(workspace_name)-dev"
  [ "$(sudo -n grep -c '' "$ARGS")" = 2 ] &&
    [ "$(last_hostname)" = "$want" ] &&
    ! grep -q -- '--auth-key' "$ARGS" &&
    grep -q -- '--advertise-tags=tag:devcontainer' "$ARGS" &&
    grep -q -- ' --ssh' "$ARGS"
}

check "a Running node is set to the computed hostname, tags and SSH, with no key" settings_replaced

reportResults
