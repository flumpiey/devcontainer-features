#!/usr/bin/env bash
set -euo pipefail
# test/verify-fast-untracked.sh
# Host-side test: verify.sh fast ignores an untracked bad JSON file and fails on a tracked one.
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
