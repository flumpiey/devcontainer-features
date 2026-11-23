# Tasks: orca-server devcontainer Feature

**Input**: Design documents from `specs/001-orca-server-feature/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Required. The spec has 17 acceptance criteria and constitution principle VIII says a change is done only when `bash scripts/verify.sh ci` passes. Test tasks are in Phase 7, because plan.md fixes "Hard stop: before any test file" at the end of the entrypoint slice.

**Organisation**: Phases follow plan.md slices and their hard stops. Tasks carry the user story label from spec.md where one applies. Every `STOP` line is a plan hard stop: do not start the next phase until Dru confirms.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1 Install, US2 Start on the tailnet, US3 Pair once, US4 Control, US5 Publish
- Paths are relative to the repository root
- `data-model.md` is the canonical source for field constraints. Tasks cite it as `data-model.md <section>.<field>`
- Every shell script starts with `set -euo pipefail` (constitution II), except that `entrypoint.sh` guards each step as T023 says
- Commit and push only with Dru's explicit permission in the current conversation

## Phase 1: Setup (Slice 1, repo tooling)

**Purpose**: verification and commit tooling. No file under `src/`.

- [X] T001 Create `scripts/verify.sh` with modes `fast`, `push`, `ci`. `fast` checks only paths that exist, so it passes before `src/` exists, and it fails loud when a tool is missing: shellcheck on every `*.sh` under `src/`, `test/`, `scripts/` plus `src/orca-server/orca-server`; `shfmt -d -i 2` on the same files; each of those files has `set -euo pipefail` within its first 5 lines; `jq empty` on every `*.json`; a grep of `docs/`, `specs/`, `README.md` and `src/**/NOTES.md` for en dashes, em dashes, emojis and ten common US spellings. Keep the word list inside `scripts/verify.sh`, which the grep does not scan, so no spec file has to contain the words. `push` and `ci` call `fast` and print `not wired yet` until T045. Start with `set -euo pipefail`.
- [X] T002 [P] Add a `pre-commit` entry to `lefthook.yml` that runs `bash scripts/verify.sh fast`. Keep the existing `commit-msg` hook unchanged.
- [X] T003 [P] Create `.claude/settings.json` with `{"attribution": {"commit": "", "pr": ""}}`. First confirm the keys against the installed Claude Code CLI (research item R7 is unverified). If the keys differ, fix the file and update `docs/analysis/261123-orca-server-feature.md` R7.
- [X] T004 [P] Create `README.md` with the usage snippet from `contracts/feature-options.md` and a link to `src/orca-server/NOTES.md`.
- [X] T005 Run `bash scripts/verify.sh fast` and fix failures.

**STOP**: plan hard stop before any file under `src/`.

---

## Phase 2: Foundational (Slice 2, Feature metadata)

**Purpose**: the Feature metadata every story depends on.

- [X] T006 Create `src/orca-server/devcontainer-feature.json` per `contracts/feature-options.md` (FR-001, FR-007, FR-008): `id` `orca-server`, `version` `1.0.0`, `name`, `description`, the seven options with the listed defaults, `installsAfter` (FR-019), `entrypoint` `/usr/local/share/orca-server/entrypoint.sh`, `mounts` volume `orca-server-data-${devcontainerId}` at `/var/lib/orca-server`. Option defaults follow `data-model.md options.env keys.VERSION`, `.PORT`, `.TAILSCALE_WAIT_SECONDS` and `.DEB_SHA256`.
- [X] T007 Run `bash scripts/verify.sh fast`.

---

## Phase 3: User Story 1 - Install (Priority: P1) MVP

**Goal**: the build installs `orca-ide`, Xvfb and libasound on Debian 12, Ubuntu 22.04 and Ubuntu 24.04, amd64, with a verified download.

**Independent Test**: build a container from each base with default options and run `orca-ide --version`. Run `install.sh` twice.

- [X] T008 [US1] Create `src/orca-server/install.sh`: shebang, `set -euo pipefail`, constants `DEFAULT_VERSION=1.4.271` and `DEFAULT_DEB_SHA256=7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755`, one `fail` helper that prints `orca-server: error: <message>` and exits with a given code, and reads of the option variables `VERSION`, `PAIRINGADDRESS`, `PORT`, `MOBILEPAIRING`, `AUTOSTART`, `TAILSCALEWAITSECONDS`, `DEBSHA256` (`contracts/feature-options.md`).
- [X] T009 [US1] In `src/orca-server/install.sh`, add the base check from `/etc/os-release` and `uname -m`: allow Debian 12, Ubuntu 22.04, Ubuntu 24.04 on `x86_64`. Otherwise exit 1 with one line naming the detected OS and architecture (FR-004).
- [X] T010 [US1] In `src/orca-server/install.sh`, validate options and exit 1 with one line on a bad value (FR-028): `PORT` integer 1 to 65535 (`data-model.md Validation rules.port`), `TAILSCALEWAITSECONDS` non-negative integer (`data-model.md Validation rules.tailscaleWaitSeconds`), `VERSION` equal to `latest` or matching `^[0-9]+\.[0-9]+\.[0-9]+$` (`data-model.md Validation rules.version`).
- [X] T011 [US1] In `src/orca-server/install.sh`, install `curl`, `ca-certificates` and `jq` with `apt-get`. Resolve `latest` through `https://api.github.com/repos/stablyai/orca/releases/latest`. If that call fails, exit 2 with one line (FR-003). Build the asset URL `https://github.com/stablyai/orca/releases/download/v<version>/orca-ide_<version>_amd64.deb` (research D1, analysis R2).
- [X] T012 [US1] In `src/orca-server/install.sh`, download the .deb to a temp file with `curl --fail --location --retry 3`. On HTTP 404 exit 2 with one line naming the tag and the URL tried (FR-005).
- [X] T013 [US1] In `src/orca-server/install.sh`, resolve the expected hash per Decision 20: a `DEBSHA256` that differs from `DEFAULT_DEB_SHA256` is used as is. If the resolved version is not `DEFAULT_VERSION` and `DEBSHA256` equals the default, read `assets[].digest` for the .deb from `https://api.github.com/repos/stablyai/orca/releases/tags/v<version>`. If the API fails, is rate limited, or gives no digest, exit 3 with one line. Compare with `sha256sum`. On mismatch exit 3 with exactly `orca-server: error: sha256 mismatch for <file>: expected <hash>, actual <hash>` (FR-024).
- [X] T014 [US1] In `src/orca-server/install.sh`, install with `apt-get install -y ./<file>.deb`, so the dependencies the .deb declares resolve and no separate package list exists (FR-002). Skip the download and install when `dpkg-query -W -f='${Version}' orca-ide` already equals the resolved version. Install in place when it differs (FR-006). Remove the temp file.
- [X] T015 [US1] In `src/orca-server/install.sh`, write `/usr/local/share/orca-server/options.env` (keys `VERSION`, `PAIRING_ADDRESS`, `PORT`, `MOBILE_PAIRING`, `AUTO_START`, `TAILSCALE_WAIT_SECONDS`, `DEB_SHA256` per `data-model.md options.env keys`, mapped from the variables in T008, no secret, rewritten on each run) and `/usr/local/share/orca-server/remote-user` (one line from `_REMOTE_USER`). If `_REMOTE_USER` is empty or `root`, exit 1 with one line (FR-014). Write no pairing link and start no Orca (FR-022).
- [X] T016 [US1] In `src/orca-server/install.sh`, create `/var/lib/orca-server` owned by the remote user, mode 0700 (`data-model.md Run-time state./var/lib/orca-server`, FR-015, Decision 18), so a new named volume inherits owner and mode.
- [X] T017 [US1] Add a check to `scripts/verify.sh` `fast`: `DEFAULT_VERSION` and `DEFAULT_DEB_SHA256` in `src/orca-server/install.sh` equal the `version` and `debSha256` defaults in `src/orca-server/devcontainer-feature.json` (FR-024, Decision 20).
- [X] T018 [US1] Run `bash scripts/verify.sh fast`.

