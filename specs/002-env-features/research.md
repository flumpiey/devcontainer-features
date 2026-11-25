# Research: Environment Features (tailnet, node-guard, ts7-cli)

Date: 2026-11-25. Anchor findings are in `docs/analysis/261123-env-features.md`. Each item below gives a decision, the reason, the alternatives and sources. Where this file disagrees with the plan input, this file wins.

## R1. dependsOn, installsAfter and devices

- Decision: tailnet uses `dependsOn` for `ghcr.io/tailscale/codespace/tailscale:1` and `ghcr.io/devcontainers/features/node:1` for ts7-cli. orca-server gets `ghcr.io/flumpiey/devcontainer-features/tailnet` in `installsAfter`.
- `dependsOn` is a hard dependency. The tool installs the dependency first, with the given options. `installsAfter` is a soft dependency. The tool drops an edge when the named Feature is not in the install set. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/feature-dependencies.md
- A Feature can set `privileged`, `capAdd`, `securityOpt`, `init`, `mounts`, `containerEnv` and `entrypoint`. It has no property for devices. `capAdd` values are concatenated across Features. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md
- Result: the spec holds. tailnet cannot map `/dev/net/tun`. NOTES.md documents `"runArgs": ["--device=/dev/net/tun"]`. The upstream Feature adds `CAP_MKNOD` and creates the device node if the kernel has tun support.
- Alternatives: `installsAfter` for tailscale (rejected: soft, tailnet would break without it); `privileged` (rejected: far wider than needed).

## R2. Workspace folder name

