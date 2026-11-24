#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/test.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

installed_matches_default() {
  # VERSION is the option value. With no option set it is the default in devcontainer-feature.json.
  local want
  want="$(sed -n 's/^VERSION=//p' /usr/local/share/orca-server/options.env)"
  [ "$(dpkg-query -W -f='${Version}' orca-ide)" = "$want" ]
}

check "orca-ide runs" orca-ide --version
check "xvfb-run is present" command -v xvfb-run
check "libasound.so.2 is present" bash -c "ldconfig -p | grep -q 'libasound.so.2 '"
check "installed version equals the default" installed_matches_default

reportResults
