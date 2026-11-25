# Feature Specification: Environment Features (tailnet, node-guard, ts7-cli)

**Feature Branch**: `002-env-features`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "Add three Dev Container Features to flumpiey/devcontainer-features: tailnet, node-guard and ts7-cli. Make scripts/verify.sh and .github/workflows/release.yaml cover every Feature under src/, not orca-server only."

## Context

The repo publishes Features to ghcr.io/flumpiey/devcontainer-features. orca-server (spec 001) is the only Feature so far. Dru runs one dev container per Nx monorepo (pnpm, Biome) on dru-main-pc under Docker Desktop with a 17 GB WSL2 limit.

Each dev container joins the tailnet boga-amberjack.ts.net through the ghcr.io/tailscale/codespace/tailscale Feature, with Tailscale SSH, tag `tag:devcontainer` and hostname `<prefix>-<folder>-dev`. Today every repo copies that block by hand. Agent-started test, type-check and build runs exhaust memory and make Docker Desktop unresponsive.

## Scope

In scope:

- Three new Features: `tailnet`, `node-guard`, `ts7-cli`.
- `scripts/verify.sh` and `.github/workflows/release.yaml` cover every Feature under `src/`.
- In `src/orca-server/devcontainer-feature.json`: `tailnet` added to `installsAfter`, and the Feature `version` raised from 1.0.1 to 1.0.2 so the release action publishes the change.

Out of scope:

- No change to orca-server behaviour. Its files change only as listed above.
- No MCP or agent tooling (spec 003).
- No arm64.
- Tailscale ACLs and tag owners.
- `/dev/net/tun` mapping. A Feature cannot add devices, so the tailnet `NOTES.md` documents the `runArgs` line.
- Windows or macOS container bases.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - tailnet joins the container to the tailnet (Priority: P1)

As Dru, I add `tailnet` to `devcontainer.json` and set `TS_AUTH_KEY` on the host. The container joins the tailnet as `<prefix>-<folder>-dev` with `tag:devcontainer` and Tailscale SSH.

**Why this priority**: Every repo copies this block by hand today. One Feature line removes the copy and the drift between repos.

**Independent Test**: Build a container from a `devcontainer.json` that lists only `tailnet`, with `TS_AUTH_KEY` set and `/dev/net/tun` mapped. Run `tailscale status --json` inside it.

**Acceptance Scenarios**:

1. **Given** `TS_AUTH_KEY` is set and `/dev/net/tun` is mapped, **When** the container starts, **Then** `tailscale status --json` reports `BackendState` `Running` within 120 seconds, with the expected hostname and tag.
2. **Given** the workspace folder is `My Project`, **When** the container joins, **Then** the hostname is `<prefix>-my-project-dev`.
3. **Given** the prefix option and `HOSTNAME_PREFIX` are both empty and the folder is `app`, **When** the container joins, **Then** the hostname is `app-dev`.
4. **Given** `authKeyVar` is set to `MY_KEY` and `MY_KEY` is set, **When** the container starts, **Then** the join uses the value of `MY_KEY`.
5. **Given** the container restarts and Tailscale is already up with another hostname, other tags or SSH off, **When** the entrypoint runs, **Then** hostname, tags and SSH match the computed values.

---

### User Story 2 - node-guard caps memory and parallelism (Priority: P1)

As Dru, I add `node-guard`. Every process in the container, including agent-spawned terminals, has the heap cap and the Nx limits.

**Why this priority**: Agent-started test, type-check and build runs exhaust the 17 GB WSL2 limit and make Docker Desktop unresponsive.

**Independent Test**: Build a container from a `devcontainer.json` that lists only `node-guard`. Open a non-login shell and print the variables.

**Acceptance Scenarios**:

1. **Given** a node-guard container, **When** a non-login shell prints `NODE_OPTIONS`, `NX_PARALLEL` and `NX_DAEMON`, **Then** the values are `--max-old-space-size=2048`, `1` and `false`.
2. **Given** a node-guard container, **When** a test runner starts, **Then** its worker limit is 1.
3. **Given** a repo sets `NX_PARALLEL=3` in `devcontainer.json` `remoteEnv`, **When** a shell opens, **Then** `NX_PARALLEL` is `3`.
4. **Given** a process that no shell started, such as the container's first process, **When** its environment is read, **Then** it holds the four values.

