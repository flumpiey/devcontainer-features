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

fast() {
  local tool d f
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
      find "${dirs[@]}" -type f \( -name '*.sh' -o -path src/orca-server/orca-server \) | sort
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
  done < <(find . \( -name node_modules -o -name .git -o -name DevcontainerFeatures-Output \) -prune -o -type f -name '*.json' -print0)

  # FR-024: the install.sh constants equal the JSON defaults.
  local install=src/orca-server/install.sh json=src/orca-server/devcontainer-feature.json
  if [ -f "$install" ] && [ -f "$json" ]; then
    local opt const
    for opt in version:DEFAULT_VERSION debSha256:DEFAULT_DEB_SHA256; do
      const="$(sed -n "s/^${opt#*:}=//p" "$install")"
      [ "$const" = "$(jq -r ".options.${opt%%:*}.default" "$json")" ] ||
        problem "${opt#*:} in $install differs from the ${opt%%:*} default in $json"
    done
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

case "${1:-}" in
fast) fast ;;
push | ci)
  fast
  echo "verify: $1 not wired yet (T045)"
  ;;
*)
  echo "usage: bash scripts/verify.sh {fast|push|ci}" >&2
  exit 2
  ;;
esac
echo "verify: $1 ok"