**STOP**: plan hard stop before `entrypoint.sh`.

---

## Phase 4: User Story 2 - Start on the tailnet (Priority: P1)

**Goal**: at container start, Orca serves in the background on the resolved address, and the entrypoint reaches `exec "$@"` within 2 seconds.

**Independent Test**: start a container with `pairingAddress` set to `127.0.0.1` and request `http://127.0.0.1:6768/`.

- [ ] T019 [US2] Create `src/orca-server/orca-server`: shebang, `set -euo pipefail`, source `/usr/local/share/orca-server/options.env`, path constants (`/var/lib/orca-server`, `orca-server.log`, `orca-server.pid`, `orca-server.lock`, `pairing-url.txt`), a `log` helper that appends `orca-server: <message>` and an `err` helper for `orca-server: error: <message>`, dispatch for `start`, `stop`, `status`, `url`, and usage on stderr with exit 2 for any other input (`contracts/orca-server-cli.md`).
- [ ] T020 [US2] In `src/orca-server/orca-server`, add `resolve_address`: when `PAIRING_ADDRESS` is set, print it and never call `tailscale` (FR-010). Otherwise poll `timeout 5 tailscale status --json | jq` until `BackendState` is `Running` or `TAILSCALE_WAIT_SECONDS` elapse (0 means one check). Print `Self.DNSName` without the trailing dot, else `Self.TailscaleIPs[0]`. If not Running at the end, write one `err` line and return 1 (FR-011).
- [ ] T021 [US2] In `src/orca-server/orca-server`, add `start`: create `orca-server.lock` mode 0600 (`data-model.md Run-time state./var/lib/orca-server/orca-server.lock`), take `flock -n` on it, and exit 0 if the lock is held or Orca runs (FR-027). When run as root, re-run as the remote user with `runuser --preserve-environment -u "$(cat /usr/local/share/orca-server/remote-user)"` (FR-014). Truncate the log (mode 0600) unless `ORCA_SERVER_LOG_FRESH=1`. Run `resolve_address` in the foreground and exit 1 on failure (`contracts/orca-server-cli.md`). Export `ORCA_USER_DATA=/var/lib/orca-server` and `ORCA_SERVE_RUNTIME=orcad` (research D4). Launch `orca-ide serve --port "$PORT" --pairing-address "$addr" --refuse-public` (FR-025), plus `--mobile-pairing` when `MOBILE_PAIRING=true` (FR-017), with stdout and stderr to the log. Write the PID to `orca-server.pid`, release the lock, and return at once. Do not use `--supervise` (analysis R4).
- [ ] T022 [US2] In `src/orca-server/orca-server`, make the background watcher append `orca-server: orca-ide exited with status <n>` and remove `orca-server.pid` when the Orca process exits, so a port conflict or crash leaves `status` at `stopped` and Orca is not restarted (FR-018).
- [ ] T023 [US2] Create `src/orca-server/entrypoint.sh`: `set -euo pipefail`, `umask 077`, and `trap 'log "entrypoint step failed"; exec "$@"' ERR`. Guard every command that can fail with `|| log "..."`, and read variables as `${VAR:-}`, so no failure prevents `exec "$@"` (FR-009, constitution II and VI). Enforce owner (remote user) and mode of `/var/lib/orca-server` (0700), `pairing-url.txt` and `orca-server.log` (0600) (FR-015, `data-model.md Run-time state./var/lib/orca-server`, `.pairing-url.txt` and `.orca-server.log`). Truncate the log and write `orca-server: <UTC time> entrypoint: start`, time from `date -u +%Y-%m-%dT%H:%M:%S.%3NZ`. If `AUTO_START` is `true` (FR-017), run `ORCA_SERVER_LOG_FRESH=1 orca-server start` detached (`setsid`, output to the log), as `runuser --preserve-environment` when root. Write `orca-server: <UTC time> entrypoint: exec`, then `exec "$@"` (FR-012). When `AUTO_START` is `false`, skip the start only.
- [ ] T024 [US2] In `src/orca-server/install.sh`, copy `entrypoint.sh` to `/usr/local/share/orca-server/entrypoint.sh` and `orca-server` to `/usr/local/bin/orca-server`, both mode 0755.

