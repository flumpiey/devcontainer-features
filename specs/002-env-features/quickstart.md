# Quickstart: validate the environment Features

Prerequisites: Docker, Node 20 or newer, `shellcheck`, `shfmt`, `jq`, a tailnet auth key for tag `tag:devcontainer` (manual step 5 only).

## Automated

1. Fast gate (no Docker): `bash scripts/verify.sh fast`. Expect `verify: fast ok`.
2. One base: `bash scripts/verify.sh push`. Expect `verify: push ok`.
3. Full gate: `bash scripts/verify.sh ci`. Expect `verify: ci ok` after orca-server, tailnet, node-guard and ts7-cli pass on bookworm, jammy and noble. This run takes a long time.

## Manual (AC1 needs a real tailnet)

4. In a scratch repo `devcontainer.json`, add the tailnet block from `contracts/feature-options.md`, with `containerEnv` for `TS_AUTH_KEY`.
5. On the host: `export TS_AUTH_KEY=<key>`, then `devcontainer up --workspace-folder .`.
6. Within 120 seconds: `devcontainer exec --workspace-folder . tailscale status --json | jq '.BackendState, .Self.HostName, .Self.Tags'`. Expect `"Running"`, `<prefix>-<folder>-dev`, `["tag:devcontainer"]`.
7. Unset the key, rebuild, then `devcontainer exec --workspace-folder . cat /var/log/tailnet.log`. Expect one line that names `TS_AUTH_KEY`.
8. node-guard: `devcontainer exec --workspace-folder . sh -c 'echo $NODE_OPTIONS $NX_PARALLEL $NX_DAEMON'`. Expect `--max-old-space-size=2048 1 false`.
9. ts7-cli: `devcontainer exec --workspace-folder . sh -c 'tsc7 --version; npx tsc --version'`. Expect `Version 7.0.2` then a TypeScript 6 version in a repo that has its own `typescript` 6.

If step 6 shows `NeedsLogin`: the key is wrong, expired or lacks the tag owner rights. Read `/var/log/tailnet.log` and `/var/log/tailscaled.log`.
If step 6 shows the container hostname: `/dev/net/tun` is not mapped or the entrypoint did not run. Check `runArgs`.

## Result (2026-11-25)

Run on dru-main-pc, Docker Desktop, `@devcontainers/cli` 0.88.0, scratch repo with the three Features from local paths.

1. `bash scripts/verify.sh fast`: `verify: fast ok`.
2. `bash scripts/verify.sh push`: `verify: push ok`.
3. `bash scripts/verify.sh ci`: `verify: ci ok`, 1822 seconds, four Features on bookworm, jammy and noble.
4. Scratch `devcontainer.json` with `runArgs`, the `containerEnv` lines and the three Features: built and started.
5. `TS_AUTH_KEY` was already set in the host shell (value not read or shown). `devcontainer up --remove-existing-container` finished in 9 seconds.
6. `tailscale status --json`: `BackendState` `Running`, hostname `qs-repo-dev`, tag `tag:devcontainer`, DNS name `qs-repo-dev.boga-amberjack.ts.net.`, first seen 19 seconds after the start of `up` (limit 120). `tailscale debug prefs` showed `RunSSH` true. `/var/log/tailnet.log` read `joined as qs-repo-dev with tags tag:devcontainer`. No key file stayed in `/run/tailnet` and the log held no `tskey-` text. The hostname has no prefix because `HOSTNAME_PREFIX` was unset on the host. The node was logged out and the container and its Tailscale volume removed afterwards.
7. With the key empty: log lines `start`, `hostname qs-repo-dev`, `backend state NeedsLogin`, then one line `error: TS_AUTH_KEY is unset or empty; not joining the tailnet`. Real `tailscaled` answered with `/dev/net/tun` mapped.
8. `echo $NODE_OPTIONS $NX_PARALLEL $NX_DAEMON $VITEST_MAX_WORKERS`: `--max-old-space-size=2048 1 false 1`.
9. `tsc7 --version`: `Version 7.0.2`. `npx tsc --version` in a repo with `typescript` 6: `Version 6.0.3`. `command -v tsc` found none outside the repo.
