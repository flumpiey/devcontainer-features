# Tasks: Environment Features (tailnet, node-guard, ts7-cli)

**Input**: `specs/002-env-features/` (plan.md, spec.md, research.md, data-model.md, contracts/feature-options.md, quickstart.md, checklists/)

**Tests**: Required. Constitution I and VIII need `test/<id>/` and `bash scripts/verify.sh ci` per Feature.

**Order**: The plan's slice order wins over spec priority order, because of its hard stops. Verify comes first (Phase 2, serves US4), then node-guard (US2, P1), ts7-cli (US3, P2), tailnet (US1, P1). tailnet is last because it edits orca-server and needs the generalised `verify.sh`.

**Format**: `- [ ] T### [P] [US#] Description with file path`. `[P]` means a different file and no open dependency. Every path is relative to the repo root. `data-model.md` is the canonical source for field rules. Tasks cite it as `data-model.md` plus `Entity.field`.

**Git**: No task commits. Stage the slice and give Dru the Conventional Commit message at each hard stop.

## Phase 1: Setup

- [X] T001 Confirm branch `002-env-features` and a clean `bash scripts/verify.sh fast` in `scripts/verify.sh` before any edit. (Constitution VIII)
- [X] T002 Time `bash scripts/verify.sh ci` with orca-server only. Write the minutes under Risks in `specs/002-env-features/plan.md` (FR-035).

## Phase 2: Foundational. Generalise verify.sh (plan slice 1, serves US4)

**Goal**: `verify.sh` finds Features from `src/*/devcontainer-feature.json` and enforces the pin and test-file rules. `release.yaml` stays unchanged (finding A2).

**Independent test**: `bash scripts/verify.sh ci` still prints `verify: ci ok` with orca-server only.

- [X] T003 Add `features()` to `scripts/verify.sh`. It prints the directory name of each `src/*/devcontainer-feature.json`, sorted. Print nothing when `src/` is absent (FR-022).
- [X] T004 In `fast()` of `scripts/verify.sh`, change the shell-file pattern to `\.sh$|^src/[^/]+/[^/.]+$|^test/.*/tailscale$`. This keeps `orca-server/orca-server` and admits `test/tailnet/stub/tailscale`. (FR-021)
- [X] T005 In `fast()` of `scripts/verify.sh`, replace the orca-server constant check with a loop over `features`. For each option with a `default` in the JSON, if `install.sh` has the line `DEFAULT_<UPPER_SNAKE option>=`, the value must equal the default. Check only where the constant exists. orca-server keeps `version` and `debSha256` (FR-031).
- [X] T006 In `fast()` of `scripts/verify.sh`, fail with one `problem` line if `.github/workflows/release.yaml` has a `paths:` key that does not list `src/**` (AC10, FR-024).
- [X] T007 In `fast()` of `scripts/verify.sh`, fail with one `problem` line per Feature that lacks `test/<id>/test.sh` or `test/<id>/scenarios.json` (FR-022).
- [X] T008 In `fast()` of `scripts/verify.sh`, fail with one `problem` line per `dependsOn` entry in any Feature JSON whose `version` option is missing, `latest` or `lts`, or whose reference has no `:<major>` tag (FR-031).
- [X] T009 In `scripts/verify.sh`, make `default_test` and `scenarios` take the Feature id as the first argument and the base as the second. `scenarios` copies `test/<id>` and returns 0 when `test/<id>/scenarios.json` is absent. (FR-022)
- [X] T010 In the `ci` branch of `scripts/verify.sh`, loop Features then bases for `default_test` and `scenarios`. Run `dc features test -p . --global-scenarios-only` once. Then run `test/<id>/build-fails.sh` and `test/<id>/secrets_scan.sh` for each Feature where the file exists. Update the `push` branch to test every Feature on bookworm (FR-022, FR-023).
- [X] T011 Extend `test/verify-fast-untracked.sh` with four cases in a temp repo: a `release.yaml` with `paths: ['src/orca-server/**']` fails `fast`; one with `paths: ['src/**']` passes; a Feature with no `test.sh` fails; a `dependsOn` entry with `"version": "latest"` fails. (FR-022, FR-024, FR-031)
- [X] T012 HARD STOP. Run `bash test/verify-fast-untracked.sh`, `bash scripts/verify.sh fast` and `bash scripts/verify.sh ci`. All pass with orca-server only. Stage the slice. Give Dru the commit message. Do not start Phase 3. (Constitution VIII)

## Phase 3: User Story 2, node-guard (Priority: P1)

**Goal**: Every process gets the heap cap and the Nx and Vitest limits.