---

## Phase 5: User Story 3 - Pair once (Priority: P1)

**Goal**: the user reads one desktop link and one mobile link, pairs, and after a rebuild the clients reconnect.

**Independent Test**: with Orca running, `orca-server url` and `orca-server url --mobile` each print one `orca://pair` line and the lines differ.

- [ ] T025 [US3] In `src/orca-server/orca-server` `start`, delete any old `pairing-url.txt`. In the background watcher, poll the log every second while the Orca process lives, take the first line that starts with `Pairing URL: `, and write the rest to `pairing-url.txt` as exactly one line, mode 0600 (FR-013, `data-model.md Validation rules.pairing-url.txt`, research D6).
- [ ] T026 [US3] In `src/orca-server/orca-server`, add `url` and `url --mobile`: fail with one `err` line and exit 1 if Orca is not running. Run `orca-ide pair --address "$addr"` (plus `--mobile` for the mobile form) with `ORCA_USER_DATA` set, as the remote user. Print only the first token that matches `orca://pair[^[:space:]]*`, exactly one line. Exit 1 with one `err` line when pairing is unavailable (FR-023, research D11). Reject any other flag with usage and exit 2.
- [ ] T027 [US3] In `src/orca-server/orca-server`, confirm `ORCA_USER_DATA` is exported on every path that runs `orca-ide`, so grants live in the volume (Decision 9, FR-008).

