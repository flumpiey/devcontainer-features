# orca-server Feature

Spec, contracts and decision numbers (FR-xxx, AC, Decision n) cited in comments: `specs/001-orca-server-feature/`. User docs, release and withdrawal procedure: `src/orca-server/NOTES.md`.

- Flow: `install.sh` validates options, installs the pinned `.deb` (SHA-256 checked), writes `options.env` + `remote-user` to `/usr/local/share/orca-server`. `entrypoint.sh` backgrounds `orca-server start`. `orca-server` (no `.sh` suffix) is the CLI and watcher.
- `options.env` is sourced: every option value must be filtered to a safe character set in `install.sh`.
- `DEFAULT_VERSION` / `DEFAULT_DEB_SHA256` in `install.sh` must equal the JSON defaults (`verify.sh fast` enforces). Digest: GitHub release asset of `stablyai/orca`.
- `os-release` defines `VERSION`, which collides with the option name: read it in a subshell.
- Entrypoint: every failure path still reaches `exec "$@"`.
- Orca never runs as root; `orca-server` re-execs through `runuser` and resets `HOME`.
- Data and pairing secrets: volume at `/var/lib/orca-server`, dir 0700, files 0600. No pairing link at build time.
- Process lifecycle is race-sensitive: lock fd 9 must be closed in children; watcher logs the exit, then removes the watcher file, then the PID file. `stop`/`start` wait on the PID file.
- `postAttachCommand` runs `orca-server show --attach`: it must always exit 0. Pairing links appear only at attach, never at build (FR-022, FR-030).
- Release: bump `version` in `devcontainer-feature.json`; push to `main` publishes, an already published version is skipped.
- A new bash file without `.sh` must be added to the path regex in `scripts/verify.sh`, or it is not linted.
