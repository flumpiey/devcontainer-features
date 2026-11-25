## What it installs

ts7-cli installs the TypeScript 7 CLI as the command `tsc7`. The package lives in its own prefix, `/usr/local/share/ts7-cli`, and `/usr/local/bin/tsc7` links to it. The Feature does not put a command named `tsc` on `PATH`, so a repo's own `tsc` and its TypeScript 6 stay as they are.

The package `typescript` 7.0.2 ships the binary `tsc`. A global install of it would shadow a repo's `tsc` outside `node_modules/.bin`. The private prefix and the name `tsc7` avoid that.

```bash
tsc7 --version   # Version 7.0.2
tsc7 --noEmit -p tsconfig.json
```

## Options

| Option | Default | Meaning |
|---|---|---|
| `version` | `7.0.2` | TypeScript package version behind `tsc7`. 7.0.2 is the tested version. `latest` is allowed and is not tested. |

A change of `version` replaces the install. No file of the old version stays.

## Node

The Feature depends on `ghcr.io/devcontainers/features/node:1` and sets its `version` to `26.13.1`, the tested Node release. The TypeScript 7 package needs Node 16.20 or newer.

## Example devcontainer.json

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:bookworm",
  "features": {
    "ghcr.io/flumpiey/devcontainer-features/ts7-cli:1": {}
  }
}
```

## Supported bases

Debian 12, Ubuntu 22.04 and Ubuntu 24.04 on amd64. On any other base the install stops with one error line.

## Tested

Tested with `@devcontainers/cli` 0.88.0 on Debian bookworm, Ubuntu jammy and Ubuntu noble, with TypeScript 7.0.2 and Node 26.13.1.
