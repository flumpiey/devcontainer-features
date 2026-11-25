# Implementation Plan: Environment Features (tailnet, node-guard, ts7-cli)

**Branch**: `002-env-features` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-env-features/spec.md`

## Summary

Add three Features and make `verify.sh` cover every Feature under `src/`. tailnet configures the upstream Tailscale Feature at container start. node-guard sets four environment values. ts7-cli installs the TypeScript 7 CLI as `tsc7` in a private prefix.

Findings that override the plan input (details in `docs/analysis/261123-env-features.md` and `research.md`):

1. release.yaml has no `paths` filter. It already runs on every push to main and publishes every Feature. AC10 holds with no change. Slice 1 adds a `fast` check instead of a filter.
2. The upstream Tailscale Feature already runs a blocking `tailscale up --accept-routes` when `TS_AUTH_KEY` is set. tailnet must re-run `up --reset` with hostname, tags and SSH. It does not declare `capAdd` (the upstream Feature does).
3. `typescript@7.0.2` ships the binary `tsc`. A global install would shadow the repo's `tsc`. ts7-cli uses a private prefix and the command `tsc7`.
4. Jest has no worker-count variable. The worker limit is `VITEST_MAX_WORKERS=1`.
5. orca-server needs `version` 1.0.1 to 1.0.2 as well as the `installsAfter` line, or the change does not publish. The spec now says so (FR-025, Scope).
6. Both `dependsOn` entries float by default (Tailscale `latest`, Node `lts`). The plan pins `version` in each (Tailscale 1.104.7, Node 26.13.1) and `verify.sh fast` enforces it (FR-031).
7. `tailscale up --auth-key=file:<path>` is supported (`up.go` line 102), so the key stays off the command line (research R3).
8. The tailnet stub lives in `test/tailnet/stub/`. `test/_global/` stays unchanged.
9. The entrypoint runs as the container user, but `tailscale up` needs root. tailnet re-runs itself under `sudo`, as the upstream Feature does (FR-028).

## Technical Context

**Language/Version**: Bash 5 (Debian 12, Ubuntu 22.04, Ubuntu 24.04), `set -euo pipefail` in every script

**Primary Dependencies**: `@devcontainers/cli` 0.88.0 (pinned in `verify.sh`), `ghcr.io/tailscale/codespace/tailscale:1` (option `version` 1.104.7), `ghcr.io/devcontainers/features/node:1` (option `version` 26.13.1), npm package `typescript` 7.0.2, `jq`, `shellcheck` 0.11.0, `shfmt` 3.14.1

**Storage**: small files under `/usr/local/share/<id>/`, log `/var/log/tailnet.log`, key file `/run/tailnet/authkey` (0600, removed after use)

**Testing**: `dev-container-features-test-lib` (`test.sh`, `scenarios.json`), host-side scripts (`build-fails.sh`, `secrets_scan.sh`, `install_twice.sh`), Tailscale stub on `PATH`

**Target Platform**: linux/amd64 on bookworm, jammy, noble

**Project Type**: Dev Container Feature collection

**Performance Goals**: tailnet `Running` within 120 seconds of start (AC1). Entrypoint returns in under 1 second.

**Constraints**: no secret in an image layer; entrypoint never blocks start; no arm64; orca-server logic untouched

**Scale/Scope**: 4 Features x 3 bases in `ci`; 3 repos adopt the Features

## Constitution Check

| Principle | Result | How |
|---|---|---|
| I Spec-compliant Features | Pass | Each Feature has `devcontainer-feature.json`, `install.sh`, `test/<id>/test.sh`, `scenarios.json` |
| II Bash only | Pass | All new files Bash, strict mode, `shfmt -i 2`, covered by `fast` |
| III Idempotent installs | Pass | Files overwritten in place; `install_twice.sh` per Feature (AC6) |
| IV Pinned versions | Pass | `ts7-cli` `version` default 7.0.2 with the constant check. Each `dependsOn` sets an exact `version` option (Tailscale 1.104.7, Node 26.13.1) and the `:1` tag. `verify.sh fast` fails on a `dependsOn` entry with no exact `version` or with `latest` or `lts` (FR-031). node-guard downloads nothing |
| V No secrets in images | Pass | Key read from the environment at start, written to a 0600 file under `/run`, removed after use. Canary scan proves it (AC3) |
| VI Entrypoints never block | Pass | Join runs in a background subshell under a lock; entrypoint ends with `exec "$@"`. The upstream entrypoint can still block on its own `tailscale up`. That is outside this repo |
| VII Debian and Ubuntu first | Pass | OS check copied from orca-server; AC7 test per Feature |
| VIII Tests before done | Pass | Each slice ends with `bash scripts/verify.sh ci` (slice 1: orca-server only) |
| IX Conventional commits | Pass | One commit per slice, no AI attribution |
| X British spelling | Pass | `fast` style scan covers `specs`, `docs`, `README.md`, `NOTES.md` |
| XI Smallest change | Pass | No userspace mode, no capAdd copy, no paths filter, one shared `verify.sh` path |

Post-design re-check: pass. No violation, so Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/002-env-features/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── feature-options.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks, not created here
docs/analysis/261123-env-features.md
```

