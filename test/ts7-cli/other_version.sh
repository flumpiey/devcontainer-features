#!/usr/bin/env bash
set -euo pipefail
# test/ts7-cli/other_version.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

PREFIX=/usr/local/share/ts7-cli

# US3 scenario 3: the version option installs that release. 7.0.1 was never published; 7.0.1-rc is the release before 7.0.2.
tsc7_prints_other() { [ "$(tsc7 --version)" = "Version 7.0.1-rc" ]; }

# FR-015: one typescript package, at the chosen version.
one_typescript_package() {
  [ "$(find "$PREFIX/node_modules" -name package.json -path '*/node_modules/typescript/package.json' | wc -l)" = 1 ] &&
    [ "$(jq -r .version "$PREFIX/node_modules/typescript/package.json")" = 7.0.1-rc ]
}

check "tsc7 prints the chosen version" tsc7_prints_other
check "one typescript package at the chosen version" one_typescript_package

reportResults
