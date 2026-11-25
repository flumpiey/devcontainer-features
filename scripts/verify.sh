#!/usr/bin/env bash
# scripts/verify.sh
# Usage: bash scripts/verify.sh {fast|push|ci}
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

status=0
problem() {
  echo "verify: error: $*" >&2
  status=1
}

# FR-022: the Feature ids are the directories that hold a devcontainer-feature.json. Prints nothing without src/.
features() {
  local j
  for j in src/*/devcontainer-feature.json; do
    if [ -e "$j" ]; then basename "$(dirname "$j")"; fi
  done
}

# jq on Windows ends lines with CRLF. Strip the CR so values compare equal.
jqr() { jq "$@" | tr -d '\r'; }

# option name in camelCase -> constant name in install.sh, for example debSha256 -> DEFAULT_DEB_SHA256
constant_name() {
  printf 'DEFAULT_%s' "$(sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' <<<"$1" | tr '[:lower:]' '[:upper:]')"
}

fast() {
  local tool d f id
  for tool in shellcheck shfmt jq grep; do
    command -v "$tool" >/dev/null || {
      echo "verify: error: missing tool: $tool" >&2
      exit 1
    }
  done

  # Check only the paths that exist, so fast passes before src/ exists.
  local dirs=()
  for d in scripts test src; do
    if [ -d "$d" ]; then dirs+=("$d"); fi
  done
  local sh_files=()
  if [ "${#dirs[@]}" -gt 0 ]; then
    mapfile -t sh_files < <(
      # Tracked files only. Bash scripts without a .sh suffix: one extensionless file per Feature, and the Tailscale stubs.
      git ls-files -- "${dirs[@]}" | grep -E '\.sh$|^src/[^/]+/[^/.]+$|^test/.*/tailscale$' | sort
    )
  fi
  if [ "${#sh_files[@]}" -gt 0 ]; then
    shellcheck "${sh_files[@]}" || status=1
    shfmt -d -i 2 "${sh_files[@]}" || status=1
    for f in "${sh_files[@]}"; do
      head -n 5 "$f" | grep -qx 'set -euo pipefail' ||
        problem "$f: 'set -euo pipefail' not in the first 5 lines"
    done
  fi

  while IFS= read -r -d '' f; do
    jq empty "$f" || problem "invalid JSON: $f"
  done < <(git ls-files -z -- '*.json')

  local install json opt name const ref ver
  while IFS= read -r id; do
    install="src/$id/install.sh"
    json="src/$id/devcontainer-feature.json"

    # FR-022: every Feature has a default test and a scenarios file.
    for f in "test/$id/test.sh" "test/$id/scenarios.json"; do
      [ -f "$f" ] || problem "$id: missing $f"
    done

    # FR-031: a default constant in install.sh equals the JSON default. Only options that have such a constant are checked.
    if [ -f "$install" ]; then
      while IFS= read -r opt; do
        name="$(constant_name "$opt")"
        const="$(sed -n "s/^${name}=//p" "$install")"
        [ -n "$const" ] || continue
        # shellcheck disable=SC2016 # $o is a jq variable
        [ "$const" = "$(jqr -r --arg o "$opt" '.options[$o].default' "$json")" ] ||
          problem "$name in $install differs from the $opt default in $json"
      done < <(jqr -r '(.options // {}) | to_entries[] | select(.value.default != null) | .key' "$json")
    fi

    # FR-031: each dependsOn entry has an exact version option and a major tag.
    while IFS=$'\t' read -r ref ver; do
      case "$ver" in
      '' | latest | lts) problem "$json: dependsOn $ref needs an exact version option, got '${ver:-none}'" ;;
      esac
      [[ "$ref" =~ :[0-9]+$ ]] || problem "$json: dependsOn $ref needs a major tag such as :1"
    done < <(jqr -r '(.dependsOn // {}) | to_entries[] | [.key, (.value.version // "")] | @tsv' "$json")
  done < <(features)

  # AC10, FR-024: release.yaml runs on a change under src/. It has no paths filter; one must keep src/**.
  local release=.github/workflows/release.yaml
  if [ -f "$release" ] && grep -qE '^[[:space:]]*paths:' "$release" && ! grep -qF 'src/**' "$release"; then
    problem "$release has a paths filter that does not list src/**"
  fi

  # Style scan. The word list lives here, and this file is not scanned.
  local targets=()
  for d in docs specs README.md; do
    if [ -e "$d" ]; then targets+=("$d"); fi
  done
  if [ -d src ]; then
    while IFS= read -r -d '' f; do targets+=("$f"); done < <(find src -name NOTES.md -print0)
  fi
  if [ "${#targets[@]}" -gt 0 ]; then
    # Bytes: en dash, em dash, symbol and emoji ranges, emoji variation selector.
    if LC_ALL=C grep -rnP '\xE2\x80[\x93\x94]|\xE2[\x98-\x9D]|\xE2\xAD|\xF0\x9F|\xEF\xB8\x8F' "${targets[@]}"; then
      problem "en dash, em dash or emoji found (above)"
    fi
    if grep -rniE '\b(color|behavior|organiz|analyz|center|favorite|initializ|optimiz|catalog|recogniz)' "${targets[@]}"; then
      problem "US spelling found (above)"
    fi
  fi

  return "$status"
}

export DEVCONTAINER_CLI_VERSION=0.88.0
IMAGE_PREFIX=mcr.microsoft.com/devcontainers/base
BASES=(bookworm jammy noble)

native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
dc() { npx --yes "@devcontainers/cli@$DEVCONTAINER_CLI_VERSION" "$@"; }

# The default test (test.sh) of one Feature on one base. --skip-scenarios, because the scenarios hold __BASE__.
default_test() {
  dc features test -p . -f "$1" -i "$IMAGE_PREFIX:$2" --skip-scenarios
}

# Every scenario of one Feature on one base, from a temp copy with __BASE__ replaced.
scenarios() {
  local id="$1" tmp
  if [ ! -f "test/$id/scenarios.json" ]; then return 0; fi
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/test"
  cp -r src "$tmp/src"
  cp -r "test/$id" "$tmp/test/$id"
  jq --arg image "$IMAGE_PREFIX:$2" 'walk(if type == "string" then sub("__BASE__"; $image) else . end)' \
    "test/$id/scenarios.json" >"$tmp/test/$id/scenarios.json"
  dc features test -p "$(native "$tmp")" -f "$id" --skip-autogenerated || {
    rm -rf "$tmp"
    return 1
  }
  rm -rf "$tmp"
}

case "${1:-}" in
fast) fast ;;
push)
  fast
  while IFS= read -r id; do default_test "$id" bookworm; done < <(features)
  ;;
ci)
  fast
  mapfile -t ids < <(features)
  for base in "${BASES[@]}"; do
    for id in "${ids[@]}"; do
      default_test "$id" "$base"
      scenarios "$id" "$base"
    done
  done
  dc features test -p . --global-scenarios-only
  # Host-side tests, run where a Feature has them.
  for id in "${ids[@]}"; do
    for script in build-fails.sh secrets_scan.sh; do
      if [ -f "test/$id/$script" ]; then bash "test/$id/$script"; fi
    done
  done
  ;;
*)
  echo "usage: bash scripts/verify.sh {fast|push|ci}" >&2
  exit 2
  ;;
esac
echo "verify: $1 ok"
