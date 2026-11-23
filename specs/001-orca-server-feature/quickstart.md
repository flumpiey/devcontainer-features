# Quickstart: validate the orca-server Feature

Prerequisites: Docker, Node (npm), `@devcontainers/cli`, `shellcheck`, `shfmt`, `jq`.

## 1. Static checks

```bash
bash scripts/verify.sh fast
```

Expected: exit 0 (acceptance criterion 11).

## 2. One scenario

```bash
bash scripts/verify.sh push
```

Expected: exit 0.

## 3. Every scenario on every base

```bash
bash scripts/verify.sh ci
```

Expected: exit 0 on `base:bookworm`, `base:jammy` and `base:noble` (criteria 1 to 8, 10, 11, 13 to 16). Criterion 13 uses a stub `tailscale` command.

## 4. Manual check on the real tailnet (criteria 5 and 9)

1. Add the Tailscale Feature and `ghcr.io/flumpiey/devcontainer-features/orca-server:1` to a project `devcontainer.json`.
2. Rebuild the container.
3. Run `orca-server status`. Expect `running`.
4. Run `orca-server url`. Paste the line into Orca, Settings, Remote Orca Servers, Add Server. Run `orca-server url --mobile` and scan or paste it in Orca Mobile.
5. Rebuild the container. Expect the client to reconnect with no new URL.

## 5. Publish (criterion 12)

1. Bump `version` in `src/orca-server/devcontainer-feature.json`.
2. Push to `main`.
3. Check `ghcr.io/flumpiey/devcontainer-features/orca-server:1` exists.
4. Run `bash scripts/verify.sh ci` on the generated README pull request branch, then merge it.
5. First publish only: on GitHub, open the package `orca-server`, Package settings, Change visibility, Public.
6. Check criterion 17 with no credentials:

```bash
DOCKER_CONFIG="$(mktemp -d)" devcontainer features info manifest ghcr.io/flumpiey/devcontainer-features/orca-server:1
```

Expected: exit 0 and a manifest.
