# Analysis: orca-server Feature research (2026-11-23)

Status: read-only investigation. Where a finding disagrees with the plan, the finding wins. Disagreements are listed in the section "Plan changes".

Method: Context7 (`/devcontainers/spec`, `/devcontainers/cli`, `/anthropics/claude-code`), the `gh` CLI against stablyai/orca release v1.4.271 and its source at `main`, and the downloaded `.deb` control file. Nothing here comes from memory.

## R1. containers.dev Feature reference

- `id`, `version` and `name` are required. `id` must match the directory name. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md
- `options` become upper-case environment variables for `install.sh`. Omitted options export their default. The name rule is replace non-word characters with `_`, then upper-case. So `pairingAddress` becomes `PAIRINGADDRESS`, `tailscaleWaitSeconds` becomes `TAILSCALEWAITSECONDS`. Same source.
- `installsAfter` is a soft dependency. It only orders Features already queued, and it ignores absent ones. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/feature-dependencies.md
- `entrypoint` is a single string. `containerEnv` and `mounts` are supported Feature properties. Same source as the first bullet.
- `_REMOTE_USER`, `_CONTAINER_USER`, `_REMOTE_USER_HOME` and `_CONTAINER_USER_HOME` are passed to `install.sh`, which runs as root. If no `remoteUser` is set, `_REMOTE_USER` equals `_CONTAINER_USER`. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md
- `${devcontainerId}` is allowed in Feature `entrypoint`, `mounts` and `customizations`. It must not be used where the image is built. The docker-in-docker Feature uses it in a volume `source`. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-id-variable.md
- Features may contribute lifecycle commands (`postStartCommand` and others). They run before the user's command and are blocking. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/features-contribute-lifecycle-scripts.md
- Feature metadata, including `entrypoint` and `mounts`, is stored in the image label `devcontainer.metadata`. Source: https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-reference.md

Not verified: how several Feature entrypoints chain. The spec text found gives only the single-string property. Plan action: the entrypoint script ends with `exec "$@"` (constitution principle 6), and a test scenario installs a second Feature that has its own entrypoint.

## R2. stablyai/orca releases

- Newest tag: `v1.4.271`, published 2026-11-22T20:13:44Z, marked Latest. Previous tags: v1.4.269, v1.4.268, v1.4.267, v1.4.266. Source: https://github.com/stablyai/orca/releases/tag/v1.4.271
- amd64 .deb asset name: `orca-ide_1.4.271_amd64.deb` (pattern `orca-ide_<version>_amd64.deb`, version without the `v`). Size 212,261,080 bytes. Same source.
- The tag has a `v` prefix. The asset name has no `v`.
- Checksum file: `orca-server-sha256sums.txt` exists, but it lists only `orca-server-linux-x64.tar.gz` and `orca-server-linux-arm64.tar.gz`. It does not list the .deb. No checksum is published for the .deb.
- The release also publishes `orca-server-linux-x64.tar.gz` (server only, about 60 MB, no GTK, X11 or Xvfb needed, glibc 2.28 or newer). Source: https://github.com/stablyai/orca/blob/main/docs/site/content/docs/remote-servers.mdx (section "Install only the server on Linux")

## R3. User-data directory

- The orcad runtime (the default for `serve`) resolves user data in this order: env `ORCA_USER_DATA`; else `$XDG_DATA_HOME/Orca`; else `~/.orca`. Logs go to `<userData>/logs`. Source: https://github.com/stablyai/orca/blob/main/src/main/orcad/host-runtime/orcad-app-paths.ts
- No `--user-data-dir` flag appears in the `serve` flag list. `--data-root` exists only with `--reclaim-stale-lock`. Source: https://github.com/stablyai/orca/blob/main/src/cli/specs/serve.ts
- `ORCA_SERVE_USER_DATA_PATH` is an internal fence between the CLI and the Electron child. Do not set it. Source: https://github.com/stablyai/orca/blob/main/src/shared/remote-runtime/serve-supervisor/serve-user-data-path.ts
- Not verified: whether the Electron fallback runtime also honours `ORCA_USER_DATA`. The docs say orcad falls back to Electron when it cannot serve, and `ORCA_SERVE_RUNTIME=orcad` forces orcad.
- Identity: copies of one image share the pairing key. `ORCA_INSTANCE_ID` rotates identity when its value changes. Source: remote-servers.mdx, section "Copies of a machine image". A fixed value would not rotate, but `${devcontainerId}` is stable across rebuilds, so it would be safe. It is not required here, because the identity lives in the volume.

## R4. `orca-ide serve` flags and output