---

### User Story 3 - ts7-cli gives the TypeScript 7 CLI by name (Priority: P2)

As Dru, I add `ts7-cli` and run the TypeScript 7 CLI by name for type checks.

**Why this priority**: Type checks are one of the memory-heavy agent runs. The TypeScript 7 CLI is the faster path. It is secondary to joining the tailnet and capping memory.

**Independent Test**: Build a container from a `devcontainer.json` that lists `ts7-cli` and a repo with its own TypeScript 6. Print both versions.

**Acceptance Scenarios**:

1. **Given** a ts7-cli container, **When** Dru runs the TypeScript 7 CLI by name, **Then** it prints the pinned version.
2. **Given** a repo with its own TypeScript 6, **When** Dru runs the repo's `tsc`, **Then** it still prints its TypeScript 6 version.
3. **Given** the `version` option is set to another release, **When** the container builds, **Then** that release installs and no file of the previous release remains.

---

### User Story 4 - verify and release cover every Feature (Priority: P2)

As the maintainer, `bash scripts/verify.sh ci` tests every Feature on bookworm, jammy and noble, and `release.yaml` publishes every Feature.

**Why this priority**: Without it, new Features ship untested or unpublished.

**Independent Test**: Run `bash scripts/verify.sh ci`. Inspect the `release.yaml` trigger paths.

**Acceptance Scenarios**:

1. **Given** four Features under `src/`, **When** `bash scripts/verify.sh ci` runs, **Then** it tests all four on bookworm, jammy and noble and prints `verify: ci ok`.
2. **Given** a fifth directory with `devcontainer-feature.json` is added under `src/`, **When** `verify.sh` runs, **Then** it tests that Feature without any edit to `verify.sh`.
3. **Given** a change to any path under `src/`, **When** it reaches the default branch, **Then** `release.yaml` runs and publishes every Feature.
4. **Given** a Feature has no `test/<id>/test.sh` or no `test/<id>/scenarios.json`, **When** `verify.sh fast` runs, **Then** it fails and names the Feature.

---

### Edge Cases

- **Auth key variable unset or empty**: The container starts and a shell opens. The tailnet log has one line that names the missing variable. The join does not run.
- **Key expired, revoked or refused for the tag**: tailnet logs the Tailscale error and the container starts. Tag owner rights belong to the tailnet policy that Dru owns.
- **tailscaled not running**: The entrypoint logs the failure and still reaches `exec "$@"`. The container starts.
- **Tailscale already up with another hostname, other tags or SSH off after a restart**: The entrypoint applies the computed values again. It does not fail on the existing state.
- **Workspace folder name has spaces or capitals**: The hostname is lower case. Any character outside a-z, 0-9 and hyphen becomes a hyphen. Example: `My Project_v2` gives `<prefix>-my-project-v2-dev`.
- **Workspace folder name changes between runs**: The next start computes a new hostname and applies it.
- **Hostname longer than 63 characters**: The folder part is cut so the whole hostname is 63 characters, the `-dev` suffix stays, and no trailing hyphen is left before it.
- **Prefix option and `HOSTNAME_PREFIX` both empty**: The hostname is `<folder>-dev`.
- **Two entrypoint runs overlap, for example a fast restart**: The second run logs one line and does nothing.
- **Entrypoint user is not root**: The join still runs as root through `sudo`. When `sudo` is missing, tailnet logs one line and does not join.
- **install.sh runs twice**: The second run exits 0 and leaves the same result as the first (FR-030).
- **install.sh runs twice with different option values**: The result equals a fresh install with the second values (FR-030).
- **Base is not Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on amd64**: install.sh exits non-zero with one error line that names the supported bases. It writes nothing first (FR-020).
- **Repo wants different limits**: The repo overrides a node-guard value in `devcontainer.json` `remoteEnv`. node-guard has no options.

