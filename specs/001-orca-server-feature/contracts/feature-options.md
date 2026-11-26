# Contract: Feature options

Feature id `orca-server`, version `1.1.0`, `ghcr.io/flumpiey/devcontainer-features/orca-server`.

| Option | Type | Default | Environment variable in `install.sh` |
|--------|------|---------|--------------------------------------|
| `version` | string | `1.4.271` | `VERSION` |
| `pairingAddress` | string | `""` | `PAIRINGADDRESS` |
| `port` | string | `6768` | `PORT` |
| `mobilePairing` | boolean | `true` | `MOBILEPAIRING` |
| `autoStart` | boolean | `true` | `AUTOSTART` |
| `showPairingOnAttach` | boolean | `true` | `SHOWPAIRINGONATTACH` |
| `tailscaleWaitSeconds` | string | `120` | `TAILSCALEWAITSECONDS` |
| `debSha256` | string | `7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755` | `DEBSHA256` |

`pairingAddress` set: the entrypoint skips the Tailscale wait and does not call `tailscale`.

Feature metadata:

- `installsAfter`: `ghcr.io/tailscale/codespace/tailscale`, `ghcr.io/devcontainers-extra/features/tailscale`
- `entrypoint`: `/usr/local/share/orca-server/entrypoint.sh`
- `postAttachCommand`: `/usr/local/bin/orca-server show --attach`
- `mounts`: `{"source": "orca-server-data-${devcontainerId}", "target": "/var/lib/orca-server", "type": "volume"}`

Usage:

```json
{
  "features": {
    "ghcr.io/tailscale/codespace/tailscale": {},
    "ghcr.io/flumpiey/devcontainer-features/orca-server:1": {}
  }
}
```

Install-time exit codes: 0 success; 1 unsupported base or architecture, option out of range, or `_REMOTE_USER` empty or `root`; 2 no .deb asset for the tag, or the release lookup for `latest` failed; 3 SHA-256 mismatch, or the release API gave no usable digest.

Install-time checks:

- The default `version` in this file MUST equal the pinned version in `install.sh` (`1.4.271`). `verify.sh fast` checks this.
- `install.sh` holds the default version and the default `debSha256` as constants. The JSON defaults MUST equal them. `verify.sh fast` checks this.
- Expected hash: a `debSha256` that differs from the default is always used. If `version` is not the default and `debSha256` equals the default, the expected hash is the `digest` of the .deb asset in the GitHub release API. If the API is unreachable or gives no digest, exit 3 with one error line.
- Mismatch message, one line: `orca-server: error: sha256 mismatch for <file>: expected <hash>, actual <hash>`.

Publish: the GHCR package MUST be public. Check: `devcontainer features info manifest ghcr.io/flumpiey/devcontainer-features/orca-server:1` succeeds with no credentials.
