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
