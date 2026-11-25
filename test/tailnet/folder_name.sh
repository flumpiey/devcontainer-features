#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/folder_name.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# hostname_for <folder> <prefix>: the hostname that a hand-made join passes for these inputs.
hostname_for() {
  install_stub
  join_now TS_AUTH_KEY=test-auth-key "TAILNET_WORKSPACE=$1" "HOSTNAME_PREFIX=$2"
  last_hostname
}

# FR-005: spaces, capitals and other characters.
spaces_and_capitals() { [ "$(hostname_for 'My Project_v2' Dru)" = dru-my-project-v2-dev ]; }

# FR-004: no prefix gives <folder>-dev.
no_prefix() { [ "$(hostname_for app '')" = app-dev ]; }

# FR-005: at most 63 characters, -dev stays.
long_folder() {
  local host
  host="$(hostname_for "$(printf 'a%.0s' $(seq 70))" dru)"
  [ "${#host}" -eq 63 ] && [[ "$host" =~ ^dru-a+-dev$ ]]
}

# FR-005: a cut that would leave a hyphen before -dev drops the hyphen.
cut_leaves_no_hyphen() {
  local host
  host="$(hostname_for "$(printf 'a%.0s' $(seq 54))-bbbbbbbb" dru)"
  [[ "$host" =~ -dev$ ]] && [[ ! "$host" =~ --dev$ ]] && [ "${#host}" -le 63 ]
}

check "spaces and capitals become a lower-case hyphenated hostname" spaces_and_capitals
check "no prefix gives <folder>-dev" no_prefix
check "a 70 character folder gives a 63 character hostname that ends in -dev" long_folder
check "a cut never leaves a hyphen before -dev" cut_leaves_no_hyphen

reportResults
