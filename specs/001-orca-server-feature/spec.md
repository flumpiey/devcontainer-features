# Feature Specification: orca-server devcontainer Feature

**Feature Branch**: `n/a (no branch hook ran; work on the current branch)`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Build a devcontainer Feature with id orca-server that installs the Orca IDE runtime (stablyai/orca) in a devcontainer and starts `orca-ide serve` on the container's Tailscale address, so each devcontainer shows as a Remote Orca Server that Orca desktop and Orca Mobile can pair with. It does NOT register Claude or Codex accounts, does NOT install Tailscale, does NOT pair clients automatically, and does NOT support the AppImage or non-Debian bases."

## Context

- Dru runs one devcontainer per project (Nx monorepos, pnpm) on dru-main-pc under Docker Desktop on WSL2. Each container joins the tailnet boga-amberjack.ts.net through the Feature `ghcr.io/tailscale/codespace/tailscale`, with Tailscale SSH, `tag:devcontainer`, and hostname `<HOSTNAME_PREFIX>-<folder>-dev`.
- Orca headless mode is `orca-ide serve --port <port> --pairing-address <address>`. It prints a pairing URL that the client pastes into Settings, Remote Orca Servers, Add Server. `--mobile-pairing` enables phone pairing. Orca starts Xvfb on display :99 when no display exists.
- The Linux .deb installs to `/opt/Orca` and provides the `orca-ide` command. It declares `libasound2t64 | libasound2`, `xvfb`, `libgbm1` and `libnss3` as dependencies, so `apt-get install` resolves them (research.md, analysis R5).
- Orca has no environment variable or flag for a fixed pairing credential. Each paired client gets a revocable grant that stays valid until revoked.

## Decisions (fixed, do not re-ask in clarify)

1. Feature id `orca-server`, published as `ghcr.io/flumpiey/devcontainer-features/orca-server`, Feature version 1.0.0.
2. Option `version`: default is the newest release tag that passes the test suite at plan time. `latest` resolves the newest GitHub release at install time.
3. Install format: the .deb from the GitHub release, installed with `apt-get install` so dependencies resolve.
4. Option `pairingAddress`: empty (default) means the Tailscale MagicDNS name of the container, read from `tailscale status --json` field `Self.DNSName` with the trailing dot removed. If that is empty, use the first entry of `Self.TailscaleIPs`.
5. Option `tailscaleWaitSeconds`, default 120. If Tailscale is not Running when the wait ends and `pairingAddress` is empty, the entrypoint logs one error line and does not start Orca. When `pairingAddress` is set, the entrypoint skips the Tailscale wait and does not call `tailscale`. A value of 0 means one check and no wait. Each `tailscale status` call is limited to 5 seconds, so a hung call cannot extend the wait.
6. Option `port`, default `6768`.
7. Option `mobilePairing`, boolean, default true, which adds `--mobile-pairing`.
8. Option `autoStart`, boolean, default true. When false, the Feature installs Orca and a start script but the entrypoint starts nothing.
9. The Feature declares a named volume `orca-server-data-${devcontainerId}` mounted at `/var/lib/orca-server`. Orca's user-data directory resolves into that volume, so grants survive a rebuild.
10. Each start overwrites `/var/lib/orca-server/pairing-url.txt` with the newest pairing URL. Full output goes to `/var/lib/orca-server/orca-server.log` (changed 2026-11-23 from `/tmp/orca-server.log`, see Decision 17).
11. The remote user captured at install time from `_REMOTE_USER` runs Orca. If the entrypoint runs as root, it starts Orca with `runuser` as that user.
12. `installsAfter` lists `ghcr.io/tailscale/codespace/tailscale` and `ghcr.io/devcontainers-extra/features/tailscale`.
13. The Feature installs `/usr/local/bin/orca-server` with subcommands `start`, `stop`, `status` and `url`.
14. (Decided 2026-11-23) `orca-server url` prints the desktop pairing link, taken from `orca-ide pair --address <resolved address>`. `orca-server url --mobile` prints the mobile link, taken from `orca-ide pair --mobile --address <resolved address>`. `mobilePairing` stays default true. `pairing-url.txt` (Decision 10) keeps the link that `orca-ide serve` printed at start, so with `mobilePairing` true it holds the mobile link. `url` needs a running server and exits 1 with an error line otherwise.
15. (Decided 2026-11-23) `orca-ide serve` is always started with `--refuse-public`. Verified in Orca source: the 100.64.0.0/10 range is class `tailnet`, and only class `public` peers are refused. See research.md D10.
16. (Decided 2026-11-23) The .deb stays for 1.0.0. `install.sh` checks the downloaded .deb against a SHA-256. The hash rules are in Decision 20 and FR-024. The default version is `1.4.271`.
17. (Decided 2026-11-23) The log is `/var/lib/orca-server/orca-server.log`, mode 0600, owned by the remote user. The entrypoint and `orca-server start` truncate it at the start of each Orca start. It holds the pairing link, so it MUST NOT be world readable and MUST NOT sit in `/tmp`.
18. (Decided 2026-11-23) `/var/lib/orca-server` is mode 0700 and `pairing-url.txt` is mode 0600, both owned by the remote user. The entrypoint enforces owner and mode at each start, so an existing volume with other values is corrected.
19. (Decided 2026-11-23) The GHCR package `ghcr.io/flumpiey/devcontainer-features/orca-server` MUST be public. A new package is private by default. `NOTES.md` states the one-time step to set the visibility to public after the first publish.
20. (Decided 2026-11-23) Option `debSha256`, string, default `7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755` (the `v1.4.271` digest). A value other than the default is always the expected hash. If the resolved `version` is not the default and `debSha256` still equals the default, the expected hash comes from the release API. When `version` is `latest`, the resolved version is compared with the default version first. `install.sh` holds the default version and default hash as constants. The full rules, exit codes and message are in FR-024.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Install (Priority: P1)

