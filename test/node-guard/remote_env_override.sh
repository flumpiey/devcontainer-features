#!/usr/bin/env bash
set -euo pipefail
# test/node-guard/remote_env_override.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

# FR-014: a remoteEnv value wins over the Feature value. The other values stay.
value_is() { [ "$(printenv "$1")" = "$2" ]; }

check "NX_PARALLEL has the remoteEnv value" value_is NX_PARALLEL 3
check "NODE_OPTIONS keeps the Feature value" value_is NODE_OPTIONS --max-old-space-size=2048
check "NX_DAEMON keeps the Feature value" value_is NX_DAEMON false

reportResults