---

## Phase 6: User Story 4 - Control (Priority: P2)

**Goal**: stop, start and check Orca with the `orca-server` command.

**Independent Test**: run `status`, `stop`, `status`, `start`, `status`.

- [ ] T028 [US4] In `src/orca-server/orca-server`, add `status`: running means the PID file exists, the process lives, and `/proc/<pid>/cmdline` contains `orca-ide`. Print `running` and exit 0, or print `stopped` and exit 3. A stale PID file counts as stopped and is removed (FR-016).
- [ ] T029 [US4] In `src/orca-server/orca-server`, add `stop`: send TERM to the process group, send KILL after 10 seconds if it still lives, remove the PID file. Exit 0 also when already stopped.
- [ ] T030 [US4] Run `bash scripts/verify.sh fast` and fix failures in `src/`.

**STOP**: plan hard stop before any test file.

---

## Phase 7: Tests (Slice 4)

**Purpose**: cover acceptance criteria 1 to 8, 10, 11 and 13 to 16 (spec Acceptance Criteria), plus FR-022. Criteria 9, 12 and 17 are in Phase 8.

- [ ] T031 Confirm the `test/_global/` layout and the scenario-matrix approach: read `devcontainer features test --help` and the CLI test docs for the installed CLI. Record the result in `docs/analysis/261123-orca-server-feature.md` R6.
- [ ] T032 Create `test/orca-server/scenarios.json` with the scenarios `local_address` (`pairingAddress` `127.0.0.1`), `pairing_files` (same), `control` (same), `no_tailscale` (empty `pairingAddress`, `tailscaleWaitSeconds` low), `install_twice`. Each `image` is the placeholder `__BASE__`, replaced per base by `verify.sh` (T045). Each key matches a script in T034 to T039. The default test is `test/orca-server/test.sh` (FR-001), run by `devcontainer features test` once per base.
- [ ] T033 [P] [US1] Create `test/orca-server/test.sh`: use the `dev-container-features-test-lib`. Check `orca-ide --version` (AC 1), `xvfb-run` and `libasound.so.2` through `ldconfig -p` (AC 2).
- [ ] T034 [P] [US2] Create `test/orca-server/local_address.sh`: poll `http://127.0.0.1:6768/` for status below 500 within 90 seconds (AC 3). Read the two timestamped log lines and check their difference is at most 2 seconds (AC 5). Read `/proc/<pid>/cmdline` of `orca-ide serve` and check it contains `--refuse-public` (AC 16). Check the process runs as the remote user (AC 8). Check `--refuse-public` is present as FR-025 requires. Check that the second `orca-server start` starts no second process (FR-027).
- [ ] T035 [P] [US3] Create `test/orca-server/pairing_files.sh`: `pairing-url.txt` exists within 90 seconds and holds one line with a URL scheme (AC 4). `orca-server url` and `url --mobile` each print exactly one `orca://pair` line and the two differ (AC 14). Check modes 0700 and 0600 and the owner (AC 8).
- [ ] T036 [P] [US4] Create `test/orca-server/control.sh`: `status` prints `running`, exit 0, then after `stop` prints `stopped`, exit 3 (AC 7). Run `stop`, bind a listener on the port, run `start`, and check the container stays up and `status` reports `stopped`. Kill Orca and check the log has the exit line. Restart without rebuild and check `pairing-url.txt` is replaced.
- [ ] T037 [P] [US2] Create `test/orca-server/no_tailscale.sh`: with no Tailscale and empty `pairingAddress`, the log has exactly one line starting with `orca-server: error:`, no `orca-ide` process runs, and the container stays up (AC 6).
- [ ] T038 [P] [US2] Create a `test/_global/` scenario with a stub `tailscale` command that prints `Running` JSON after a delay, and an extra Feature with its own entrypoint. Check `pairing-url.txt` is written within 90 seconds after the stub reports Running (AC 13) and that both entrypoints run (research D7, analysis R1).
- [ ] T039 [P] [US1] Create `test/orca-server/install_twice.sh`: run `install.sh` a second time with the same options and expect exit 0, one installed `orca-ide` package, and unchanged `options.env`, owner and mode (FR-006).
- [ ] T040 [P] [US1] Create `test/orca-server/build-fails.sh`: run `devcontainer build` expecting failure for (a) a `version` with no .deb asset, log names the tag (AC 10), (b) a wrong `debSha256`, log names expected and actual hash (AC 15), (c) an unsupported base `debian:11`, one line names OS and architecture (FR-004), (d) `remoteUser` root (FR-014).
- [ ] T041 [P] [US1] Create `test/orca-server/secrets_scan.sh`: run `devcontainer build` for the default configuration, then grep `options.env`, `remote-user` and `docker history --no-trunc` output for `orca://pair`, `TS_AUTH_KEY` and `tskey-` and expect no match (FR-022).
- [ ] T042 [US2] Decide the Xvfb question (research D5): run `orca-ide serve` with no `DISPLAY` inside `local_address.sh`. If it fails, wrap the launch in `xvfb-run -a` in `src/orca-server/orca-server`. Record the result in `research.md` D5.
- [ ] T043 [US2] Add a non-root start check to `test/orca-server/local_address.sh`: the entrypoint runs as the remote user and starts Orca directly (Edge Cases).
- [ ] T044 [US1] Add a check to `test/orca-server/test.sh` that `dpkg-query -W -f='${Version}' orca-ide` equals the `version` default in `src/orca-server/devcontainer-feature.json`, so the default is a version the suite has installed (constitution IV).
- [ ] T045 Wire `push` and `ci` in `scripts/verify.sh` (FR-029): `push` runs `fast` plus `devcontainer features test -f orca-server --base-image mcr.microsoft.com/devcontainers/base:bookworm` (the default test `test.sh`). `ci` runs `fast`, then for each base `mcr.microsoft.com/devcontainers/base:bookworm`, `:jammy` and `:noble` it runs the default test with `--base-image`, writes a copy of `scenarios.json` with `jq` replacing `__BASE__`, and runs every scenario, then `test/_global`, then `build-fails.sh` and `secrets_scan.sh`. Pin the devcontainer CLI version in the script.
- [ ] T046 Create `.github/workflows/test.yaml`: triggers `pull_request`, `push` and `workflow_call`, `permissions: contents: read`, no secrets, pinned shellcheck, shfmt, devcontainer CLI and actions (FR-029, FR-030), with `devcontainers/action@v1.4.4`. Run `bash scripts/verify.sh ci`. On `pull_request`, also run `devcontainers/action` with `validate-only: "true"` and `base-path-to-features: ./src`.
- [ ] T047 Run `bash scripts/verify.sh ci` and fix failures. Record the result in `docs/analysis/261123-orca-server-feature.md`.