As Dru, I add the Feature to devcontainer.json and the build installs orca-ide, Xvfb and libasound, on Debian 12, Ubuntu 22.04 and Ubuntu 24.04, amd64.

**Why this priority**: Nothing else works without a successful install.

**Independent Test**: Build a container from each of the three base images with default options and run `orca-ide --version`.

**Acceptance Scenarios**:

1. **Given** a Debian 12, Ubuntu 22.04 or Ubuntu 24.04 amd64 base, **When** the container builds with the Feature at default options, **Then** the build succeeds and `orca-ide --version` exits 0.
2. **Given** a finished install, **When** I look for `xvfb-run` and `libasound.so.2`, **Then** both are present.
3. **Given** a finished install, **When** `install.sh` runs a second time, **Then** it exits 0 and one copy of Orca is installed.

---

### User Story 2 - Start on the tailnet (Priority: P1)

As Dru, when the container starts, Orca serve starts in the background on the Tailscale name and port 6768, and the container start is never delayed by more than 2 seconds.

**Why this priority**: A running server is the point of the Feature.

**Independent Test**: Start a container with `pairingAddress` set to 127.0.0.1 and request `http://127.0.0.1:6768/`.

**Acceptance Scenarios**:

1. **Given** Tailscale is Running, **When** the container starts, **Then** Orca serves on the MagicDNS name of the container (or the first Tailscale IP if the name is empty) and port 6768.
2. **Given** `pairingAddress` is set, **When** the container starts, **Then** Orca serves on that address and Tailscale is not consulted.
3. **Given** the entrypoint waits for Tailscale or starts Orca, **When** the container starts, **Then** the entrypoint reaches `exec "$@"` within 2 seconds of starting, so the container start is not delayed.
4. **Given** `pairingAddress` is set, **When** the container starts, **Then** the entrypoint does not wait for Tailscale.

---

### User Story 3 - Pair once (Priority: P1)

As Dru, I read the pairing URL with `orca-server url`, pair once from the desktop and from Orca Mobile, and after a rebuild the clients reconnect without a new pairing.

**Why this priority**: Without durable grants, every rebuild forces a manual re-pair on every client.

**Independent Test**: Pair the desktop client, rebuild the container with the same volume, and confirm the client reconnects.

