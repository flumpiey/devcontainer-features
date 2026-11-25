#!/usr/bin/env bash
# src/tailnet/entrypoint.sh
set -euo pipefail
# Without arguments: start the join in the background and end with exec "$@" (Constitution VI, FR-006).
# With --join as the first argument: do the join. That mode runs as root (FR-028).
set -E

SHARE_DIR=/usr/local/share/tailnet
LOG=/var/log/tailnet.log
RUN_DIR=/run/tailnet
KEY_FILE=$RUN_DIR/authkey
LOCK_FILE=$RUN_DIR/lock
WAIT_SECONDS=30
UP_TIMEOUT=90

stamp() { date -u +%Y-%m-%dT%H:%M:%S.%3NZ; }

# One line per call. When the log file is not writable the line goes to the container error output.
log() {
  { echo "tailnet: $(stamp) $*" >>"$LOG"; } 2>/dev/null || echo "tailnet: $*" >&2
}

# sanitise <text>: lower case, and anything outside a-z, 0-9 and hyphen becomes a hyphen (FR-005).
sanitise() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g'; }

# The base name of the workspace folder. A repo may set TAILNET_WORKSPACE in its devcontainer.json containerEnv, with the
# value ${containerWorkspaceFolderBasename}. Without it, or with a value that was not expanded, the single directory under
# /workspaces is used. A Feature containerEnv cannot hold this variable: Docker expands it to nothing when the image builds.
workspace_folder() {
  local f="${TAILNET_WORKSPACE:-}" d dirs=()
  # shellcheck disable=SC2016 # the pattern is a literal dollar sign and brace
  if [ -n "$f" ] && [[ "$f" != *'${'* ]]; then
    printf '%s' "$f"
    return 0
  fi
  for d in /workspaces/*/; do
    if [ -d "$d" ]; then dirs+=("$d"); fi
  done
  if [ "${#dirs[@]}" -eq 1 ]; then basename "${dirs[0]}"; fi
}

# FR-004, FR-005: <prefix>-<folder>-dev, or <folder>-dev. At most 63 characters, so the folder part is cut and -dev stays.
compute_hostname() {
  local prefix folder base
  prefix="$(sanitise "${HOSTNAME_PREFIX_OPT:-}")"
  if [ -z "$prefix" ]; then prefix="$(sanitise "${HOSTNAME_PREFIX:-}")"; fi
  folder="$(sanitise "$(workspace_folder)")"
  base="$folder"
  if [ -n "$prefix" ]; then base="$prefix-$folder"; fi
  base="${base:0:59}"
  base="${base#"${base%%[!-]*}"}"
  base="${base%"${base##*[!-]}"}"
  if [ -n "$base" ]; then printf '%s-dev' "$base"; fi
}

join() {
  umask 022
  mkdir -p "$RUN_DIR"
  chmod 0700 "$RUN_DIR"
  if [ ! -e "$LOG" ]; then install -m 0644 /dev/null "$LOG"; fi

  # FR-036: one join at a time.
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log "another join is running; this run stops"
    return 0
  fi
  : >"$LOG"
  trap 'rm -f "$KEY_FILE"' EXIT
  trap 'log "error: a step failed near line $LINENO"' ERR

  # shellcheck source=/dev/null
  . "$SHARE_DIR/options.env"
  log "start"

  local folder host out state="" key="" rc=0 i
  folder="$(workspace_folder)"
  host="$(compute_hostname)"
  if [ -z "$folder" ] || [ -z "$host" ]; then
    log "error: cannot find the workspace folder name; not joining the tailnet"
    return 0
  fi
  log "hostname $host"

  # FR-006: tailscaled may still be starting, or may not run at all.
  for ((i = 0; i < WAIT_SECONDS; i++)); do
    out="$(tailscale status --json 2>/dev/null || true)"
    if [[ "$out" == *'"BackendState"'* ]]; then break; fi
    out=""
    sleep 1
  done
  if [ -z "$out" ]; then
    log "error: tailscaled did not answer within $WAIT_SECONDS seconds; not joining the tailnet"
    return 0
  fi
  state="$(sed -n 's/.*"BackendState": *"\([^"]*\)".*/\1/p' <<<"$out" | head -n 1)"
  log "backend state ${state:-unknown}"

  local args=(up --reset --accept-routes "--hostname=$host" "--advertise-tags=$TAGS")
  if [ "$SSH" = true ]; then args+=(--ssh); fi

  # FR-002, FR-007, FR-026: a node that is already Running needs no key. Any other node needs one.
  if [ "$state" != Running ]; then
    key="${!AUTH_KEY_VAR:-}"
    if [ -z "$key" ]; then
      log "error: $AUTH_KEY_VAR is unset or empty; not joining the tailnet"
      return 0
    fi
    (umask 077 && printf '%s' "$key" >"$KEY_FILE")
    args+=("--auth-key=file:$KEY_FILE")
  fi

  # FR-008: --reset makes the hostname, tags and SSH setting match this run, even on a node that is already up.
  out="$(timeout "$UP_TIMEOUT" tailscale "${args[@]}" 2>&1)" || rc=$?
  rm -f "$KEY_FILE"
  if [ "$rc" -eq 0 ]; then
    log "joined as $host with tags $TAGS"
  else
    log "error: tailscale up failed with exit $rc: ${out//$'\n'/ }"
  fi
}

# FR-028: tailscale needs root. A non-root entrypoint user joins through sudo, as the upstream Feature does.
start_join() {
  if [ "$(id -u)" -eq 0 ]; then
    setsid "$0" --join >/dev/null </dev/null &
  elif command -v sudo >/dev/null; then
    setsid sudo --non-interactive -E "$0" --join >/dev/null </dev/null &
  else
    echo "tailnet: error: sudo is missing and the user is not root; not joining the tailnet" >&2
  fi
}

if [ "${1:-}" = --join ]; then
  join
  exit 0
fi
start_join || echo "tailnet: error: could not start the join" >&2
exec "$@"