- Usage: `orca serve [--port] [--bind <ip>] [--pairing-address <host>] [--allow-public | --refuse-public] [--mobile-pairing] [--no-pairing] [--grant-desktop-control] [--json] [--supervise]` and more. On Linux the command is `orca-ide`. Source: serve.ts (R3) and remote-servers.mdx.
- Default port is 6768. With `--port`, serve exits with an error when the port is taken. Same source.
- `--pairing-address` changes only the address in pairing links. `--bind` sets the listening interface. Without `--bind`, Orca listens as the default. `--mobile-pairing` needs all interfaces (no `--bind`, or `--bind 0.0.0.0`). Same source.
- `--mobile-pairing` prints a mobile-scoped QR and link "instead of the default runtime-environment pairing link". Same source. So one start prints one kind of link, not both.
- `orca-ide pair [--mobile] --address <addr>` asks the running Orca for a new pairing without a restart. Only the machine's own user can run it. Source: remote-servers.mdx, section "Pair without restarting the server".
- Each start prints a new link and retires the previous unused link. Source: serve.ts notes.
- Stdout line format: `Pairing URL: <url>`. A mobile run first prints `Mobile pairing QR:` lines. Source: https://github.com/stablyai/orca/blob/main/src/main/server/serve-readiness.ts and https://github.com/stablyai/orca/blob/main/src/cli/runtime/serve/startup/serve-pairing-redaction.ts
- URL scheme: `orca://pair?code=<base64url>`. Source: https://github.com/stablyai/orca/blob/main/src/shared/remote-runtime/pairing/pairing.ts
- Plain `serve` keeps pairing output on stdout. `--supervise` without a terminal replaces the line with a "hidden" message. Source: serve-pairing-redaction.ts. So the entrypoint must not use `--supervise`.
- `--json` prints an `orca_server_ready` JSON line that carries a `pairing` object. Exact field names for the URL are not verified.
- Public addresses: Orca accepts clients from localhost, LAN and Tailscale ranges (100.64/10, fd7a:115c:a1e0::/48). A hostname as `--pairing-address` also permits public addresses. A MagicDNS name is a hostname. Source: serve.ts notes. Impact: with the MagicDNS default, the server is not limited to tailnet clients by Orca itself. Add `--refuse-public` to keep it to private ranges.
- When Orca is PID 1 it warns that it cannot reap orphans. Source: https://github.com/stablyai/orca/blob/main/src/cli/runtime/serve/startup/serve-pid1-init-reaper.ts. Here Orca is not PID 1, because the entrypoint chains to `exec "$@"`.
- Account setup (`orca account add`) is out of scope for this Feature.

## R5. Runtime packages

- The .deb control file (v1.4.271, read from the downloaded package) declares: `libgtk-3-0, libnotify4, dbus-bin | dbus, libglib2.0-bin, libnss3, libxss1, libxtst6, xdg-utils, libatspi2.0-0, libuuid1, libsecret-1-0, libasound2t64 | libasound2, libgbm1, python3, python3-gi, gir1.2-atspi-2.0, at-spi2-core, xdotool, xclip, xvfb`. Recommends `libappindicator3-1`.
- So the .deb already declares libasound (as `libasound2t64 | libasound2`), xvfb, libgbm1 and libnss3. No extra packages are needed. Package names resolve per release: Debian 12 and Ubuntu 22.04 use `libasound2`, Ubuntu 24.04 uses `libasound2t64`.
- Orca's own headless Docker test installs the same set on ubuntu:24.04 with `LIBASOUND_PACKAGE=libasound2t64`. Source: https://github.com/stablyai/orca/blob/main/config/docker/headless-pairing/Dockerfile
- Orca's own test starts `serve` under `xvfb-run -a`, as an unprivileged user, via `runuser`. Source: https://github.com/stablyai/orca/blob/main/config/docker/headless-pairing/run-appimage-case.sh
- Not verified here: that the apt resolver finds every dependency on the three base images. Test scenarios cover this.

## R6. devcontainers/action and CLI tests