**Acceptance Scenarios**:

1. **Given** Orca is serving, **When** I run `orca-server url`, **Then** it prints the desktop pairing link. **When** I run `orca-server url --mobile`, **Then** it prints the mobile pairing link.
2. **Given** a paired client and an existing volume, **When** the container is rebuilt, **Then** the client reconnects with no new pairing URL.
3. **Given** `mobilePairing` is true, **When** Orca starts, **Then** phone pairing is enabled.

---

### User Story 4 - Control (Priority: P2)

As Dru, I stop, start and check Orca with the `orca-server` command.

**Why this priority**: Manual control helps recovery, but the Feature works without it.

**Independent Test**: Run `orca-server status`, `stop`, `status`, `start`, `status` in order.

**Acceptance Scenarios**:

1. **Given** Orca serves, **When** I run `orca-server status`, **Then** it prints `running` and exits 0.
2. **Given** Orca serves, **When** I run `orca-server stop` then `orca-server status`, **Then** status prints `stopped` and exits 3.
3. **Given** `autoStart` is false, **When** the container starts, **Then** Orca does not run until I run `orca-server start`.

---

### User Story 5 - Publish (Priority: P2)

As Dru, a push to main that changes the Feature version publishes it to GHCR and regenerates the Feature README.

**Why this priority**: Projects consume the Feature from the registry, but publishing can follow a working Feature.

**Independent Test**: Push a version bump to main and check the registry tag and README.

**Acceptance Scenarios**:

1. **Given** a push to main that changes the Feature version, **When** the publish workflow finishes, **Then** `ghcr.io/flumpiey/devcontainer-features/orca-server:1` exists.
2. **Given** the same push, **When** the workflow finishes, **Then** `src/orca-server/README.md` lists every option with its default.

---

### Edge Cases