### Source Code (repository root)

```text
src/
├── orca-server/devcontainer-feature.json   # edit: installsAfter line, version 1.0.2
├── tailnet/        {devcontainer-feature.json, install.sh, entrypoint.sh, NOTES.md}
├── node-guard/     {devcontainer-feature.json, install.sh, NOTES.md}
└── ts7-cli/        {devcontainer-feature.json, install.sh, NOTES.md}
test/
├── _global/        # unchanged
├── tailnet/        {test.sh, scenarios.json, install_twice.sh, secrets_scan.sh, build-fails.sh,
│                    key_unset.sh, folder_name.sh, already_up.sh, daemon_down.sh, custom_key_var.sh,
│                    key_refused.sh, overlap.sh, non_root.sh,
│                    stub/{Dockerfile, tailscale}}
├── node-guard/     {test.sh, scenarios.json, install_twice.sh, build-fails.sh, remote_env_override.sh}
└── ts7-cli/        {test.sh, scenarios.json, install_twice.sh, build-fails.sh, other_version.sh}
scripts/verify.sh   # edit: Feature discovery
README.md           # edit: three new sections
```

**Structure Decision**: one directory per Feature under `src/` and `test/`, as the Constitution requires. Existing orca-server files under `test/orca-server/` stay where they are.

## Implementation slices

Each slice ends at a hard stop. Run `bash scripts/verify.sh ci` (or the narrower check named) and stop. No slice starts before the previous one passes.

### Slice 1. Generalise verify.sh

Files: `scripts/verify.sh`, `test/verify-fast-untracked.sh` (extend only if the new checks need a case).

1. Add `features()` that prints the ids from `src/*/devcontainer-feature.json`, sorted.
2. `fast()`: shell-file pattern becomes `\.sh$|^src/[^/]+/[^/.]+$|^test/_global/tailscale_stub/tailscale$`.
3. `fast()`: the constant check loops over every Feature. For each option with a default, constant `DEFAULT_<UPPER_SNAKE option>` in `install.sh` must equal the default, checked only where the constant exists. orca-server still checks `version` and `debSha256`.
4. `fast()`: fail if `release.yaml` has a `paths:` key that does not list `src/**`.
4a. `fast()`: fail for a Feature with no `test/<id>/test.sh` or no `test/<id>/scenarios.json` (FR-022).
4b. `fast()`: fail for a `dependsOn` entry whose `version` option is missing, `latest` or `lts` (FR-031).
5. `default_test` and `scenarios` take the id as the first argument. `scenarios` skips a Feature with no `test/<id>/scenarios.json`.
6. `ci`: loop Features x bases. Then `--global-scenarios-only` once. Then each Feature's `build-fails.sh` and `secrets_scan.sh` where present.
7. `release.yaml`: no change.

Hard stop: `bash scripts/verify.sh ci` passes with orca-server only, and `bash test/verify-fast-untracked.sh` passes. Covers AC10 and the verify half of AC8.

### Slice 2. node-guard

Files: `src/node-guard/*`, `test/node-guard/*`.

1. `devcontainer-feature.json` with `containerEnv` for the four variables. No options.
2. `install.sh`: OS check only, same text as orca-server with `node-guard:` as prefix.
3. `test.sh` (AC4, FR-013): `bash -c 'printenv NODE_OPTIONS NX_PARALLEL NX_DAEMON VITEST_MAX_WORKERS'` on a non-login shell, then the same values from `/proc/1/environ` (a process no shell started). `scenarios.json`: one scenario that sets `remoteEnv` `NX_PARALLEL=3` and expects 3.
4. `install_twice.sh` (AC6), `build-fails.sh` (AC7, base `debian:11`).
5. `NOTES.md`: values, override with `remoteEnv`, Jest note, `NODE_OPTIONS` replace rule.

Hard stop before ts7-cli: `bash scripts/verify.sh ci` passes with two Features.

### Slice 3. ts7-cli

Files: `src/ts7-cli/*`, `test/ts7-cli/*`.

