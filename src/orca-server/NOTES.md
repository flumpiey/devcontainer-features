## Pair once

Orca starts at container start. At each attach, the terminal shows the desktop link, then the mobile QR code and link. Paste the desktop link in the Orca client under Settings, Remote Orca Servers, Add Server. Scan the QR code with Orca Mobile. The QR code needs a terminal at least 80 columns wide.

The image build cannot show a link, because Orca does not run then. A tool that ignores `postAttachCommand` shows nothing. Attach output can stay in Dev Containers, Codespaces or CI logs. Anyone who reads a link and can reach the server can pair. Set `showPairingOnAttach` to `false` to stop the attach output. In CI, `devcontainer up --skip-post-attach` also stops it.

```bash
orca-server show          # both links and the QR code
orca-server url           # desktop link
orca-server url --mobile  # mobile link
```

Each `url` command prints one `orca://pair` line. Treat the link like a password. The pairing grant lives in the volume `orca-server-data-${devcontainerId}`, so a rebuild keeps it and the client reconnects with no new link.

If a client does not reconnect after a rebuild, pair it again by hand:

1. Run `orca-server status`. It must print `running`. If it prints `stopped`, run `orca-server start` and read `/var/lib/orca-server/orca-server.log`.
2. Run `orca-server url`.
3. Remove the old server entry in the client, then add the new link.

## Revoke old links

An unused pairing link stays valid after a container restart. Its grant is in the volume, which a rebuild keeps. Revoke the unused links when a link can be in a log, a screenshot, a chat or a shared screen.

1. Set `showPairingOnAttach` to `false` and rebuild, when attach output is logged. Otherwise the next attach prints the new links in the same place.
2. Open a terminal in the container as the remote user.
3. Run `orca-server status`. It must print `running`. If it prints `stopped`, run `orca-server start`.
4. Run both commands. Each one revokes only its own kind of link, so one command alone leaves the other link valid.

```bash
orca-ide pair --rotate >/dev/null           # revokes unused desktop links
orca-ide pair --mobile --rotate >/dev/null  # revokes unused mobile links
```

Both commands must exit 0. Then `orca-server url` and `orca-server url --mobile` print new links. `pairing-url.txt` and the log keep the old link until the next start, but that link no longer pairs.

Rotate does not remove an already paired client, and neither removal method below is tested. This includes a stranger who used a leaked link before you revoked it. Remove that client in Orca under Shared Server Access. If you cannot, delete the volume `orca-server-data-<id>` and rebuild. Every client must then pair again.

## Example devcontainer.json

Put the Tailscale Feature in the same file. The Feature waits for Tailscale to report `Running`, then uses the Tailscale DNS name as the pairing address.

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:bookworm",
  "remoteUser": "vscode",
  "features": {
    "ghcr.io/tailscale/codespace/tailscale": {},
    "ghcr.io/flumpiey/devcontainer-features/orca-server:1": {}
  }
}
```

The remote user must not be root. Orca refuses public peers (`--refuse-public`). Set `pairingAddress` to skip the Tailscale wait.

## Run as a non-root container user

When you set `containerUser`, also set `"updateRemoteUserUID": false`. On a Linux host the dev container tool otherwise changes the user's UID and fixes only the home folder. The data folder `/var/lib/orca-server` keeps the old owner, and a non-root entrypoint cannot change it.

When the data folder is not writable, the entrypoint prints one `orca-server: error:` line to the container output, and also to `/var/lib/orca-server/orca-server.log` when that file is reachable. It does not start Orca and still runs the container command.

```json
{
  "containerUser": "vscode",
  "updateRemoteUserUID": false
}
```

## Commands

| Command | Result |
|---------|--------|
| `orca-server start` | Starts Orca in the background. Exit 0 also when it already runs. |
| `orca-server stop` | Stops Orca. Exit 0. |
| `orca-server status` | Prints `running` (exit 0) or `stopped` (exit 3). |
| `orca-server url [--mobile]` | Prints one pairing link. Exit 1 when Orca is not running. |
| `orca-server show [--attach]` | Waits for Orca, then prints both links and the QR code. Always exit 0. With `--attach`, prints nothing when `showPairingOnAttach` is `false`. |

Orca does not restart after a crash or a port conflict. Run `orca-server start` after you fix the cause.

## Files

All files are in `/var/lib/orca-server`, owned by the remote user. The directory has mode 0700.

| File | Mode | Content |
|------|------|---------|
| `orca-server.log` | 0600 | Orca output and `orca-server:` lines. Truncated at each start. |
| `pairing-url.txt` | 0600 | The link Orca printed at start. One line. |
| `orca-server.pid` | 0600 | PID of the running Orca. Removed on stop. |
| `orca-server.lock` | 0600 | Lock that prevents a second start. |

The install writes `/usr/local/share/orca-server/options.env` and `remote-user`. They hold no secret.

## Publish

The first publish creates the GHCR package as private. Set it to public once:

1. Open the package `orca-server` on GitHub.
2. Open Package settings, then Change visibility, then Public.
3. Run `DOCKER_CONFIG="$(mktemp -d)" devcontainer features info manifest ghcr.io/flumpiey/devcontainer-features/orca-server:1`. It must exit 0 with no credentials.

The release workflow needs the repository setting "Allow GitHub Actions to create and approve pull requests". The generated README arrives as a pull request. Run `bash scripts/verify.sh ci` on that branch before you merge it.

## Withdraw a bad version

Publish a fixed patch version. Change `version` in `devcontainer-feature.json`. When you change the Orca default, also change `DEFAULT_VERSION` and `DEFAULT_DEB_SHA256` in `install.sh` in the same commit. Take the digest from `gh api repos/stablyai/orca/releases/tags/v<version>`.

Users can pin an exact Feature version, for example `ghcr.io/flumpiey/devcontainer-features/orca-server:1.0.0`, so a later bad patch does not reach them.

To delete one published version, use the GitHub package page, or the API:

```bash
gh auth refresh -s delete:packages
gh api /user/packages/container/devcontainer-features%2Forca-server/versions --jq '.[] | [.id, (.metadata.container.tags | join(","))] | @tsv'
gh api -X DELETE /user/packages/container/devcontainer-features%2Forca-server/versions/<id>
```

A deleted version breaks every build that pins it. Prefer a patch release.