- Decision (changed by the slice 4 test, 2026-11-25): the entrypoint takes the single directory under `/workspaces`. A repo with another workspace folder sets `TAILNET_WORKSPACE` in its own `devcontainer.json` `containerEnv`, with the value `${containerWorkspaceFolderBasename}`, and the entrypoint prefers it. If neither works, it logs one line and skips the join.
- `${containerWorkspaceFolderBasename}` is the base name of the workspace folder path in the container. The substitution code returns `path.posix.basename(containerWorkspaceFolder)`. Sources: https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainerjson-reference.md (variables table), `devcontainers/cli` v0.88.0 `src/spec-common/variableSubstitution.ts` lines 109 to 110.
- The CLI wraps image metadata in `addSubstitution` before the container is created (`src/spec-node/utils.ts` lines 163 to 170). That made substitution in a Feature `containerEnv` look likely. The slice 4 test showed it is not: a Feature `containerEnv` becomes a Dockerfile `ENV` line, Docker expands `${containerWorkspaceFolderBasename}` to nothing at build, and `TAILNET_WORKSPACE` was empty in the test container. The `/workspaces` fallback gave the right folder. The Feature therefore declares no `containerEnv`.
- Alternatives: read `$PWD` (rejected: the wrapper's working directory is the image `WORKDIR`, not the workspace); an option (rejected: the user must not repeat the folder name).

## R3. Upstream Tailscale Feature

- Decision: tailnet configures it and never installs it. tailnet pins `ghcr.io/tailscale/codespace/tailscale:1` (Feature 1.0.8) and sets its `version` option to `1.104.7`, the stable release on pkgs.tailscale.com on 2026-11-25 (`https://pkgs.tailscale.com/stable/?mode=json`). The Feature default is `latest`, which Constitution IV forbids as a default.
- Options: one, `version` (default `latest`). It installs `tailscale` to `/usr/local/bin` and `tailscaled` to `/usr/local/sbin` from `pkgs.tailscale.com/stable`. It declares `capAdd` `NET_ADMIN`, `NET_RAW`, `MKNOD`, a volume `tailscale-${devcontainerId}` at `/var/lib/tailscale`, and the entrypoint `/usr/local/sbin/tailscaled-entrypoint`. Source: https://github.com/tailscale/codespace/blob/main/src/tailscale/devcontainer-feature.json
- The entrypoint starts `tailscaled` in the background with a log at `/var/log/tailscaled.log`. If `TS_AUTH_KEY` is set it moves the key to a non-exported variable and runs `tailscale up --accept-routes --authkey=<key>` in the foreground. If the key equals `test-auth-key` it only touches `/tmp/test-auth-key-seen` and does not join. It adds `--hostname` only when `CODESPACE_NAME` is set. It then unsets `TS_AUTH_KEY` and runs `exec "$@"`. Sources: `tailscaled-entrypoint.sh` and `tailscaled-devcontainer-start.sh` in the same directory.
- No userspace fallback exists in the Feature. The script prints a message that points to Tailscale userspace networking when `/dev/net/tun` cannot be created. tailnet does not add a userspace mode (Constitution XI).
- Consequences for tailnet (decisions 3 and 4 hold, the shape changes):
  - A key in `TS_AUTH_KEY` already joins the node, blocking, as `--accept-routes` only. tailnet then corrects hostname, tags and SSH.
  - tailnet always runs `tailscale up --reset --accept-routes --ssh --hostname=<h> --advertise-tags=<t>`. `--reset` avoids the "requires mentioning all non-default flags" error on a node that is already up.
  - tailnet passes the key only when `BackendState` is `NeedsLogin` or when the node has no state. The key goes in a file, not on the command line. `tailscale up --auth-key` accepts a value that begins with `file:` as a path to a file that holds the key. Source: `tailscale/tailscale` `cmd/tailscale/cli/up.go` line 102 (`"node authorization key; if it begins with \"file:\", then it's a path to a file containing the authkey"`), verified 2026-11-25.
  - A custom `authKeyVar` is not seen by the upstream entrypoint. tailnet does the whole join in that case.
- Alternatives: set `--ssh` and `--hostname` with `tailscale set` (rejected: no tags flag, source `cmd/tailscale/cli/set.go`); a second Tailscale install (rejected by decision 1).

## R4. Entrypoint order and blocking

- Decision: tailnet's entrypoint returns at once. The join runs in a background subshell. The entrypoint ends with `exec "$@"`.
- The CLI joins every Feature entrypoint into one shell script, one per line, then runs `exec "$@"`. Each entrypoint is a blocking child of that wrapper. Order is the Feature install order. Source: `devcontainers/cli` v0.88.0 `src/spec-node/singleContainer.ts` lines 389 to 393 and `src/spec-node/imageMetadata.ts` line 177.
- Result: `dependsOn` puts tailscale first, then tailnet, then orca-server (through `installsAfter`). A slow tailnet entrypoint would delay orca-server, so Constitution VI applies. An entrypoint `exec "$@"` with no arguments is a no-op.
- Not proven: other tools (Codespaces, DevPod) may chain differently. Only the devcontainer CLI is tested here.

## R5. TypeScript 7 CLI

- Decision: package `typescript`, version `7.0.2` (npm `latest` on 2026-11-25), installed with `npm install --prefix /usr/local/share/ts7-cli --ignore-scripts typescript@<version>`. A shim `/usr/local/bin/tsc7` points at the package's `bin/tsc`. The `version` option default is `7.0.2`. The value `latest` is allowed only by explicit choice.
- `typescript@7.0.2` exposes the binary `tsc`, requires Node 16.20 or newer, and ships a native binary per platform as an optional dependency (`@typescript/typescript-linux-x64` for amd64). Source: `npm view typescript@7.0.2`.
- A global install would put a TypeScript 7 `tsc` on `PATH` and shadow the repo's TypeScript 6 outside `node_modules/.bin`. FR-016 and FR-018 forbid that. The private prefix and the `tsc7` name avoid it.
- Alternatives: `@typescript/native-preview` with `tsgo` (rejected: stale preview, last dev build 2026-07-07); `npm install -g` (rejected: shadows `tsc`).

## R5b. Node Feature pin

- Decision: ts7-cli sets the `ghcr.io/devcontainers/features/node:1` option `version` to `26.13.1`, the current Node LTS release on 2026-11-25 (`https://nodejs.org/dist/index.json`, codename Lithium, published 2026-11-10).
- The Node Feature (2.1.2) has option `version` with default `lts`. That floats, so Constitution IV forbids leaving it. Source: `devcontainers/features` `src/node/devcontainer-feature.json`, read 2026-11-25. `typescript@7.0.2` needs Node 16.20 or newer, which 26.13.1 meets.
- Alternative: leave `lts` (rejected: not a pinned version).

## R6. Test-runner worker caps

- Decision: node-guard sets `VITEST_MAX_WORKERS=1`. Jest has no environment variable for worker count, so node-guard sets nothing for Jest and NOTES.md says so.
- Vitest: `VITEST_MAX_WORKERS` overwrites the resolved `maxWorkers`, including project config. Source: https://github.com/vitest-dev/vitest/blob/main/packages/vitest/src/node/config/resolveConfig.ts (via `ctx7`, `/vitest-dev/vitest`).
- Jest: workers come from `--maxWorkers` or the `maxWorkers` config key. `JEST_WORKER_ID` is an output set by `jest-worker`, not an input. Source: `ctx7`, `/jestjs/jest`.
- Nx: `NX_PARALLEL` and `NX_DAEMON` are as decided.

## R7. Constitution link per decision

| Decision | Principle |
|---|---|
| Layout of three Features | I |
| Bash, strict mode, shellcheck, shfmt | II |
| `install.sh` twice, shim and files overwritten in place | III |
| `version` option default 7.0.2 | IV |
| Key read at start, canary scan | V |
| Background join, `exec "$@"` | VI |
| OS check copied from orca-server | VII |
| `verify.sh ci` is the gate | VIII |
| Smallest change: no userspace mode, no capAdd copy | XI |