- Action inputs include `publish-features`, `base-path-to-features`, `generate-docs`, `oci-registry`, `features-namespace`, `validate-only`, `disable-schema-validation`, `disable-repo-tagging`, `devcontainer-cli-version`. Source: https://github.com/devcontainers/action/blob/main/action.yml
- Required workflow permissions: `packages: write`, `contents: write`, `pull-requests: write`. Docs are generated into a pull request, not pushed to main. The repo setting "Allow GitHub Actions to create and approve pull requests" must be on. Source: https://github.com/devcontainers/action/blob/main/README.md
- `devcontainer features test -f <feature> --base-image <image> .` runs `test/<feature>/test.sh`. `scenarios.json` maps a scenario name to a devcontainer.json snippet. The scenario passes when the container builds and `test/<feature>/<scenario>.sh` exits 0. Extra files in `test/<feature>/<scenario>/` are copied into the build folder. Source: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
- `test/_global/` is for scenarios that combine Features. It is needed here only for the Tailscale ordering and entrypoint chaining scenario.
- Verified 2026-11-23 with CLI 0.88.0 (T031). `test/_global/scenarios.json` holds the scenarios and `test/_global/<scenario>.sh` is the check script. Run it with `devcontainer features test -p . --global-scenarios-only`. A scenario can set `build.dockerfile`, and the Dockerfile and its files sit in `test/_global/<scenario>/`. Scenario containers run the Feature entrypoints. The scenario `image` is not set by `--base-image`, so `verify.sh` writes a copy of `scenarios.json` with `__BASE__` replaced. Scenarios use `containerUser` to run as a non-root user. The harness mounts the Feature files at `/workspaces/<id>/.devcontainer/orca-server/` inside the container, which `install_twice.sh` uses.

## R7. Claude Code attribution settings

- `attribution` in settings.json replaces the deprecated `includeCoAuthoredBy`. It customises commit and PR bylines. Source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
- `"attribution": false` hides all attribution, but older CLI versions skip a settings file that holds it. Keep the object form in shared files. Same source.
- `attribution.sessionUrl` omits the claude.ai session link. Same source.
- Verified 2026-11-23 against Claude Code 2.1.330 and https://code.claude.com/docs/en/settings-reference.md: the object keys are `commit` (string), `pr` (string) and `sessionUrl` (boolean, default `true`). An empty string hides that byline. `.claude/settings.json` sets `commit` and `pr` to `""` and `sessionUrl` to `false`.

## Plan changes

1. R5: the plan step "apt-get install of the .deb and the R5 packages" becomes "apt-get install of the .deb". The .deb declares libasound, xvfb, libgbm1 and libnss3 itself.
2. R3: the symlink fallback is dropped. Set `ORCA_USER_DATA=/var/lib/orca-server` in `options.env` and in the control script.
3. R4: one `serve` start prints one link kind. With `mobilePairing` true the printed link is the mobile link. `orca-server url` must therefore call `orca-ide pair` for the desktop link and `orca-ide pair --mobile` for the phone link, as the user running Orca.
4. R4: the entrypoint must not use `--supervise`. Otherwise the pairing line is redacted.
5. R6: `release.yaml` needs `contents: write` and `pull-requests: write` as well as `packages: write`. Generated docs arrive as a pull request.
6. R2: no checksum exists for the .deb. Principle 4 (pinned) is met by the tag. Integrity rests on HTTPS to github.com.

## Decisions needed

- Install format. The server-only tarball is 60 MB against 212 MB, needs no GTK, X11, Xvfb, python3 or xdotool, and has a published checksum. Decision 3 and acceptance criterion 2 fix the .deb and Xvfb. Recommendation: keep the .deb for 1.0.0, because criterion 2 requires `xvfb-run`. Consider the tarball for 2.0.0.
- Public-address policy. Recommendation: pass `--refuse-public` always. Cost: a client on a non-private path cannot connect. For a tailnet-only setup this is correct.

## Implementation results (2026-11-23)

- T047: `bash scripts/verify.sh ci` exits 0 on `mcr.microsoft.com/devcontainers/base:bookworm`, `:jammy` and `:noble`. It ran the default test, the six scenarios on each base, the `_global` scenario, `build-fails.sh` and `secrets_scan.sh`. CLI 0.88.0, Docker Desktop on Windows 11. Quickstart steps 1 to 3 also pass (`verify.sh fast`, `push`, `ci`).
- Entrypoint chaining (research D7, T038): passes. The Orca entrypoint and the `ghcr.io/devcontainers/features/sshd:1` entrypoint both ran in one container (`tailscale_stub` scenario). The stub reported Running 15 s after its first call, and the pairing link appeared after that.
- `attribution` keys (T003): verified, see R7.
- `pair` output token (T026): `orca-ide pair` prints a prose line, the `orca://pair` link and a browser URL. `--mobile` also prints a QR code. The first `orca://pair` token is the link for both forms.
- Restart link: `orca-ide serve` prints the same unused link again after a restart, so the test plants a stale line and expects it replaced.
- `runuser --preserve-environment` keeps `HOME=/root`, which Orca cannot read. `orca-server` sets the remote user's `HOME`.
- Not verified: `ORCA_USER_DATA` under the Electron fallback. All runs used the orcad runtime (`ORCA_SERVE_RUNTIME=orcad`). Grants across a rebuild with a real client are manual (T055).
- Not run: the GitHub workflows (`test.yaml`, `release.yaml`). `actionlint` 1.7.7 reports no findings.
