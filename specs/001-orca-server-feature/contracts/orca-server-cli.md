# Contract: orca-server command

Path: `/usr/local/bin/orca-server`. Runs as the remote user. When run as root, it switches to the remote user with `runuser`.

| Subcommand | Behaviour | Output | Exit |
|------------|-----------|--------|------|
| `start` | Start Orca in the background if not running. Resolve the address as in spec Decision 4. Pass `--refuse-public` (Decision 15). | none on success | 0; 1 on error |
| `stop` | Stop the process in the PID file. Remove the PID file. | none | 0 |
| `status` | Check the PID file and the process. | `running` or `stopped` | 0 running, 3 stopped |
| `url` | Run `orca-ide pair --address <resolved address>`. Print the first `orca://pair` token. | one line, the desktop link | 0; 1 if Orca is not running or pairing is unavailable |
| `url --mobile` | Run `orca-ide pair --mobile --address <resolved address>`. Print the first `orca://pair` token. | one line, the mobile link | 0; 1 if Orca is not running or pairing is unavailable |

Rules:

- `url` and `url --mobile` use the same address resolution as `start`.
- Repeated calls reuse an unused offer. They do not create new grants.
- On failure, `url` prints one `orca-server: error: ` line to stderr.
- `/var/lib/orca-server/pairing-url.txt` is not read by `url`. It holds the link `serve` printed at start. With `mobilePairing` true, that link is the mobile link.
- Log line format: every line the script writes starts with `orca-server: `. An error line starts with `orca-server: error: `. Log file: `/var/lib/orca-server/orca-server.log`, mode 0600, owned by the remote user. `start` truncates it before Orca starts.
- Timestamped lines (entrypoint only): `orca-server: <UTC time> entrypoint: start` and `orca-server: <UTC time> entrypoint: exec`. Time format `YYYY-MM-DDTHH:MM:SS.mmmZ`. These lines never start with `orca-server: error:`.
- `url` and `url --mobile` print exactly one line each. The two lines differ.
- `start` resolves the address in the foreground, so it exits 1 with one `orca-server: error:` line when the address cannot be resolved. The entrypoint runs it detached.
- `start` takes the lock `/var/lib/orca-server/orca-server.lock` (FR-027). If the lock is held or Orca runs, it exits 0 and starts nothing.
- `start` truncates the log unless the environment has `ORCA_SERVER_LOG_FRESH=1`. The entrypoint sets that variable, because it truncates the log itself. Root callers use `runuser --preserve-environment`, so the variable survives.
- Orca exit: when the Orca process ends, the control script appends `orca-server: orca-ide exited with status <n>` and removes the PID file.
- Files `start` creates: `pairing-url.txt` and the log, mode 0600. The directory `/var/lib/orca-server` stays mode 0700.
- Unknown subcommand or flag: print usage to stderr, exit 2.
- The Orca process starts as: `orca-ide serve --port <port> --pairing-address <addr> --refuse-public [--mobile-pairing]`.