- Tailscale Feature absent: `pairingAddress` empty gives one error line and no Orca start. `pairingAddress` set starts Orca on that address.
- Tailscale present but not logged in (no `TS_AUTH_KEY`): same as absent once the wait ends.
- Port already in use: Orca fails, the log records it, the container keeps running, `orca-server status` reports stopped.
- Container restart without rebuild: Orca starts again and overwrites the pairing URL file.
- Rebuild with the existing volume: grants and settings are kept.
- Unsupported base or architecture: `install.sh` exits non-zero with one line naming the detected OS and architecture.
- `version` names a tag with no .deb asset: `install.sh` exits non-zero naming the tag and the URL it tried.
- `install.sh` run twice: no error, one installed copy.
- Container runs as a non-root user: the entrypoint starts Orca directly as that user.
- `_REMOTE_USER` is empty or `root`: `install.sh` exits 1 with one line (FR-014).
- `orca-server start` runs while Orca runs or waits for Tailscale: no second process starts (FR-027).
- Orca exits after a successful start: the log records the exit, `status` reports `stopped`, Orca does not restart (FR-018).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Feature MUST follow the layout `src/orca-server/devcontainer-feature.json`, `src/orca-server/install.sh`, `test/orca-server/test.sh` and `test/orca-server/scenarios.json`.
- **FR-002**: `install.sh` MUST install the .deb of the chosen Orca release with `apt-get install`, so that the dependencies the .deb declares (including Xvfb and libasound) resolve. The .deb declares them (research.md, analysis R5), so `install.sh` installs no separate package list for them.
- **FR-003**: `install.sh` MUST resolve `version` `latest` to the newest GitHub release at install time, and MUST otherwise use the given tag. If the release API call fails, `install.sh` MUST exit 2 with one line.
- **FR-004**: `install.sh` MUST exit 1 with one line naming the detected OS and architecture on any base other than Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on amd64.
- **FR-005**: `install.sh` MUST exit 2 with a message naming the tag and the URL tried when the tag has no .deb asset.
- **FR-006**: `install.sh` MUST be idempotent: a second run with the same options exits 0 and gives the same result, meaning one installed `orca-ide` package at the same version and the same content, owner and mode for every file `install.sh` writes. A second run with a different `version` installs that version in place of the first. The second run rewrites `options.env` from the new options.
- **FR-007**: The Feature MUST expose the options `version`, `pairingAddress`, `port`, `mobilePairing`, `autoStart`, `tailscaleWaitSeconds` and `debSha256` with the defaults in Decisions.
- **FR-008**: The Feature MUST declare the named volume `orca-server-data-${devcontainerId}` mounted at `/var/lib/orca-server`, and Orca's user-data directory MUST resolve into it.
- **FR-009**: The Feature MUST declare an entrypoint that starts Orca in the background and always ends with `exec "$@"`. Every step before `exec "$@"` MUST be guarded: a failing step is logged and MUST NOT stop the entrypoint from reaching `exec "$@"`. Because the entrypoint ends with `exec "$@"`, later Feature entrypoints can chain after it. How tools chain several Feature entrypoints is not verified (see Assumptions) and a test covers it.
- **FR-010**: With `pairingAddress` empty, the entrypoint MUST wait up to `tailscaleWaitSeconds` for Tailscale to be Running, then take the address from `tailscale status --json` as in Decisions. With `pairingAddress` set, the entrypoint MUST skip the wait and MUST NOT call `tailscale`. The wait runs in the background job, so it never delays `exec "$@"`. A `tailscaleWaitSeconds` of 0 means one check and no wait. Each `tailscale status` call is limited to 5 seconds.
- **FR-011**: If Tailscale is not Running when the wait ends and `pairingAddress` is empty, the entrypoint MUST log exactly one line starting with `orca-server: error:` to `/var/lib/orca-server/orca-server.log`, MUST NOT start Orca, and MUST NOT stop the container.
- **FR-012**: The entrypoint MUST reach `exec "$@"` within 2 seconds of starting. It MUST write two timestamped lines to the log: one when it starts and one immediately before `exec "$@"`. Neither line starts with `orca-server: error:`.
- **FR-013**: Each start MUST overwrite `/var/lib/orca-server/pairing-url.txt` with the newest pairing URL and write full output to `/var/lib/orca-server/orca-server.log`. The entrypoint and `orca-server start` MUST truncate the log at the start of each Orca start.
- **FR-014**: Orca MUST run as the remote user captured from `_REMOTE_USER`. A root entrypoint MUST use `runuser`. A non-root entrypoint MUST start Orca directly. If `_REMOTE_USER` is empty or `root`, `install.sh` MUST exit 1 with one line, because Orca runs as an unprivileged user (analysis R5).
- **FR-015**: `/var/lib/orca-server` MUST be mode 0700. `pairing-url.txt` and `orca-server.log` MUST be mode 0600. All three MUST be owned by the remote user. `install.sh` sets the directory at build time. The entrypoint enforces owner and mode of all three at each start.
- **FR-016**: The Feature MUST install `/usr/local/bin/orca-server` with `start`, `stop`, `status` and `url`. `status` prints `running` and exits 0, or prints `stopped` and exits 3. A PID file that points to no live `orca-ide` process counts as stopped and MUST be removed.
- **FR-023**: `orca-server url` MUST print the desktop link from `orca-ide pair --address <resolved address>`. `orca-server url --mobile` MUST print the mobile link from `orca-ide pair --mobile --address <resolved address>`. Each prints one line starting with `orca://pair`. With no running server, each MUST print one `orca-server: error:` line and exit 1. Only the remote user (and root, through `runuser`) can run them. Orca also allows only the machine's own user to create pairings.
- **FR-024**: `install.sh` MUST verify the downloaded .deb against a SHA-256 before `apt-get install`. The expected hash is the option `debSha256`, resolved as in Decision 20. On mismatch it MUST exit 3 with exactly this line: `orca-server: error: sha256 mismatch for <file>: expected <hash>, actual <hash>`. For a non-default `version` with `debSha256` unchanged, the hash and the file come from the same release, so the check detects a damaged download but not a replaced release asset. Set `debSha256` to pin such a version. If the release API is unreachable, rate limited, or gives no digest, `install.sh` MUST exit 3 with one line. A change to the default version, the default hash, or the JSON defaults without the others MUST fail `bash scripts/verify.sh fast`. To bump the default, change the two constants in `install.sh` and the two JSON defaults in one commit.
- **FR-025**: Orca MUST start with `--refuse-public` (Decision 15). The flag MUST appear in the command line of the `orca-ide serve` process. Orca judges the TCP peer address: a client behind a Docker port forward arrives as a private address and a Tailscale userspace peer arrives as loopback, and both are accepted. A client on a public path is refused.
- **FR-026**: The GHCR package `ghcr.io/flumpiey/devcontainer-features/orca-server` MUST be public (Decision 19). `NOTES.md` MUST state the one-time step to set the visibility to public after the first publish.
- **FR-017**: `mobilePairing` true MUST add `--mobile-pairing`. `autoStart` false MUST install Orca and the start script and start nothing at entrypoint.
- **FR-018**: A port conflict, or any other exit of the Orca process after it started, MUST NOT stop the container. The log MUST record the failure as Orca output plus one line `orca-server: orca-ide exited with status <n>`. That line does not start with `orca-server: error:`, so criterion 6 counts only the no-Tailscale error. `status` MUST report `stopped`. Orca is not restarted automatically.
- **FR-019**: `installsAfter` MUST list `ghcr.io/tailscale/codespace/tailscale` and `ghcr.io/devcontainers-extra/features/tailscale`.
- **FR-020**: The Feature MUST NOT register accounts, install Tailscale, pair clients automatically, support the AppImage, or support arm64, Alpine, RPM or systemd.
- **FR-021**: A push to main that changes files under `src/orca-server/` MUST run the release workflow. The workflow MUST publish `ghcr.io/flumpiey/devcontainer-features/orca-server` only after the test workflow passes. The publish step publishes a version that is not yet in the registry. When the `version` in `devcontainer-feature.json` is unchanged, the publish step skips it, the workflow succeeds, and nothing new is published (the devcontainer CLI skips an existing version with a warning). A new version also regenerates `src/orca-server/README.md` as a pull request. The release workflow needs the permissions `packages: write`, `contents: write` and `pull-requests: write`. A pull request opened with `GITHUB_TOKEN` does not start workflows, so Dru runs `bash scripts/verify.sh ci` on the README pull request branch before merging it. The README pull request passes the same checks as any other change.
- **FR-022**: No token, auth key, pairing link or pairing grant MUST be written into an image layer. `install.sh` writes only `options.env` (option values), `remote-user`, the two installed scripts and the empty `/var/lib/orca-server`. `install.sh` MUST NOT start Orca and MUST NOT print a pairing link. The Feature MUST NOT read, store or log `TS_AUTH_KEY` or any Tailscale credential. Runtime secrets live only in the named volume.
- **FR-027**: `orca-server start` MUST start no second Orca process when one runs or when another `start` waits for Tailscale. It holds the lock file `/var/lib/orca-server/orca-server.lock` (mode 0600, owned by the remote user) from the start of the wait until Orca has launched. A second `start` that finds the lock held, or Orca running, exits 0 and starts nothing.
- **FR-028**: `install.sh` MUST validate options and exit 1 with one line on a bad value: `port` an integer from 1 to 65535, `tailscaleWaitSeconds` a non-negative integer, `version` equal to `latest` or matching `^[0-9]+\.[0-9]+\.[0-9]+$`.
- **FR-029**: The devcontainer CLI, shellcheck, shfmt and every GitHub Action that CI uses MUST be pinned to a full version or a commit SHA. The apt dependencies of the .deb resolve from the base distribution and are not pinned.
- **FR-030**: The test workflow MUST have the permission `contents: read` only and MUST use no secret. On pull requests, CI MUST also run the publish action in `validate-only` mode.
- **FR-031**: A bad published version is withdrawn by publishing a fixed patch version. Users can pin an exact version such as `:1.0.0`. `NOTES.md` MUST describe both steps and how to delete a package version in the GitHub package settings.