**Independent test**: a container with only node-guard prints the four values in a non-login shell and from the first process (AC4, FR-013).

- [X] T013 [P] [US2] Create `src/node-guard/devcontainer-feature.json`: `id` `node-guard`, `version` `1.0.0`, no `options`, `containerEnv` with the four values from `data-model.md` `node-guard.NODE_OPTIONS`, `node-guard.NX_PARALLEL`, `node-guard.NX_DAEMON` and `node-guard.VITEST_MAX_WORKERS`. (FR-011, FR-012, FR-019)
- [X] T014 [P] [US2] Create `src/node-guard/install.sh`: Bash, `set -euo pipefail`, the orca-server `os_field` and base `case` copied, first action in the file. One error line `node-guard: error: unsupported base ...` that names Debian 12, Ubuntu 22.04 and Ubuntu 24.04 on x86_64. Nothing else (AC7, FR-020). (FR-012, FR-021)
- [X] T015 [P] [US2] Create `src/node-guard/NOTES.md`: the four values, the `remoteEnv` override, the rule that `NODE_OPTIONS` in `remoteEnv` replaces the whole value, and that Jest has no worker variable (research.md R6, FR-014).
- [X] T016 [P] [US2] Create `test/node-guard/test.sh` (AC4, FR-013): `source dev-container-features-test-lib`; `bash -c 'printenv ...'` and `sh -c 'printenv ...'` for the four variables; the same four values read from `/proc/1/environ`; `check` each; `reportResults`.
- [X] T017 [P] [US2] Create `test/node-guard/scenarios.json`: one scenario named `remote_env_override` on `__BASE__` with `remoteEnv` `NX_PARALLEL=3`.
- [X] T018 [P] [US2] Create `test/node-guard/remote_env_override.sh`: expects `NX_PARALLEL` 3 and `NODE_OPTIONS` unchanged (FR-014).
- [X] T019 [P] [US2] Create `test/node-guard/install_twice.sh` (AC6, FR-030): re-run the mounted `install.sh` as root; exit 0; `printenv` values unchanged. Pattern: `test/orca-server/install_twice.sh`.
- [X] T020 [P] [US2] Create `test/node-guard/build-fails.sh` (AC7): `expect_fail old_base debian:11 ...` with message `unsupported base debian 11`. Pattern: `test/orca-server/build-fails.sh`, copying `src/node-guard`.
- [X] T021 [US2] HARD STOP. `bash scripts/verify.sh ci` prints `verify: ci ok` with orca-server and node-guard on three bases. Stage. Give Dru the commit message. Do not start Phase 4.

## Phase 4: User Story 3, ts7-cli (Priority: P2)

**Goal**: `tsc7` prints the pinned TypeScript 7 version. The repo's `tsc` stays TypeScript 6.

**Independent test**: a container with ts7-cli and a temp project that has `typescript@6` prints both versions (AC5).

- [X] T022 [P] [US3] Create `src/ts7-cli/devcontainer-feature.json`: `id` `ts7-cli`, `version` `1.0.0`, `dependsOn` `ghcr.io/devcontainers/features/node:1` with `{"version": "26.13.1"}` (FR-017, FR-031), option `version` string default `7.0.2`. Field rules from `data-model.md` `ts7-cli.version`. The description names 7.0.2 as the tested version and says `latest` is not tested (FR-015).
- [X] T023 [P] [US3] Create `src/ts7-cli/install.sh`: base check first (FR-020); constant `DEFAULT_VERSION=7.0.2`; `VERSION` checked per `data-model.md` `ts7-cli.version`; source `/usr/local/share/nvm/nvm.sh` if present; remove `data-model.md` `ts7-cli.prefix`; `npm install --prefix` that path `--ignore-scripts typescript@$VERSION`; `ln -sf` `data-model.md` `ts7-cli.link` to the package `bin/tsc`. Error lines start `ts7-cli: error:`. (FR-016, FR-018, FR-021)
- [X] T024 [P] [US3] Create `src/ts7-cli/NOTES.md`: command `tsc7`, why not `tsc` (research.md R5), the `version` option, tested versions 7.0.2 and Node 26.13.1.
- [X] T025 [P] [US3] Create `test/ts7-cli/test.sh` (AC5): `tsc7 --version` equals the `version` default that `jq` reads from the mounted `devcontainer-feature.json`; a temp project with `typescript@6` gives `npx tsc --version` starting `Version 6.`; `command -v tsc` is empty or not under `/usr/local/share/ts7-cli`. (FR-016)
- [X] T026 [P] [US3] Create `test/ts7-cli/scenarios.json`: scenarios `other_version` on `__BASE__` with `"version": "7.0.1-rc"` (7.0.1 was never published) and `install_twice`.
- [X] T027 [P] [US3] Create `test/ts7-cli/other_version.sh`: `tsc7 --version` prints 7.0.1-rc; exactly one `typescript` package under `/usr/local/share/ts7-cli/node_modules` and its version is 7.0.1-rc (FR-015, US3 scenario 3).
- [X] T028 [P] [US3] Create `test/ts7-cli/install_twice.sh` (AC6, FR-030): second run exits 0; `readlink -f /usr/local/bin/tsc7` and `tsc7 --version` unchanged. A second run with `VERSION=7.0.1-rc` equals a fresh 7.0.1-rc install.
- [X] T029 [P] [US3] Create `test/ts7-cli/build-fails.sh` (AC7): `old_base` on `mcr.microsoft.com/devcontainers/base:bullseye` (the Node Feature fails first on a raw `debian:11`) and `bad_version` (`{"version": "7"}`, message `version must be`).
- [X] T030 [US3] HARD STOP. `bash scripts/verify.sh ci` prints `verify: ci ok` with three Features. The `fast` checks cover `DEFAULT_VERSION` and the `dependsOn` pin. Stage. Give Dru the commit message. Do not start Phase 5.

