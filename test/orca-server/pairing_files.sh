#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/pairing_files.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server
USER_FILE=/usr/local/share/orca-server/remote-user

pairing_file_ready() {
  local _
  for _ in $(seq 90); do
    if [ -s "$DATA/pairing-url.txt" ]; then return 0; fi
    sleep 1
  done
  return 1
}

# AC4: one line, one URL scheme.
pairing_file_is_one_link() {
  [ "$(wc -l <"$DATA/pairing-url.txt")" = 1 ] && grep -q '^orca://pair' "$DATA/pairing-url.txt"
}

# AC14: each form prints exactly one orca://pair line, and the two differ.
links_differ() {
  local desktop mobile
  desktop="$(orca-server url)"
  mobile="$(orca-server url --mobile)"
  [ "$(printf '%s\n' "$desktop" | wc -l)" = 1 ] && [ "$(printf '%s\n' "$mobile" | wc -l)" = 1 ] &&
    [[ "$desktop" == orca://pair* && "$mobile" == orca://pair* ]] && [ "$desktop" != "$mobile" ]
}

# AC8: owners and modes.
owners_and_modes() {
  local want
  want="$(<"$USER_FILE")"
  [ "$(stat -c '%U %a' "$DATA")" = "$want 700" ] &&
    [ "$(stat -c '%U %a' "$DATA/pairing-url.txt")" = "$want 600" ] &&
    [ "$(stat -c '%U %a' "$DATA/orca-server.log")" = "$want 600" ]
}

check "pairing-url.txt appears within 90 s" pairing_file_ready
check "pairing-url.txt holds one link" pairing_file_is_one_link
check "url and url --mobile print one differing link each" links_differ
check "owners and modes are correct" owners_and_modes

reportResults