**STOP**: plan hard stop before `release.yaml`.

---

## Phase 8: User Story 5 - Publish (Priority: P2)

**Goal**: a push to main that changes the Feature publishes `ghcr.io/flumpiey/devcontainer-features/orca-server:1` and regenerates the README.

**Independent Test**: the first release run publishes the package and opens the README pull request.

- [ ] T048 [US5] Create `.github/workflows/release.yaml`: trigger `push` to `main` with paths `src/orca-server/**`, a job that calls `test.yaml` and a publish job that `needs` it, `permissions` `packages: write`, `contents: write`, `pull-requests: write`, step `devcontainers/action@v1.4.4` with `publish-features: "true"`, `base-path-to-features: ./src`, `generate-docs: "true"`. An unchanged `version` is skipped by the publish step and the workflow succeeds (FR-021).
- [ ] T049 [US5] Create `src/orca-server/NOTES.md`: pair once with `orca-server url` and `orca-server url --mobile`, the manual re-pair fallback, the example `devcontainer.json` with `ghcr.io/tailscale/codespace/tailscale`, file and log locations with modes, the one-time step to set the package visibility to public after the first publish (FR-026), and how to withdraw a bad version and delete a package version (FR-031).
- [ ] T050 [US5] Run `bash scripts/verify.sh fast`.
- [ ] T051 [US5] MANUAL (Dru): in the repository settings, enable "Allow GitHub Actions to create and approve pull requests".
- [ ] T052 [US5] MANUAL (Dru): after Dru approves a commit and push, watch the first release run on `main`. Check `ghcr.io/flumpiey/devcontainer-features/orca-server:1` exists and the README pull request lists every option with its default (AC 12). Run `bash scripts/verify.sh ci` on that pull request branch, then merge it (FR-021).
- [ ] T053 [US5] MANUAL (Dru): on GitHub open the package `orca-server`, Package settings, Change visibility, Public (Decision 19).
- [ ] T054 [US5] Run `DOCKER_CONFIG="$(mktemp -d)" devcontainer features info manifest ghcr.io/flumpiey/devcontainer-features/orca-server:1` and expect exit 0 (AC 17).
- [ ] T055 [US3] MANUAL (Dru): on the real tailnet, pair the desktop client, rebuild the container, and check the client reconnects with no new pairing URL (AC 9, `quickstart.md` step 4). Also check the real Tailscale path of AC 13. Record date, Orca client version and pass or fail in `docs/analysis/261123-orca-server-feature.md`.

