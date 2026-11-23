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

Pair a client once with `orca-server url` (desktop) or `orca-server url --mobile`. See [src/orca-server/NOTES.md](src/orca-server/NOTES.md) for options, files and the release procedure.

## Checks

```bash
bash scripts/verify.sh fast
```
