# Data Model: orca-server Feature

## Build-time files

| Path | Written by | Content |
|------|-----------|---------|
| `/opt/Orca` | the .deb | Orca runtime; provides `orca-ide` |
| `/usr/local/share/orca-server/entrypoint.sh` | `install.sh` | entrypoint, mode 0755 |
| `/usr/local/bin/orca-server` | `install.sh` | control script, mode 0755 |
| `/usr/local/share/orca-server/remote-user` | `install.sh` | one line: the user name from `_REMOTE_USER` |
| `/usr/local/share/orca-server/options.env` | `install.sh` | `KEY=value` lines for the options, no secret |
| `/var/lib/orca-server` | `install.sh` | directory owned by the remote user, so a new named volume inherits the owner |

## Run-time state

| Path | Lifetime | Content |
|------|----------|---------|
| `/var/lib/orca-server` (mode 0700) | named volume `orca-server-data-${devcontainerId}`, survives rebuild | Orca user data (`ORCA_USER_DATA`): identity, grants, settings, logs |
| `/var/lib/orca-server/pairing-url.txt` (mode 0600) | overwritten at each start | one line, `orca://pair?code=...` |
| `/var/lib/orca-server/orca-server.pid` | removed on stop | PID of the `orca-ide serve` process |
| `/var/lib/orca-server/orca-server.lock` (mode 0600) | held by `start` from the wait until Orca has launched | empty lock file (FR-027) |
| `/var/lib/orca-server/orca-server.log` (mode 0600) | truncated at each start, survives rebuild | full Orca output and `orca-server:` lines |

All four are owned by the remote user. The entrypoint enforces owner and mode at each start.

## options.env keys

| Key | Source option | Default |
|-----|---------------|---------|
| `VERSION` | `version` | `1.4.271` |
| `PAIRING_ADDRESS` | `pairingAddress` | empty |
| `PORT` | `port` | `6768` |
| `MOBILE_PAIRING` | `mobilePairing` | `true` |
| `AUTO_START` | `autoStart` | `true` |
| `TAILSCALE_WAIT_SECONDS` | `tailscaleWaitSeconds` | `120` |
| `DEB_SHA256` | `debSha256` | `7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755` (not read at run time) |
| `SHOW_PAIRING_ON_ATTACH` | `showPairingOnAttach` | `true` |

## Process states

```text
absent -> waiting (autoStart true, address empty) -> running
absent -> running (address set)
waiting -> failed (wait ends, Tailscale not Running): one error line, no process
running -> stopped (orca-server stop, or Orca exit): status prints stopped, exit 3
stopped -> running (orca-server start)
```

## Validation rules

- `port` MUST be an integer from 1 to 65535. Reject anything else at install time.
- `tailscaleWaitSeconds` MUST be a non-negative integer.
- `version` MUST match `^[0-9]+\.[0-9]+\.[0-9]+$` or equal `latest`.
- `pairing-url.txt` MUST hold exactly one line.