### Key Entities

- **Feature**: the `orca-server` package, with options, an install step, an entrypoint and a volume declaration.
- **Orca server process**: one `orca-ide serve` process per container, run as the remote user.
- **Pairing URL**: a one-line URL in `/var/lib/orca-server/pairing-url.txt` (mode 0600), replaced on each start.
- **Log**: `/var/lib/orca-server/orca-server.log` (mode 0600), truncated on each start.
- **Grant**: a revocable per-client credential held in the named volume. It stays valid until revoked.
- **Named volume**: `orca-server-data-${devcontainerId}`, mounted at `/var/lib/orca-server`.

## Success Criteria *(mandatory)*

### Acceptance Criteria (verbatim)

1. On mcr.microsoft.com/devcontainers/base:bookworm, base:jammy and base:noble, a build with the Feature at default options succeeds and "orca-ide --version" exits 0.
2. xvfb-run and libasound.so.2 are present after install.
3. With pairingAddress set to 127.0.0.1, an HTTP request to http://127.0.0.1:6768/ returns a status code below 500 within 90 seconds of container start.
4. With pairingAddress set to 127.0.0.1, within 90 seconds of container start, /var/lib/orca-server/pairing-url.txt exists and contains one line that starts with a URL scheme.
5. The entrypoint reaches exec "$@" within 2 seconds of starting, shown by two timestamped lines in /var/lib/orca-server/orca-server.log: one written when the entrypoint starts and one written immediately before exec "$@". Their timestamps differ by at most 2 seconds.
6. With no Tailscale and pairingAddress empty, /var/lib/orca-server/orca-server.log contains exactly one line that starts with "orca-server: error:", no orca-ide process runs, and the container stays up.
7. "orca-server status" prints "running" and exits 0 while Orca serves, and prints "stopped" and exits 3 after "orca-server stop".
8. /var/lib/orca-server is mode 0700, and pairing-url.txt and orca-server.log in it are mode 0600. All three are owned by the remote user, and the orca-ide process runs as the remote user.
9. Manual check: after pairing the desktop client and rebuilding the container, the desktop client reconnects with no new pairing URL.
10. A build with version set to a tag that has no .deb asset fails, and the build log names that tag.
11. shellcheck and shfmt -d report nothing for every script under src/ and test/.
12. A push to main publishes ghcr.io/flumpiey/devcontainer-features/orca-server:1 and the generated src/orca-server/README.md lists every option with its default.
13. With Tailscale logged in and pairingAddress empty, /var/lib/orca-server/pairing-url.txt is written within 90 seconds after Tailscale reports Running.
14. "orca-server url" and "orca-server url --mobile" each print exactly one line that starts with "orca://pair", and the two lines differ.
15. A build with option debSha256 set to a wrong value fails, and the build log names the expected hash and the actual hash.
16. The command line of the orca-ide serve process, read from /proc/<pid>/cmdline, contains "--refuse-public".
17. Without registry credentials, "devcontainer features info manifest ghcr.io/flumpiey/devcontainer-features/orca-server:1" succeeds.

### Measurable Outcomes

- **SC-001**: Dru adds one line to a project's devcontainer.json, rebuilds, runs `orca-server url` once, pairs, and needs no further step for that container.
- **SC-002**: After a rebuild with the existing volume, 100% of previously paired clients reconnect with no new pairing.
- **SC-003**: Container start is delayed by no more than 2 seconds by the Feature, on every start.
- **SC-004**: Every devcontainer with the Feature appears in Orca on Dru's PC, laptop and phone after its first pairing on each device.

## Assumptions

- Dru is the only user. The host is dru-main-pc, Docker Desktop on WSL2, amd64.
- The Tailscale Feature handles login, SSH and hostname. This Feature only reads its status.
- The newest passing release tag for the `version` default is chosen at plan time.
- GitHub release assets of stablyai/orca are reachable at build time.
- Orca's user-data directory can be redirected into `/var/lib/orca-server`. The plan phase confirms how.
- How tools chain several Feature entrypoints is not verified. The entrypoint ends with `exec "$@"` and a test with a second Feature entrypoint checks it.
- The repository setting "Allow GitHub Actions to create and approve pull requests" is on before the first release.- Clients pair manually with the printed URL. Revoking a grant is done in Orca and is out of scope.
