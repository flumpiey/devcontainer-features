## What it does

tailnet joins the dev container to your tailnet at container start. It does not install Tailscale. It depends on `ghcr.io/tailscale/codespace/tailscale` (Feature 1.0.8, Tailscale 1.104.7) and configures it.

At every start the entrypoint runs `tailscale up --reset --accept-routes --ssh --hostname=<hostname> --advertise-tags=<tags>`. The hostname is `<prefix>-<folder>-dev`:

- The prefix is the `hostnamePrefix` option, else the container variable `HOSTNAME_PREFIX`, else none. With no prefix the hostname is `<folder>-dev`.
- The folder is the single directory under `/workspaces`. A repo with another workspace folder sets `TAILNET_WORKSPACE` in its own `containerEnv` to `${containerWorkspaceFolderBasename}`, and tailnet uses that value.
- The hostname is lower case. Any character outside a-z, 0-9 and hyphen becomes a hyphen. Example: prefix `dru` and folder `My Project_v2` give `dru-my-project-v2-dev`.
- The hostname has at most 63 characters. A longer name is cut in the folder part, and `-dev` stays.

The join runs in the background. It never blocks or fails container start. Read the result in `/var/log/tailnet.log`.

## Example devcontainer.json

A Feature cannot add a device or read a host variable, so the repo adds two lines of its own: `runArgs` for the tun device, and `containerEnv` for the key.

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:bookworm",
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

Set `TS_AUTH_KEY` on the host before you start the container. The key never enters an image layer.

## Options

| Option | Default | Meaning |
|---|---|---|
| `hostnamePrefix` | empty | Prefix of the hostname. Empty means `HOSTNAME_PREFIX`. |
| `tags` | `tag:devcontainer` | Comma-separated tags to advertise. |
| `authKeyVar` | `TS_AUTH_KEY` | Name of the variable that holds the key at container start. |
| `ssh` | `true` | Turn Tailscale SSH on. |

## Log and failures

`/var/log/tailnet.log` has one line per step. When the key variable is unset or empty and the node is not logged in, the log has one line that names the variable, and the join does not run. A key that is expired, revoked or refused for the tag gives a log line with the Tailscale error. The container starts in every case.

## Upstream Feature

The Tailscale Feature starts `tailscaled`. When `TS_AUTH_KEY` is set it also runs a blocking `tailscale up --accept-routes` with that key, with no hostname, tags or SSH. That can delay container start if the control server is slow. tailnet then corrects the hostname, tags and SSH on the same node. When `authKeyVar` names another variable, the upstream Feature does not see the key and tailnet does the whole join.

## Tailnet policy

Your tailnet policy must define the tags and let the key own them. That is outside this Feature. A refusal shows in the log.

## Non-root users

`tailscale up` needs root. When the container user is not root, the entrypoint runs the join through `sudo --non-interactive`, as the upstream Feature does. Without `sudo` the entrypoint prints one error line to the container output and does not join.

## Supported bases

Debian 12, Ubuntu 22.04 and Ubuntu 24.04 on amd64. On any other base the install stops with one error line.

## Tested

Tested with `@devcontainers/cli` 0.88.0 on Debian bookworm, Ubuntu jammy and Ubuntu noble, with the Tailscale Feature 1.0.8 and Tailscale 1.104.7. The join itself is proved by one manual run, recorded in `specs/002-env-features/quickstart.md`.
