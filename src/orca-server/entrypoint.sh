#!/usr/bin/env bash
set -euo pipefail
# src/orca-server/entrypoint.sh
# Every failure still reaches exec "$@" (FR-009), so no step may stop the container.
set -E
umask 077

SHARE_DIR=/usr/local/share/orca-server
DATA_DIR=/var/lib/orca-server
LOG="$DATA_DIR/orca-server.log"

log() { echo "orca-server: $*" >>"$LOG" 2>/dev/null || true; }
stamp() { date -u +%Y-%m-%dT%H:%M:%S.%3NZ; }

trap 'log "entrypoint step failed"; exec "$@"' ERR

# shellcheck source=/dev/null
. "$SHARE_DIR/options.env" || log "cannot read options.env"
user="$(cat "$SHARE_DIR/remote-user" 2>/dev/null)" || log "cannot read remote-user"

# FR-015: enforce owner and mode. Only root can change the owner.
if [ "$(id -u)" -eq 0 ] && [ -n "${user:-}" ]; then
  install -d -o "$user" -g "$(id -gn "$user")" -m 0700 "$DATA_DIR" || log "cannot set owner of $DATA_DIR"
else
  chmod 0700 "$DATA_DIR" || log "cannot set mode of $DATA_DIR"
fi
: >"$LOG" || true
log "$(stamp) entrypoint: start"
for f in "$LOG" "$DATA_DIR/pairing-url.txt"; do
  [ -e "$f" ] || continue
  chmod 0600 "$f" || log "cannot set mode of $f"
  if [ "$(id -u)" -eq 0 ] && [ -n "${user:-}" ]; then
    chown "$user:$(id -gn "$user")" "$f" || log "cannot set owner of $f"
  fi
done

# orca-server switches to the remote user itself when root runs it.
if [ "${AUTO_START:-true}" = true ]; then
  ORCA_SERVER_LOG_FRESH=1 setsid /usr/local/bin/orca-server start >>"$LOG" 2>&1 </dev/null &
fi

log "$(stamp) entrypoint: exec"
exec "$@"