## Requirements *(mandatory)*

### Functional Requirements

**tailnet**

- **FR-001**: tailnet MUST NOT install Tailscale. It MUST depend on `ghcr.io/tailscale/codespace/tailscale` through `dependsOn`, with its `version` option set to the tested version (FR-031), and configure it.
- **FR-002**: tailnet MUST read the auth key at container start from the environment variable named by the `authKeyVar` option. The default is `TS_AUTH_KEY`.
- **FR-003**: The auth key MUST NOT enter an image layer, a build argument, a Feature option value, a file or label in the image, or the image environment. The `authKeyVar` option holds a variable name, never a key.
- **FR-004**: tailnet MUST bring Tailscale up with Tailscale SSH on (when the `ssh` option is true), the tags from the `tags` option (default `tag:devcontainer`) and the hostname `<prefix>-<folder>-dev`. The prefix is the `hostnamePrefix` option, else the container variable `HOSTNAME_PREFIX`, else none. With no prefix the hostname is `<folder>-dev`.
- **FR-005**: The hostname MUST be lower case. Any character outside a-z, 0-9 and hyphen MUST become a hyphen. The hostname MUST NOT exceed 63 characters. Where it would, the folder part is cut, the `-dev` suffix stays, and no hyphen is left before the suffix.
- **FR-006**: The tailnet entrypoint MUST start the join in the background, log every failure and end with `exec "$@"` (Constitution VI). tailnet MUST NOT block or fail container start. This includes an expired, revoked or tag-refused key and an unreachable control server.
- **FR-007**: When the auth key variable is unset or empty, tailnet MUST write one log line that names the variable and MUST NOT attempt the join.
- **FR-008**: On every start, tailnet MUST set hostname, tags and SSH to the computed values, including when Tailscale is already up with other values.
- **FR-009**: tailnet MUST document the `/dev/net/tun` `runArgs` line and the `containerEnv` lines for the key and `HOSTNAME_PREFIX` in its `NOTES.md`.
- **FR-010**: tailnet MUST list its options (`authKeyVar`, `tags`, `hostnamePrefix`, `ssh`), their defaults and the tested version in the option descriptions of `devcontainer-feature.json` (Platform and Distribution Constraints).
- **FR-026**: The auth key MAY exist only in the container process environment, as the host supplies it, and in one file readable only by root while one `tailscale up` runs. tailnet MUST remove that file on every exit path. The key MUST NOT appear on any command line or in any log that tailnet writes. tailnet passes the key to `tailscale` only through that file, so the `tailscaled` log, which the upstream Feature owns, receives no key from tailnet.
- **FR-027**: The secrets scan MUST build a tailnet test image with a canary key in the host environment. It MUST fail if the canary or the prefix `tskey-` appears in image history, in the Feature option files or in the image filesystem. It MUST also fail when a canary is planted on purpose, which proves the scan can detect one.
- **FR-028**: Files that tailnet installs MUST be owned by root. The options file MUST have mode 0644, the key file MUST have mode 0600, and the tailnet log file MUST have mode 0644 and hold no key (FR-026). The join MUST run as root. When the entrypoint user is not root, it MUST use `sudo` without a prompt, as the upstream Feature does.
- **FR-036**: Two tailnet entrypoint runs MUST NOT join at the same time. A run that finds another one active MUST log one line and stop.

**node-guard**

- **FR-011**: node-guard MUST set only `containerEnv`: `NODE_OPTIONS=--max-old-space-size=2048`, `NX_PARALLEL=1`, `NX_DAEMON=false` and a test-runner worker limit of 1.
- **FR-012**: node-guard MUST have no options and MUST NOT install any software.
- **FR-013**: The values MUST reach every process in the container, including non-login shells, agent-spawned terminals and processes that no shell started.
- **FR-014**: A repo MUST be able to override any value in `devcontainer.json` `remoteEnv`. node-guard MUST document this in its `NOTES.md`.

**ts7-cli**

