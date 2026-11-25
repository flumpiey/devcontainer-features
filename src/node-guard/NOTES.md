## What it sets

node-guard has no options. It sets four values in the image environment, so every process in the container has them: non-login shells, agent-spawned terminals and processes that no shell started.

| Variable | Value | Effect |
|---|---|---|
| `NODE_OPTIONS` | `--max-old-space-size=2048` | Caps the Node heap at 2048 MB per process. |
| `NX_PARALLEL` | `1` | Runs one Nx task at a time. |
| `NX_DAEMON` | `false` | Stops the Nx daemon. |
| `VITEST_MAX_WORKERS` | `1` | Runs Vitest with one worker. |

Jest has no environment variable for its worker count. Set `--maxWorkers=1` in the repo's Jest config or command line.

## Example devcontainer.json

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:bookworm",
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/node-guard:1": {}
  }
}
```

## Override a value

Set the variable in `remoteEnv`. The repo value wins for terminals and tasks that the editor starts.

```json
{
  "remoteEnv": {
    "NX_PARALLEL": "3"
  }
}
```

`NODE_OPTIONS` in `remoteEnv` replaces the whole value. A repo that sets it must repeat `--max-old-space-size=2048`, or set the heap size it wants.

## Supported bases

Debian 12, Ubuntu 22.04 and Ubuntu 24.04 on amd64. On any other base the install stops with one error line.

## Tested

Tested with `@devcontainers/cli` 0.88.0 on Debian bookworm, Ubuntu jammy and Ubuntu noble.
