# Contract: Feature options and user-facing surface

The public surface is the `devcontainer.json` that a repo writes, the container environment, and `bash scripts/verify.sh`.

## tailnet

```json
{
  "runArgs": ["--device=/dev/net/tun"],
  "containerEnv": {
    "TS_AUTH_KEY": "${localEnv:TS_AUTH_KEY}",
    "HOSTNAME_PREFIX": "${localEnv:HOSTNAME_PREFIX}"
  },
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/tailnet:1": {}
  }
}
```

- The host sets `TS_AUTH_KEY`. `devcontainer.json` passes it with `containerEnv`, because a Feature cannot read a host variable. NOTES.md documents this line.
- `runArgs` maps the tun device. A Feature cannot add a device.
- Options: `hostnamePrefix`, `tags`, `authKeyVar`, `ssh` (see data-model.md).
- Hostname rule: `<prefix>-<folder>-dev`, lower case, `[^a-z0-9-]` becomes `-`, at most 63 characters (the folder part is cut). With no prefix: `<folder>-dev`. Example: folder `My Project_v2`, prefix `dru` gives `dru-my-project-v2-dev`.
- Log: `/var/log/tailnet.log`. Missing key: one line, `tailnet: error: TS_AUTH_KEY is unset or empty; not joining the tailnet` (variable name from `authKeyVar`).
- Exit rule: the entrypoint never fails the container start.

## node-guard

```json
{
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/node-guard:1": {}
  }
}
```

Sets `NODE_OPTIONS=--max-old-space-size=2048`, `NX_PARALLEL=1`, `NX_DAEMON=false`, `VITEST_MAX_WORKERS=1` in the image environment. A repo overrides one value with `remoteEnv`. Overriding `NODE_OPTIONS` replaces the whole value, so a repo that sets it must repeat `--max-old-space-size`.

## ts7-cli

```json
{
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/ts7-cli:1": { "version": "7.0.2" }
  }
}
```

Command: `tsc7`. It prints `Version 7.0.2`. The repo's `tsc` (TypeScript 6) is untouched.

## Install failure messages

One line on stderr, exit non-zero:

| Case | Line starts with |
|---|---|
| Unsupported base | `<id>: error: unsupported base <os> <version> on <arch>; need Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on x86_64` |
| Bad option | `<id>: error: <option> must ...` |

## verify.sh

`bash scripts/verify.sh {fast|push|ci}`. Exit 0 and the last line `verify: <mode> ok` on success. It finds Features from `src/*/devcontainer-feature.json`. `fast` also fails when `release.yaml` has a `paths:` filter that does not include `src/**`.
