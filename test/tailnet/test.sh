#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/test.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-028: root owns the installed files. The options file holds no key (FR-003).
files_are_root_owned() {
  [ "$(stat -c '%U %a' "$ENTRY")" = "root 755" ] &&
    [ "$(stat -c '%U %a' "$SHARE/options.env")" = "root 644" ] &&
    ! grep -Eq 'tskey-|test-auth-key' "$SHARE/options.env"
}

# Research R2: with no TAILNET_WORKSPACE, the entrypoint takes the folder from /workspaces. The auto-run at container start proves it.
folder_from_workspaces() {
  wait_for_log "hostname $(workspace_name)-dev"
}

# The entrypoint ran at container start and wrote its log (FR-006).
entrypoint_wrote_log() {
  wait_for_log 'tailnet: .* start' &&
    [ "$(stat -c '%U %a' "$LOG")" = "root 644" ]
}

# AC1, arguments: the join passes the hostname, the tag, SSH and the key file. The key text stays off the command line (FR-026).
join_arguments() {
  local want
  install_stub
  want="dru-$(workspace_name)-dev"
  join_now TS_AUTH_KEY=test-auth-key HOSTNAME_PREFIX=dru
  [ "$(last_hostname)" = "$want" ] &&
    grep -q -- '--advertise-tags=tag:devcontainer' "$ARGS" &&
    grep -q -- ' --ssh' "$ARGS" &&
    grep -q -- '--reset' "$ARGS" &&
    grep -q -- '--accept-routes' "$ARGS" &&
    grep -q -- '--auth-key=file:/run/tailnet/authkey' "$ARGS" &&
    ! grep -q -- 'test-auth-key' "$ARGS" &&
    sudo -n grep -q 'joined as' "$LOG"
}

# FR-026: the key file is gone after the join.
key_file_removed() { ! sudo -n test -e "$RUN/authkey"; }

check "installed files are root owned and the options file holds no key" files_are_root_owned
check "the entrypoint wrote a root-owned log at start" entrypoint_wrote_log
check "the hostname takes the folder name from /workspaces" folder_from_workspaces
check "the join passes hostname, tag, SSH and the key file" join_arguments
check "the key file is removed after the join" key_file_removed

reportResults