## Phase 5: User Story 1, tailnet (Priority: P1)

**Goal**: The container joins the tailnet with the computed hostname, the tags and SSH, and never blocks start.

**Independent test**: with the stub, `tailscale up` receives `--hostname`, `--advertise-tags` and `--ssh`. With the key unset or empty, the log has one line (AC1 arguments, AC2). The real join is the manual task T045.

- [X] T031 [P] [US1] Create `src/tailnet/devcontainer-feature.json`: `id` `tailnet`, `version` `1.0.0`, `dependsOn` `ghcr.io/tailscale/codespace/tailscale:1` with `{"version": "1.104.7"}` (FR-001, FR-031), `entrypoint` `/usr/local/share/tailnet/entrypoint.sh`, no `containerEnv` (a Feature `containerEnv` cannot hold `${containerWorkspaceFolderBasename}`, research.md R2), no `capAdd`. Options and defaults from `data-model.md` `tailnet.hostnamePrefix`, `tailnet.tags`, `tailnet.authKeyVar`, `tailnet.ssh`. Each description states its default and the tested Tailscale Feature version 1.0.8 (FR-010). (FR-019)
- [X] T032 [P] [US1] Create `src/tailnet/install.sh`: base check first (FR-020); validate `HOSTNAMEPREFIX`, `TAGS`, `AUTHKEYVAR`, `SSH` per `data-model.md` `tailnet.hostnamePrefix`, `tailnet.tags`, `tailnet.authKeyVar`, `tailnet.ssh` (FR-029); write `data-model.md` `tailnet.optionsFile` (names and settings only, never a key); `install -m 0755 -o root` the file `data-model.md` `tailnet.entrypointFile`. Constants `DEFAULT_TAGS=tag:devcontainer` and `DEFAULT_AUTH_KEY_VAR=TS_AUTH_KEY` equal the JSON defaults. (FR-021)
- [X] T033 [US1] Create `src/tailnet/entrypoint.sh` (after T032, for the options file shape): `set -euo pipefail`; source the options file; compute `data-model.md` `tailnet.hostname` (prefix order, sanitise, 63-character cut); take the folder from `TAILNET_WORKSPACE` when a repo sets it, else from the single `/workspaces/*` directory; start the join in `( ... ) &`; end with `exec "$@"`. The subshell takes `data-model.md` `tailnet.lock` with `flock -n` (busy: one log line, stop), re-runs under `sudo --non-interactive` when not root (no `sudo`: one log line, stop), waits up to 30 seconds for `tailscale status --json`, logs one line naming the variable when `${!AUTH_KEY_VAR}` is unset or empty and the state is `NeedsLogin`, writes the key to `data-model.md` `tailnet.keyFile` only when needed, runs `tailscale up --reset --accept-routes [--ssh] --hostname=... --advertise-tags=... [--auth-key=file:...]`, removes the key file on every path (trap), and appends each outcome and each Tailscale error to `data-model.md` `tailnet.log` with no key text (FR-026, FR-028, FR-036). Any failure still reaches `exec "$@"`. (FR-002 to FR-008)
- [X] T034 [P] [US1] Create `src/tailnet/NOTES.md`: the `runArgs` line `--device=/dev/net/tun`, the `containerEnv` lines for the key variable and `HOSTNAME_PREFIX`, options, hostname rule with one example and the 63-character cut, the log path, that the upstream Feature joins first and may block, tag owner note, tested versions Tailscale Feature 1.0.8 and Tailscale 1.104.7 (FR-009).
- [X] T035 [P] [US1] Create `test/tailnet/stub/tailscale` and `test/tailnet/lib.sh`. The stub appends its arguments to `/var/log/tailscale-stub.args`, reports `BackendState` from `/var/tmp/tailscale-stub-state` (default `NeedsLogin`), exits 1 on `status` in mode `down`, and exits 1 with a refusal message on `up` in mode `refuse`. It reads `TAILSCALE_STUB_MODE` (`down` or `refuse`) and `TAILSCALE_STUB_SLEEP` from the environment, so no state file is needed for those. No Dockerfile: `test/tailnet/lib.sh` installs the stub at `/usr/local/sbin/tailscale` inside the test container, which comes before the real `/usr/local/bin/tailscale` in `PATH` and in the `sudo` path. Leave `test/_global/` unchanged.
- [X] T036 [P] [US1] Create `test/tailnet/test.sh` (AC1 arguments): wait for `/var/log/tailscale-stub.args`; check `--hostname=<expected>`, `--advertise-tags=tag:devcontainer`, `--ssh`, `--auth-key=file:`; check the auto-run log at container start names the `/workspaces` folder (research.md R2); check no key text on the recorded command line. (FR-004, FR-005)
- [X] T037 [P] [US1] Create `test/tailnet/scenarios.json`: scenarios `key_unset`, `folder_name`, `already_up`, `daemon_down`, `custom_key_var`, `key_refused`, `overlap`, `non_root`, each on `__BASE__`. The scripts install the stub and run joins by hand with the key `test-auth-key`. Each scenario names its own script.
- [X] T038 [P] [US1] Create the scenario scripts `test/tailnet/key_unset.sh` (AC2: unset and empty value, shell opens, exactly one log line names `TS_AUTH_KEY`, no `up` call), `test/tailnet/folder_name.sh` (spaces, capitals, 70-character folder, empty prefix giving `<folder>-dev`), `test/tailnet/already_up.sh` (hostname, tags and SSH replaced), `test/tailnet/daemon_down.sh` (container up, log has the failure, entrypoint reached `exec`), `test/tailnet/custom_key_var.sh` (name taken from `authKeyVar`), `test/tailnet/key_refused.sh` (stub refuses `up`, log holds the error, container up), `test/tailnet/overlap.sh` (second run logs one line, one `up` call), `test/tailnet/non_root.sh` (non-root container user joins through `sudo`). (FR-006, FR-007, FR-008)
- [X] T039 [P] [US1] Create `test/tailnet/secrets_scan.sh` (AC3, FR-027): export a canary `tskey-auth-CANARY0000000000` on the host, build with the CLI, grep `docker history --no-trunc`, the option files and the image filesystem for the canary and for `tskey-`. Do not grep the bare name `TS_AUTH_KEY`. A second pass plants the canary in a scratch image and expects the scan to fail. Pattern: `test/orca-server/secrets_scan.sh`.
- [X] T040 [P] [US1] Create `test/tailnet/install_twice.sh` (AC6, FR-030): second run exits 0; options file and entrypoint unchanged by `stat` and `cat`. A third run with other options equals a fresh install with those options.
- [X] T041 [P] [US1] Create `test/tailnet/build-fails.sh` (AC7, FR-029): `old_base` (and the image has no `/usr/local/share/tailnet`), `bad_tags` (`{"tags": "devcontainer"}`), `bad_key_var` (`{"authKeyVar": "a b"}`), `bad_prefix` (`{"hostnamePrefix": "A_b"}`), `bad_ssh`.
- [ ] T042 [US1] BLOCKED until `tailnet` is published (the CLI resolves `installsAfter` from the registry; tried 2026-11-25). Apply `specs/002-env-features/orca-server-installsafter.patch` after the first release. Edit `src/orca-server/devcontainer-feature.json`: add `ghcr.io/flumpiey/devcontainer-features/tailnet` to `installsAfter` (AC9) and set `version` to `1.0.2` (FR-025, FR-032). Change nothing else.
- [X] T043 [US1] Edit `README.md`: add sections for tailnet, node-guard and ts7-cli with the JSON from `contracts/feature-options.md` and links to each `NOTES.md` (FR-034).
- [X] T044 [US1] HARD STOP. `bash scripts/verify.sh ci` prints `verify: ci ok` with four Features on three bases (AC8). Stage. Give Dru the commit message.
- [X] T045 [US1] Manual, needs Dru's key: run `quickstart.md` steps 4 to 7 on a scratch repo. Record the date, `BackendState`, hostname and tags in `specs/002-env-features/quickstart.md` under a "Result" heading (AC1, FR-033).