- **FR-015**: ts7-cli MUST install the TypeScript 7 CLI as an npm package pinned by the `version` option. The default MUST be a tested version (Constitution IV). The value `latest` is allowed only as an explicit choice and its description MUST say it is not tested. A change of `version` MUST replace the previous install and leave no file of it.
- **FR-016**: ts7-cli MUST NOT replace or shadow the repo's own `tsc` or its TypeScript 6.
- **FR-017**: ts7-cli MUST depend on `ghcr.io/devcontainers/features/node` through `dependsOn`, with its `version` option set to the tested version (FR-031).
- **FR-018**: ts7-cli MUST expose the TypeScript 7 CLI under a name that does not clash with `tsc`.

**All new Features**

- **FR-019**: Each new Feature MUST have `src/<id>/devcontainer-feature.json`, `src/<id>/install.sh`, `test/<id>/test.sh` and `test/<id>/scenarios.json` (Constitution I).
- **FR-020**: Each new `install.sh` MUST be idempotent (FR-030). On an unsupported base it MUST fail with one error line that names the supported bases, and it MUST do so before it writes any file or installs any package (Constitution VII).
- **FR-021**: Each new `install.sh` MUST be Bash with `set -euo pipefail` and MUST pass `shellcheck` and `shfmt -d` (Constitution II).
- **FR-029**: Each `install.sh` MUST validate its option values and fail with one error line per bad value. Allowed values: `tags` is one or more of `tag:` plus lower-case letters, digits and hyphens, separated by commas; `authKeyVar` is a shell variable name; `hostnamePrefix` holds letters, digits and hyphens and is lower-cased; `ssh` is `true` or `false`; `version` is `latest` or a release number such as `7.0.2`.
- **FR-030**: "Same result" means: the same files with the same paths, owners, modes and content, the same links, and the same installed package versions. A second run with the same options MUST change none of them. A second run with other options MUST give the result of a fresh install with those options. The tailnet entrypoint MUST give the same node state when it runs again with the same inputs.
- **FR-031**: Every downloaded artefact MUST be pinned (Constitution IV). Each `dependsOn` entry MUST set a `version` option to an exact tested release that is not `latest` or `lts`, and the Feature reference MUST carry its major tag. The tested versions are Tailscale 1.104.7, Node 26.13.1 and TypeScript 7.0.2. Where `install.sh` has a default constant for an option, `verify.sh fast` MUST fail if it differs from the JSON default. npm and the Tailscale package host supply the integrity check; no extra checksum is required. Upstream drift is detected by `verify.sh ci` failing.
- **FR-032**: Each change to a Feature that must reach users MUST raise that Feature's `version`, because the release action skips a published version.
- **FR-034**: `README.md` MUST describe each Feature with a `devcontainer.json` example.

**verify and release**

- **FR-022**: `scripts/verify.sh` MUST find Features from `src/*/devcontainer-feature.json`. The `fast`, `push` and `ci` modes MUST run for every Feature found. `fast` MUST fail for a Feature that lacks `test/<id>/test.sh` or `test/<id>/scenarios.json`. Host-side scripts `build-fails.sh` and `secrets_scan.sh` run where the Feature has them.
- **FR-023**: `scripts/verify.sh ci` MUST test every Feature on Debian bookworm, Ubuntu jammy and Ubuntu noble, amd64 only. "Tested" means passing with the `@devcontainers/cli` version that `verify.sh` pins.
- **FR-024**: `.github/workflows/release.yaml` MUST trigger on a change to any path under `src/` and MUST publish every Feature. It triggers on every push to main, which includes such a change. A `paths` filter, if added, MUST list `src/**`, and `verify.sh fast` MUST fail when it does not.
- **FR-025**: `src/orca-server/devcontainer-feature.json` MUST list `tailnet` in `installsAfter` and MUST have `version` 1.0.2. No other orca-server file or behaviour changes.
- **FR-033**: AC1 MUST be proved at two levels. In CI, a stub proves the arguments of `tailscale up`: hostname, tags and SSH. The join itself is proved by one manual run from `quickstart.md`, recorded with its date.
- **FR-035**: `verify.sh ci` MUST finish inside the 120 minute job limit of `test.yaml`. If a run exceeds 90 minutes, the limit changes only with Dru's approval.

