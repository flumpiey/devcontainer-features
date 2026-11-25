#!/usr/bin/env bash
set -euo pipefail
# test/verify-fast-untracked.sh
# Host-side test: verify.sh fast ignores an untracked bad JSON file and fails on a tracked one.
# It also checks the release paths filter, the Feature test files and the dependsOn pin (FR-022, FR-024, FR-031).
# Run: bash test/verify-fast-untracked.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

git init -q "$work"
mkdir "$work/scripts"
cp "$ROOT/scripts/verify.sh" "$work/scripts/verify.sh"
echo '{}' >"$work/good.json"
git -C "$work" add scripts good.json

echo '{ not json' >"$work/untracked.json"
bash "$work/scripts/verify.sh" fast >/dev/null || {
  echo "FAIL: an untracked bad JSON file failed fast" >&2
  exit 1
}
echo "ok   untracked bad JSON is ignored"

git -C "$work" add untracked.json
if bash "$work/scripts/verify.sh" fast >/dev/null 2>&1; then
  echo "FAIL: a tracked bad JSON file passed fast" >&2
  exit 1
fi
echo "ok   tracked bad JSON fails"

git -C "$work" rm -q -f --cached untracked.json
rm "$work/untracked.json"

# expect_fast <pass|fail> <name>: run fast in the temp repo and compare with the expected result.
expect_fast() {
  local rc=0
  bash "$work/scripts/verify.sh" fast >/dev/null 2>&1 || rc=$?
  if [ "$1" = pass ] && [ "$rc" -ne 0 ]; then
    echo "FAIL: $2: fast failed" >&2
    exit 1
  fi
  if [ "$1" = fail ] && [ "$rc" -eq 0 ]; then
    echo "FAIL: $2: fast passed" >&2
    exit 1
  fi
  echo "ok   $2"
}

mkdir -p "$work/.github/workflows"
printf 'on:
  push:
    paths: ["src/orca-server/**"]
' >"$work/.github/workflows/release.yaml"
expect_fast fail "release.yaml paths filter without src/** fails"
printf 'on:
  push:
    paths: ["src/**"]
' >"$work/.github/workflows/release.yaml"
expect_fast pass "release.yaml paths filter with src/** passes"

mkdir -p "$work/src/demo"
echo '{"id": "demo", "version": "1.0.0"}' >"$work/src/demo/devcontainer-feature.json"
expect_fast fail "a Feature without test.sh and scenarios.json fails"
mkdir -p "$work/test/demo"
: >"$work/test/demo/test.sh"
echo '{}' >"$work/test/demo/scenarios.json"
expect_fast pass "a Feature with test.sh and scenarios.json passes"

echo '{"id": "demo", "version": "1.0.0", "dependsOn": {"ghcr.io/example/dep:1": {"version": "latest"}}}' >"$work/src/demo/devcontainer-feature.json"
expect_fast fail "dependsOn with version latest fails"
echo '{"id": "demo", "version": "1.0.0", "dependsOn": {"ghcr.io/example/dep": {"version": "1.2.3"}}}' >"$work/src/demo/devcontainer-feature.json"
expect_fast fail "dependsOn without a major tag fails"
echo '{"id": "demo", "version": "1.0.0", "dependsOn": {"ghcr.io/example/dep:1": {"version": "1.2.3"}}}' >"$work/src/demo/devcontainer-feature.json"
expect_fast pass "dependsOn with an exact version and a major tag passes"