## Phase 6: Polish and cross-cutting (US4 close-out)

- [X] T046 Compare the T044 `ci` run time with the 120 minute limit in `.github/workflows/test.yaml`. If it exceeds 90 minutes, ask Dru before changing `timeout-minutes` (FR-035).
- [ ] T047 Review `specs/002-env-features/checklists/hardening.md` with Dru and tick items that the finished work proves. Do not edit the verbatim AC text. (checklists)
- [X] T048 Run `bash scripts/verify.sh fast` for the style scan (`specs`, `docs`, `README.md`, every `NOTES.md`). Fix any dash, emoji or US spelling. (Constitution X)
- [ ] T049 Confirm each of AC1 to AC10 has a named check: AC1 T036 and T045, AC2 T038, AC3 T039, AC4 T016, AC5 T025, AC6 T019 T028 T040, AC7 T020 T029 T041, AC8 T044, AC9 T042, AC10 T006. (spec acceptance criteria)

## Dependencies and order

- Phase 1 then Phase 2 then Phase 3 then Phase 4 then Phase 5 then Phase 6. Each hard stop (T012, T021, T030, T044) blocks the next phase.
- Phase 2 tasks edit one file, so they run in order.
- Inside Phases 3, 4 and 5, tasks marked `[P]` touch different files and run in parallel. T033 follows T032. T042 and T043 follow T031 to T041. T045 needs Dru.
- US2, US3 and US1 do not depend on each other. They run in plan order only because of the hard stops and the shared `verify.sh` change.

