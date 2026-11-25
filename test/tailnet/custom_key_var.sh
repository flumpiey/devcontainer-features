#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/custom_key_var.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# US1 scenario 4: the scenario sets authKeyVar to MY_TS_KEY. The join uses that variable.
uses_named_variable() {
  install_stub
  join_now MY_TS_KEY=test-auth-key
  grep -q -- '--auth-key=file:/run/tailnet/authkey' "$ARGS"
}

# The default variable is ignored, and the log names the variable that is missing.
names_the_missing_variable() {
  install_stub
  join_now TS_AUTH_KEY=test-auth-key
  sudo -n grep -q 'MY_TS_KEY is unset or empty' "$LOG" && [ ! -s "$ARGS" ]
}

check "the join uses the variable named by authKeyVar" uses_named_variable
check "a missing named variable is logged by name" names_the_missing_variable

reportResults