---

## Phase 9: Polish and cross-cutting

- [ ] T056 Update `docs/analysis/261123-orca-server-feature.md` with the results for the unverified items: entrypoint chaining (T038), `attribution` keys (T003), `ORCA_USER_DATA` under the Electron fallback, `pair` output token (T026).
- [ ] T057 Run every step in `specs/001-orca-server-feature/quickstart.md`.
- [ ] T058 Run `bash scripts/verify.sh ci` one last time and tick the completed items in this file. Confirm the FR-020 out-of-scope items (account registration, Tailscale install, auto-pairing, AppImage, arm64, Alpine, RPM, systemd) are absent from `src/`.

---

## Dependencies and execution order

- Phase 1 then Phase 2 then Phase 3. Each STOP needs Dru's go-ahead.
- Phases 4, 5 and 6 edit the same file `src/orca-server/orca-server`, so their tasks run in the listed order. T023 depends on T019 to T022. T026 depends on T020. T024 depends on T023.
- Phase 7 depends on Phases 3 to 6. T033 to T041 are independent files and run in parallel after T032. T045 depends on T032 to T041.
- Phase 8 depends on T047. T052 depends on T051. T053 depends on T052. T054 depends on T053. T055 depends on T052.

### Parallel examples

- Phase 1: T002, T003 and T004 together after T001.
- Phase 7: T033 to T041 together, each in its own file.

## Implementation strategy

- MVP: Phases 1 to 3 give a Feature that installs and verifies Orca on three bases. Phases 4 and 5 then deliver the working server and pairing. Stop and test after each STOP.
- Incremental: US1, then US2 and US3 (both P1), then US4, then tests, then publish.
- Tests come after code here because plan.md fixes the order. Each phase still ends with `bash scripts/verify.sh fast`.
