#!/usr/bin/env bash
set -euo pipefail
# test/node-guard/test.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

declare -A WANT=(
  [NODE_OPTIONS]=--max-old-space-size=2048
  [NX_PARALLEL]=1
  [NX_DAEMON]=false
  [VITEST_MAX_WORKERS]=1
)

# AC4: a non-login bash shell, and a plain sh shell.
in_bash() { [ "$(bash -c 'printenv "$1"' _ "$1")" = "$2" ]; }
in_sh() { [ "$(sh -c 'printenv "$1"' _ "$1")" = "$2" ]; }

# FR-013: the first process of the container, which no shell started. Root owns it, so a non-root user reads it through sudo.
in_pid1() {
  local env
  if [ -r /proc/1/environ ]; then
    env="$(tr '\0' '\n' </proc/1/environ)"
  else
    env="$(sudo -n cat /proc/1/environ | tr '\0' '\n')"
  fi
  grep -qxF "$1=$2" <<<"$env"
}

for name in "${!WANT[@]}"; do
  check "$name in a non-login bash shell" in_bash "$name" "${WANT[$name]}"
  check "$name in a plain sh shell" in_sh "$name" "${WANT[$name]}"
  check "$name in the first process" in_pid1 "$name" "${WANT[$name]}"
done

reportResults
