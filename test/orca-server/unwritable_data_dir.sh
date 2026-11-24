#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/unwritable_data_dir.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server

# A non-root entrypoint cannot fix the owner of the data directory, and mode 0700 hides the log file
# from the new UID. It prints one error line to stderr, starts no Orca, and still runs the command.
unwritable_dir_is_reported() {
  local out errf
  orca-server stop
  sudo -n chown root:root "$DATA"
  sudo -n chmod 0700 "$DATA"
  errf="$(mktemp)"
  out="$(/usr/local/share/orca-server/entrypoint.sh echo ran 2>"$errf")"
  sleep 10
  [ "$out" = ran ] &&
    [ "$(grep -c '^orca-server: error:' "$errf")" = 1 ] &&
    ! pgrep -f 'index\.js serve' >/dev/null
}

check "an unwritable data directory is reported and Orca is not started" unwritable_dir_is_reported

reportResults
