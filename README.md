# devcontainer-features

Dev Container Features, published to `ghcr.io/flumpiey/devcontainer-features`.

## orca-server

Installs Orca (`orca-ide`) in a dev container and serves it on your tailnet at container start.

```json
{
  "features": {
    "ghcr.io/tailscale/codespace/tailscale": {},
    "ghcr.io/flumpiey/devcontainer-features/orca-server:1": {}
  }
}
```

Each attach shows the desktop link and the mobile QR code in the terminal. Run `orca-server show` to print them again. See [src/orca-server/NOTES.md](src/orca-server/NOTES.md) for options, files and the release procedure.

## tailnet

Joins the dev container to your tailnet at container start, with Tailscale SSH, a tag and the hostname `<prefix>-<folder>-dev`. It configures the Tailscale Feature and does not install Tailscale. A Feature cannot add a device or read a host variable, so the repo adds `runArgs` and `containerEnv` lines.

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

See [src/tailnet/NOTES.md](src/tailnet/NOTES.md) for options, the hostname rule and failure handling.

## node-guard

Caps Node heap, Nx parallelism, the Nx daemon and Vitest workers for every process in the container. It has no options. Override a value in `remoteEnv`.

```json
{
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/node-guard:1": {}
  }
}
```

See [src/node-guard/NOTES.md](src/node-guard/NOTES.md) for the values.

## ts7-cli

Installs the TypeScript 7 CLI as `tsc7`. A repo's own `tsc` and TypeScript 6 stay untouched.

```json
{
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/ts7-cli:1": { "version": "7.0.2" }
  }
}
```

See [src/ts7-cli/NOTES.md](src/ts7-cli/NOTES.md) for options and the tested versions.

## Checks

```bash
bash scripts/verify.sh fast   # lint, JSON, pins, style
bash scripts/verify.sh ci     # every Feature on bookworm, jammy and noble
```
