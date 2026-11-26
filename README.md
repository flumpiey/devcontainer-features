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

## Checks

```bash
bash scripts/verify.sh fast
```