### Acceptance Criteria (verbatim)

- **AC1**: With TS_AUTH_KEY set and /dev/net/tun mapped, a tailnet container reports BackendState Running in tailscale status --json within 120 seconds of start, with hostname <prefix>-<folder>-dev and tag tag:devcontainer.
- **AC2**: With TS_AUTH_KEY unset, the container starts, a shell opens, and the tailnet log has one line that names the missing variable.
- **AC3**: docker history and the repo secrets scan of a tailnet test image show no auth key.
- **AC4**: In a node-guard container, a non-login shell prints --max-old-space-size=2048 for NODE_OPTIONS, 1 for NX_PARALLEL and false for NX_DAEMON.
- **AC5**: In a ts7-cli container, the TypeScript 7 CLI prints the pinned version, and the repo's own tsc still prints its TypeScript 6 version.
- **AC6**: Each new install.sh exits 0 when run twice and leaves the same result.
- **AC7**: On an unsupported base, each new install.sh exits non-zero with one error line that names the supported bases.
- **AC8**: bash scripts/verify.sh ci tests orca-server, tailnet, node-guard and ts7-cli on bookworm, jammy and noble, and prints "verify: ci ok".
- **AC9**: src/orca-server/devcontainer-feature.json lists tailnet in installsAfter.
- **AC10**: release.yaml triggers on a change to any path under src/.

### Key Entities

- **Feature**: A directory under `src/` with `devcontainer-feature.json` and `install.sh`, published as an OCI artefact.
- **Auth key**: A runtime secret in a host environment variable. It never persists in an image.
- **Hostname**: `<prefix>-<folder>-dev`, or `<folder>-dev` with no prefix, at most 63 characters. It is the tailnet identity of one dev container.
- **Resource limits**: Four environment values that cap Node heap, Nx parallelism, the Nx daemon and test-runner workers.
- **Pinned version**: An exact tested release set in a Feature option or a `dependsOn` option.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A container with `tailnet` and a host key reaches `Running` within 120 seconds of start (AC1).
- **SC-002**: A container with a missing key starts and opens a shell with zero blocked starts, and the log has exactly one line that names the missing variable (AC2).
- **SC-003**: Zero auth keys appear in image history or in the secrets scan, and the scan detects a planted canary (AC3, FR-027).
- **SC-004**: All three limit values show in a non-login shell in 100% of node-guard containers (AC4).
- **SC-005**: The TypeScript 7 CLI and the repo's TypeScript 6 `tsc` each print their own version in the same container (AC5).
- **SC-006**: One command, `bash scripts/verify.sh ci`, covers all four Features on three bases, prints `verify: ci ok` (AC8) and finishes inside 120 minutes (FR-035).
- **SC-007**: Dru replaces the hand-copied Tailscale block and memory env lines in tal, captive-coalition and smartbiii-platform with three Feature lines per repo.

## Assumptions

- The host sets `TS_AUTH_KEY` (or the variable named by `authKeyVar`) and passes it into the container with `containerEnv`. How the host sets it is outside this spec.
- The tailnet `boga-amberjack.ts.net` allows `tag:devcontainer` and its owners. Dru owns that policy. ACLs and tag owners are out of scope, and a refusal is logged (FR-006).
- Option names are `authKeyVar`, `tags`, `hostnamePrefix` and `ssh` (tailnet) and `version` (ts7-cli). The `hostnamePrefix` default is empty.
- The workspace folder name is the base name of the workspace folder path.
- The environment variable for the test-runner worker limit is `VITEST_MAX_WORKERS`. Jest has no such variable.
- ts7-cli's command is `tsc7`.
- When the auth key variable is `TS_AUTH_KEY`, the upstream Tailscale Feature also reads it and joins first with its own flags. tailnet then corrects hostname, tags and SSH. This exposure is accepted and tailnet does not change it.
- orca-server is the only existing Feature. Its tests must keep passing in `verify.sh ci`.
- The tailnet test scenarios use a stub where a real tailnet join is not possible in CI (FR-033).
