# Implementation Plan: orca-server devcontainer Feature

**Branch**: `001-orca-server-feature` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-orca-server-feature/spec.md`

**Research**: [docs/analysis/261123-orca-server-feature.md](../../docs/analysis/261123-orca-server-feature.md) and [research.md](research.md). Where the analysis disagrees with an earlier plan statement, the analysis wins. Changes are listed under "Plan changes from research".

## Summary

Publish one devcontainer Feature, `orca-server`, to `ghcr.io/flumpiey/devcontainer-features`. `install.sh` installs the Orca `.deb` (default `v1.4.271`) with `apt-get`. An entrypoint waits for Tailscale, resolves the address, and starts `orca-ide serve` in the background as the remote user. User data lives in a named volume through `ORCA_USER_DATA`, so grants survive rebuilds. A control script `orca-server` offers `start`, `stop`, `status` and `url`.

## Technical Context

**Language/Version**: Bash 5 (Debian 12, Ubuntu 22.04, Ubuntu 24.04 bases)

**Primary Dependencies**: Orca `.deb` v1.4.271 (`orca-ide`), `curl`, `jq`, `apt-get`, `runuser`; optional `tailscale` CLI at run time

**Storage**: named volume `orca-server-data-${devcontainerId}` at `/var/lib/orca-server`

**Testing**: `devcontainer features test` with `scenarios.json`; `shellcheck`, `shfmt -d`, `jq`; one entry point `bash scripts/verify.sh {fast|push|ci}`

**Target Platform**: Debian 12, Ubuntu 22.04, Ubuntu 24.04, amd64, Docker Desktop on WSL2

**Project Type**: devcontainer Feature repository

**Performance Goals**: entrypoint adds at most 2 s to container start (spec FR-012); Orca ready within 90 s

**Constraints**: no secret in an image layer; entrypoint never blocks and ends with `exec "$@"`; idempotent install

**Scale/Scope**: one Feature, seven options (`version`, `pairingAddress`, `port`, `mobilePairing`, `autoStart`, `tailscaleWaitSeconds`, `debSha256`), one control script, three base images in CI

## Constitution Check

*Gate before Phase 0. Re-checked after Phase 1.*

| # | Principle | Plan response | Status |
|---|-----------|---------------|--------|
| I | Spec-compliant Features | Layout `src/orca-server/{devcontainer-feature.json,install.sh}`, `test/orca-server/{test.sh,scenarios.json}` | Pass |
| II | Bash only | All scripts Bash with `set -euo pipefail`; `verify.sh fast` runs shellcheck and `shfmt -d -i 2` | Pass |
| III | Idempotent installs | Install step skips when `dpkg-query` shows the resolved `orca-ide` version already installed; test runs `install.sh` twice | Pass |
| IV | Pinned versions | `version` option defaults to `1.4.271`; `latest` is explicit only | Pass: option `debSha256` pins the default version (Decision 20, research.md D2) |
| V | No secrets in images | Pairing URL, log and grants are written at run time into the volume only (directory 0700, files 0600); `options.env` holds no secret | Pass |
| VI | Entrypoints never block | Orca starts in the background; Tailscale wait runs inside that background job; entrypoint ends with `exec "$@"`; every step before it is guarded with `|| log`, and an `ERR` trap runs `exec "$@"`, so no failure skips `exec` (spec FR-009) | Pass |
| VII | Debian and Ubuntu first | `install.sh` reads `/etc/os-release` and `uname -m`; any other base exits 1 with one line | Pass |
| VIII | Tests before done | Every slice ends with `bash scripts/verify.sh fast`; the last slice runs `ci` | Pass |
| IX | Conventional Commits, no AI attribution | Existing `commitlint.config.mjs` and `lefthook.yml` already enforce this; Slice 1 adds `.claude/settings.json` | Pass |
| X | British spelling, no dashes or emojis | Docs follow it; `verify.sh fast` greps docs for en dashes, em dashes, emojis and a list of US spellings | Pass |
| XI | Smallest change | No tarball path, no extra options, no systemd; see Complexity Tracking | Pass |

Post-design re-check: pass. No principle is violated.

## Project Structure

### Documentation (this feature)

```text
specs/001-orca-server-feature/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── feature-options.md
│   └── orca-server-cli.md
└── tasks.md             # created by /speckit-tasks
docs/analysis/261123-orca-server-feature.md
```

### Source Code (repository root)

```text
src/orca-server/
├── devcontainer-feature.json
├── install.sh
├── entrypoint.sh
├── orca-server            # control script, installed to /usr/local/bin
└── NOTES.md
test/orca-server/
├── test.sh
├── scenarios.json
├── <scenario>.sh          # one per scenario
├── build-fails.sh         # expected build failures, runs `devcontainer build` itself
└── secrets_scan.sh        # builds the default image with `devcontainer build`, then scans it
test/_global/              # only for the Tailscale ordering and entrypoint chaining scenario
scripts/verify.sh          # modes: fast, push, ci
.github/workflows/test.yaml
.github/workflows/release.yaml
.claude/settings.json
README.md
```

Already present and kept: `package.json`, `package-lock.json`, `lefthook.yml`, `commitlint.config.mjs`.

**Structure Decision**: the standard Feature repository layout from containers.dev. One Feature, no shared library.

## Plan changes from research

1. The .deb declares libasound, Xvfb, libgbm1 and libnss3. The install step installs only the .deb. No extra package list.
2. No symlink. `ORCA_USER_DATA=/var/lib/orca-server` redirects user data (orcad runtime).
3. `--supervise` is not used, because it redacts the pairing line.
4. One `serve` start prints one link kind. With `mobilePairing` true the printed link is the mobile link. See Decisions recorded, item 1.
5. `release.yaml` needs `contents: write`, `pull-requests: write` and `packages: write`. Docs arrive as a pull request.
6. Package manager stays npm, because `package-lock.json` exists. `commitlint.config.mjs` stays. Slice 1 does not create `commitlint.config.js`. Lefthook already has the `commit-msg` hook, so Slice 1 only adds `pre-commit`.
7. The default Orca version is `1.4.271`, the newest tag at 2026-11-23. The tag must pass the test suite before Slice 5 closes.
8. `serve` always gets `--refuse-public` (Decision 15, research.md D10).
9. The .deb gets a SHA-256 check (Decision 16, research.md D2). This replaces the earlier "no checksum" position.

## Decisions recorded (2026-11-23)

These are also in spec.md, Decisions 14 to 20. Items 1 to 3 below cover Decisions 14 to 16. Items 4 to 8 cover Decisions 17 to 20.

1. `orca-server url` prints the desktop link from `orca-ide pair --address <addr>`. `orca-server url --mobile` prints the mobile link from `orca-ide pair --mobile --address <addr>`. `mobilePairing` stays default true, so `serve` still gets `--mobile-pairing`. `pairing-url.txt` keeps the link printed at start. `url` reuses an unused offer, so repeated calls do not create new grants.
2. `serve` always gets `--refuse-public`. Orca treats 100.64.0.0/10 and fd7a:115c:a1e0::/48 as class `tailnet`, which it accepts. Public peers are refused. Consequence: a client that reaches the server through a public path cannot connect.
3. Keep the .deb for 1.0.0. The option `debSha256` defaults to `7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755`. `install.sh` holds the default version and default hash as constants. The JSON defaults MUST equal them, and `verify.sh fast` checks this. If `version` is not the default and `debSha256` is unchanged, `install.sh` takes the digest from the release API. A non-default `debSha256` is always used. A mismatch exits 3 and names both hashes.
4. Log and modes (Decisions 17, 18). The log moves to `/var/lib/orca-server/orca-server.log`. The directory is 0700 and `pairing-url.txt` and the log are 0600, all owned by the remote user. The entrypoint runs `umask 077`, creates the files, and runs `chown` and `chmod` at each start. The entrypoint and `orca-server start` truncate the log at each Orca start. The log writes use the `orca-server:` prefix. `start` takes a lock file `orca-server.lock`, so a second `start` starts no second process (FR-027). `start` resolves the address in the foreground and exits 1 on failure. The entrypoint runs it detached.
5. Tailscale wait (Decision 5). With `pairingAddress` set, the entrypoint skips the wait and never calls `tailscale`. Acceptance criteria 3 and 4 run with `pairingAddress` set to 127.0.0.1. Criterion 13 covers the Tailscale path.
6. 2 second rule (FR-012). The entrypoint writes `orca-server: <UTC time> entrypoint: start` first and `orca-server: <UTC time> entrypoint: exec` immediately before `exec "$@"`. Time format `date -u +%Y-%m-%dT%H:%M:%S.%3NZ`. Everything slow runs in the background job after the first line.
7. Public package (Decision 19). The release workflow cannot set package visibility with `GITHUB_TOKEN`. The step is manual and one time. `NOTES.md` states it: GitHub, Packages, `orca-server`, Package settings, Change visibility, Public. A later check runs `devcontainer features info manifest` without credentials (criterion 17).
8. Test scope (Slice 4, below).
9. Version bump procedure (FR-024). Change `DEFAULT_VERSION` and `DEFAULT_DEB_SHA256` in `install.sh` and the `version` and `debSha256` defaults in `devcontainer-feature.json` in one commit, with the new digest from `gh api repos/stablyai/orca/releases/tags/v<version>`. `verify.sh fast` fails when they differ. `test.sh` checks the installed version equals the default.
10. Pins (FR-029). The devcontainer CLI, shellcheck, shfmt and every GitHub Action in CI are pinned to a full version or SHA. apt dependencies of the .deb are not pinned.
11. Publish rules (FR-021, FR-030, FR-031). `test.yaml` has `contents: read` only and no secret, and runs the action with `validate-only` on pull requests. `release.yaml` needs the test workflow to pass. An unchanged version is skipped and the run succeeds, because the CLI skips an existing version. The README pull request is opened with `GITHUB_TOKEN`, so it starts no workflow. Dru runs `verify.sh ci` on its branch before merging. A bad version is withdrawn by publishing a fixed patch version. `NOTES.md` says how.
12. Extra option checks (FR-028, convergence T068). `install.sh` also requires `mobilePairing` and `autoStart` to be `true` or `false`, `pairingAddress` to hold only letters, digits and `. _ : -`, and `debSha256` to be 64 hex digits. Kept: `orca-server` and the entrypoint source `options.env` as shell, so an unchecked value could run code. `build-fails.sh` tests the address filter.
13. Action CLI pin (FR-029, convergence T060). The `devcontainers/action` steps set `devcontainer-cli-version` to the version in `verify.sh`, because the action defaults to the latest CLI.

## Implementation slices

Each slice ends with `bash scripts/verify.sh fast` and a hard stop.

- **Slice 1. Repo tooling.** `scripts/verify.sh` (fast: shellcheck, `shfmt -d -i 2`, `set -euo pipefail` check, `jq empty` on every JSON file, dash, emoji and US spelling grep on docs, checking only paths that exist; push: fast plus one scenario; ci: fast plus every scenario on bookworm, jammy and noble). Add a `pre-commit` entry to `lefthook.yml` that runs `bash scripts/verify.sh fast`. Add `.claude/settings.json` with the attribution setting (check the keys against the installed CLI first). Add `README.md` with the usage snippet. Hard stop before any file under `src/`.
- **Slice 2. install.sh and devcontainer-feature.json.** OS and architecture check, version resolution, .deb download with `curl --retry`, SHA-256 check (fail naming both hashes), `apt-get install`, `options.env`, `remote-user`, volume directory ownership, idempotency. Hard stop before `entrypoint.sh`.
- **Slice 3. entrypoint.sh and orca-server.** Background launch, Tailscale wait and address resolution, `ORCA_USER_DATA`, `runuser` when root, pairing URL extraction, PID file, status codes, `url` and `url --mobile` through `orca-ide pair`, `--refuse-public`, `exec "$@"`. Hard stop before any test file.
- **Slice 4. Tests.** `scenarios.json` (image placeholder `__BASE__`, replaced per base by `verify.sh`, so every scenario runs on bookworm, jammy and noble), scenario scripts; `.github/workflows/test.yaml` runs `bash scripts/verify.sh ci` on pull requests and pushes. Hard stop before `release.yaml`. Test scope, one row per acceptance criterion (tasks.md Phase 7):

  | Criterion | Verified by |
  |-----------|-------------|
  | 1, 2 | `test/orca-server/test.sh`, run on three bases with `--base-image` |
  | 3, 5, 16 | scenario `local_address` (`local_address.sh`), no Tailscale needed because `pairingAddress` is set |
  | 4, 8, 14 | scenario `pairing_files` (`pairing_files.sh`) |
  | 6 | scenario `no_tailscale` (`no_tailscale.sh`), a base with no Tailscale |
  | 7 | scenario `control` (`control.sh`) |
  | 10, 15 | `build-fails.sh` (expected build failures) |
  | 11 | `verify.sh fast` |
  | 13 | `test/_global` scenario with a stub `tailscale` command. A run with a real Tailscale login is manual (task T055). |
  | 9 | manual (task T055, `quickstart.md` step 4), result recorded in `docs/analysis/261123-orca-server-feature.md` with date, client version and outcome |
  | 12 | first release run (task T052), after a `validate-only` run on pull requests |
  | 17 | task T054 after the first publish and the manual visibility step, with an empty `DOCKER_CONFIG` |

  Edge cases and requirements without their own criterion:

  | Case | Verified by |
  |------|-------------|
  | Tailscale absent, or present but not logged in | `no_tailscale.sh` (same wait-end path) |
  | Port in use, Orca crash, restart without rebuild, second `start` | `control.sh`, `local_address.sh` |
  | Install twice, different options | `install_twice.sh` |
  | Unsupported base, no .deb asset, bad hash, root remote user | `build-fails.sh` |
  | Non-root user | `local_address.sh` |
  | Rebuild with existing volume | manual, task T055 |
  | FR-022 no secret in image layers | `secrets_scan.sh` |
  | FR-024 constants equal JSON defaults | `verify.sh fast` |

- **Slice 5. Release.** `.github/workflows/release.yaml` with `devcontainers/action@v1.4.4` (pinned, FR-029), the three permissions, `generate-docs`. `NOTES.md` covers pair once, manual re-pair fallback, example `devcontainer.json` with the Tailscale Feature, the one-time step to set the package visibility to public after the first publish, and how to withdraw a bad version. Then run `quickstart.md` and tick `tasks.md`.

## Complexity Tracking

No constitution violations. One accepted addition: the `--mobile` flag on `url`, decided by Dru. Items rejected to stay small: the server-only tarball path, a symlink for user data, extra Feature options, a systemd unit, and a second package manager.