1. `devcontainer-feature.json`: `dependsOn` node `:1`, option `version` default `7.0.2`.
2. `install.sh`: constant `DEFAULT_VERSION=7.0.2`, option check, OS check, load nvm if `/usr/local/share/nvm/nvm.sh` exists, remove `/usr/local/share/ts7-cli`, `npm install --prefix /usr/local/share/ts7-cli --ignore-scripts typescript@$VERSION`, `ln -sf` the shim `tsc7`. The base check runs before any write (FR-020).
3. `test.sh` (AC5): `tsc7 --version` equals the `version` default read from the mounted `devcontainer-feature.json`; in a temp project with `typescript@6`, `npx tsc --version` prints 6.x; `command -v tsc` is not under `/usr/local/share/ts7-cli`.
4. `install_twice.sh` (AC6), `build-fails.sh` (AC7, bad version string).
5. `NOTES.md`.

Hard stop before tailnet: `bash scripts/verify.sh ci` passes with three Features.

### Slice 4. tailnet and orca-server line

Files: `src/tailnet/*`, `test/tailnet/*`, `test/_global/tailscale_stub/*`, `src/orca-server/devcontainer-feature.json`, `README.md`.

1. `devcontainer-feature.json`, `install.sh` (OS check, option checks, write `options.env`, install `entrypoint.sh`), `NOTES.md` with the `runArgs` line, the `containerEnv` line and the upstream blocking note.
2. `entrypoint.sh`: compute hostname; start the join in `( ... ) &`; end with `exec "$@"`. The subshell waits up to 30 seconds for `tailscale status --json` to answer, reads the key from `${!AUTH_KEY_VAR}`, writes it to `/run/tailnet/authkey` only when state is `NeedsLogin` or empty, takes a lock, re-runs under `sudo` when not root, runs `tailscale up --reset --accept-routes --ssh --hostname=... --advertise-tags=... [--auth-key=file:...]`, removes the file, logs the outcome.
3. Stub: `test/tailnet/stub/tailscale` records its arguments to `/var/log/tailscale-stub.args` and reports state from a file. Its Dockerfile puts the stub in `/opt/tailscale-stub` and sets `ENV PATH=/opt/tailscale-stub:$PATH`. `test/_global/` stays unchanged. The upstream Feature keeps its real binary in `/usr/local/bin`. Upstream calls it by absolute path, tailnet by name. The scenarios use the key `test-auth-key`, which makes the upstream entrypoint skip its own join.
4. `test.sh` and `scenarios.json` cover: AC1 arguments (hostname, tags, `--ssh`) with the stub; AC2 (key unset, one log line, shell opens); spaces and capitals in the folder name; already up under another hostname; `tailscaled` down (stub exits 1) still reaches `exec`; custom `authKeyVar`.
5. `secrets_scan.sh` (AC3, FR-027): export a canary `tskey-auth-CANARY...` in the host environment, build, grep `docker history --no-trunc`, the options file and the image for the canary and for `tskey-`. A second pass plants the canary in a file in a scratch image and expects the scan to fail.
6. `install_twice.sh` (AC6), `build-fails.sh` (AC7 and option errors).
7. orca-server: add the `installsAfter` entry (AC9) and set `version` to 1.0.2. Nothing else.
8. README: add three sections.

Hard stop: `bash scripts/verify.sh ci` prints `verify: ci ok` with four Features on three bases (AC8). The manual steps in `quickstart.md` prove AC1 once.

## Risks

- AC1 as written needs a real tailnet. FR-033 defines two proof levels: CI proves the `tailscale up` arguments with a stub, and one manual run from `quickstart.md` proves the join. The manual run needs Dru's key and is task T045.
- Measured 2026-11-25: `bash scripts/verify.sh ci` with orca-server only took 924 seconds (15.4 minutes), run after the slice 1 edits; the work is the same as before them. Four Features give about 62 minutes if run time scales with Feature count, inside the 120 minute limit.
- `ci` run time grows about fourfold for the scenario part. The 120 minute job limit in `test.yaml` may not hold. Slice 4 measures it and FR-035 sets the rule: above 90 minutes, Dru approves any change to the limit.
- `${containerWorkspaceFolderBasename}` in a Feature `containerEnv` is likely, not proven. Slice 4 tests it and falls back to `/workspaces/*`.
- A tagged join needs `tag:devcontainer` in the tailnet policy with the right tag owners. Out of scope, and the log shows the refusal.

## Complexity Tracking

None. No principle is violated. One accepted duplication: the base check in `install.sh` is copied into four Features. Each Feature ships as its own package, so a shared file cannot be loaded at install time, and a build step to inline it would add more than it saves (Constitution XI).
