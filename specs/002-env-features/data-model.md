# Data Model: Environment Features

Each Feature is a directory under `src/` with a matching directory under `test/`. Nothing is stored apart from small files written at install time.

## Layout

```text
src/tailnet/      devcontainer-feature.json  install.sh  entrypoint.sh  NOTES.md
src/node-guard/   devcontainer-feature.json  install.sh  NOTES.md
src/ts7-cli/      devcontainer-feature.json  install.sh  NOTES.md
test/tailnet/     test.sh  scenarios.json  install_twice.sh  secrets_scan.sh  build-fails.sh
                  key_unset.sh  folder_name.sh  already_up.sh  daemon_down.sh  custom_key_var.sh
                  key_refused.sh  overlap.sh  non_root.sh
                  stub/{Dockerfile,tailscale}
test/node-guard/  test.sh  scenarios.json  install_twice.sh  build-fails.sh  remote_env_override.sh
test/ts7-cli/     test.sh  scenarios.json  install_twice.sh  build-fails.sh  other_version.sh
```

The input listed only `test.sh` and `scenarios.json`. The other scripts are the patterns the plan input told us to reuse, plus one script per scenario. `test/_global/` stays unchanged.

## tailnet

| Field | Value |
|---|---|
| `id`, `version` | `tailnet`, `1.0.0` |
| `dependsOn` | `ghcr.io/tailscale/codespace/tailscale:1` with option `version` `1.104.7` (spec FR-031) |
| `entrypoint` | `/usr/local/share/tailnet/entrypoint.sh` |
| `containerEnv` | none. A repo may set `TAILNET_WORKSPACE` itself (research R2). |
| `capAdd` | none (the dependency declares `NET_ADMIN`, `NET_RAW`, `MKNOD`) |

Options:

| Option | Type | Default | Meaning |
|---|---|---|---|
| `tailnet.hostnamePrefix` | string | empty | Prefix of the hostname. Empty means the container environment variable `HOSTNAME_PREFIX`. If that is also empty, the hostname is `<folder>-dev`. |
| `tailnet.tags` | string | `tag:devcontainer` | Comma-separated tags for `--advertise-tags`. |
| `tailnet.authKeyVar` | string | `TS_AUTH_KEY` | Name of the environment variable that holds the auth key at container start. |
| `tailnet.ssh` | boolean | `true` | Pass `--ssh`. |

Files written by `install.sh`:

| Path | Mode | Content |
|---|---|---|
| `tailnet.optionsFile` `/usr/local/share/tailnet/options.env` | 0644, root | `HOSTNAME_PREFIX_OPT`, `TAGS`, `AUTH_KEY_VAR`, `SSH`. Names and settings only. Never a key. |
| `tailnet.entrypointFile` `/usr/local/share/tailnet/entrypoint.sh` | 0755, root | The entrypoint. |

Runtime state:

| Field | Where | Rule |
|---|---|---|
| `tailnet.log` | `/var/log/tailnet.log` | Root owned, mode 0644. One line per step. One line that names the variable when the key is unset or empty. Never holds a key. |
| `tailnet.keyFile` | `/run/tailnet/authkey` | Root owned, mode 0600. Written only when a join needs the key. Removed on every exit path after `tailscale up`. |
| `tailnet.lock` | `/run/tailnet/lock` | Held for the whole join. A second run that cannot take it logs one line and stops (spec FR-036). |
| `tailnet.hostname` | computed | `<prefix>-<folder>-dev`. The prefix is the `hostnamePrefix` option, else `HOSTNAME_PREFIX`, else none, giving `<folder>-dev`. Lower case. Characters outside a-z, 0-9 and hyphen become a hyphen. At most 63 characters: the folder part is cut, `-dev` stays, no hyphen is left before it. |

Validation (install time, one error line each, before any write; spec FR-029): `tags` matches `^tag:[a-z0-9-]+(,tag:[a-z0-9-]+)*$`; `authKeyVar` matches `^[A-Za-z_][A-Za-z0-9_]*$`; `hostnamePrefix` matches `^[a-z0-9-]*$` after lower-casing; `ssh` is `true` or `false`. The values are sourced from `options.env`, so the character sets are the guard.

State flow of the entrypoint: `start` -> take `tailnet.lock` (busy: log one line, stop) -> not root: re-run under `sudo` (no `sudo`: log one line, stop) -> key variable unset or empty and node `NeedsLogin`: log one line, stop -> `tailscaled` unreachable: log, stop -> `up --reset ...` (failures are logged with the Tailscale error) -> done. Every path then returns to `exec "$@"`.

## node-guard

`containerEnv` only. No options.

| Field | Value |
|---|---|
| `node-guard.NODE_OPTIONS` | `--max-old-space-size=2048` |
| `node-guard.NX_PARALLEL` | `1` |
| `node-guard.NX_DAEMON` | `false` |
| `node-guard.VITEST_MAX_WORKERS` | `1` |

`install.sh` only checks the base, because the Feature layout requires the file (Constitution I) and AC7 covers every new `install.sh`.

## ts7-cli

| Field | Value |
|---|---|
| `id`, `version` | `ts7-cli`, `1.0.0` |
| `dependsOn` | `ghcr.io/devcontainers/features/node:1` with option `version` `26.13.1` (spec FR-031) |

Field `ts7-cli.version`: option, string, default `7.0.2`. It must match `^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$` or equal `latest`. `install.sh` has the constant `DEFAULT_VERSION=7.0.2`, and `verify.sh fast` checks it equals the JSON default.

Files: `ts7-cli.prefix` `/usr/local/share/ts7-cli/` (npm prefix, removed and rebuilt on each install) and `ts7-cli.link` `/usr/local/bin/tsc7`.

## orca-server (edit only)

`installsAfter` gains `ghcr.io/flumpiey/devcontainer-features/tailnet`. `version` goes from `1.0.1` to `1.0.2`. No other line changes.

## verify.sh (edit only)

Feature list: `src/*/devcontainer-feature.json`, id is the directory name. Per Feature: `default_test <id> <base>`, `scenarios <id> <base>` when `test/<id>/scenarios.json` exists, then once per Feature `test/<id>/build-fails.sh` and `test/<id>/secrets_scan.sh` where the file exists. Constant check: for each option with a default, constant `DEFAULT_<UPPER_SNAKE name>` in `install.sh`, checked only where the constant exists.