## Parallel example (Phase 3)

Run T013 to T020 together: eight files, no shared state. Then T021.

## Implementation strategy

- MVP is Phase 2 plus Phase 3: `verify.sh` covers every Feature and node-guard ships. It removes the memory exhaustion first.
- Ship in the plan's four slices. Each slice passes `bash scripts/verify.sh ci` before the next starts.
- The orca-server edit (T042) goes last so no earlier slice changes orca-server.

## Evidence (2026-11-25)

One line per ticked task. Gate runs: `bash scripts/verify.sh ci` printed `verify: ci ok` after 924 s (orca-server only, T012), 1301 s (three Features, T021 and T030) and 1822 s (four Features, T044). The log for each run is in the session scratch folder.

- T001: `verify.sh fast` printed `verify: fast ok` before any edit.
- T002, T046: 924 s with orca-server only; 1822 s (30.4 minutes) with four Features, inside the 90 minute rule of FR-035. Recorded in `plan.md` Risks.
- T003 to T011: `scripts/verify.sh` and `test/verify-fast-untracked.sh` changed; the untracked test printed 9 `ok` lines (7 new cases).
- T012: `verify-fast-untracked.sh`, `verify.sh fast` and `verify.sh ci` all passed with orca-server only.
- T013 to T020: `features test -f node-guard` on bookworm passed 12 default checks, `remote_env_override` and `install_twice`; `build-fails.sh` printed `ok old_base`.
- T021: `ci` passed with orca-server and node-guard on three bases (the 1301 s run). An earlier `ci` failed on orca-server `install_twice` while another Docker job ran; the rerun with no overlap passed.
- T022 to T029: `features test -f ts7-cli` passed `tsc7 prints the pinned version`, `the repo's own tsc still prints TypeScript 6` and `the Feature puts no tsc on PATH`; `other_version` and `install_twice` passed; `build-fails.sh` printed `ok old_base` and `ok bad_version`.
- T030: `ci` passed with three Features (1301 s).
- T031 to T041: `features test -f tailnet` passed 5 default checks and 9 scenarios on bookworm; `build-fails.sh` printed 5 `ok` lines; `secrets_scan.sh` printed `ok no auth key in the image` and `ok the scan detects a planted canary`.
- T043: `README.md` has the three sections.
- T044: `ci` passed with four Features on three bases (`Passed: 'tailnet'` three times), 1822 s.
- T045: manual run on a scratch repo; result recorded in `quickstart.md`.
- T048: `verify.sh fast` printed `verify: fast ok`, which includes the style scan.

Not ticked:

- T042: blocked. The CLI cannot resolve `installsAfter` to the unpublished `tailnet` (`Could not resolve Feature manifest`). The change is in `orca-server-installsafter.patch`.
- T047: the checklists are all ticked, but the review with Dru has not happened.
- T049: AC9 has no passing check until T042 lands.
