# Research: orca-server Feature

Full sourced findings: [docs/analysis/261123-orca-server-feature.md](../../docs/analysis/261123-orca-server-feature.md). This file records decisions only. No NEEDS CLARIFICATION remains.

## D1. Orca version default

- Decision: default `1.4.271`. Pass the version without the `v`. The tag is `v1.4.271`. The asset is `orca-ide_1.4.271_amd64.deb`.
- Rationale: it is the newest release at 2026-11-23.
- Alternatives: `latest` as default (rejected, principle IV).

## D2. Integrity of the download

- Decision: download over HTTPS with `curl --fail --location --retry 3`, then check SHA-256 against option `debSha256`, default `7fad3d721dc0b0920f248353f5391fe0138331791acb64c9677c7a91bf41e755`. If `version` is not the default and `debSha256` is unchanged, use the `digest` field of the asset in the GitHub release API (`gh api repos/stablyai/orca/releases/tags/v<version>`, field `assets[].digest`). A mismatch exits 3 with one line naming the expected and the actual hash.
- Rationale: the release publishes `orca-server-sha256sums.txt` only for the tarballs, but the API gives a digest for every asset. Verified 2026-11-23: the API digest for `orca-ide_1.4.271_amd64.deb` equals `sha256sum` of the downloaded file (212,261,080 bytes).
- Limit: for versions other than the default, hash and file come from the same release, so a replaced asset passes. Only the pinned default resists that.
- Alternatives: a table of pins per version (rejected: maintenance, and a wrong entry blocks installs).

## D3. Install format

- Decision: the .deb with `apt-get install ./file.deb`.
- Rationale: fixed by spec Decision 3 and criterion 2. The .deb pulls Xvfb and libasound itself.
- Alternatives: server-only tarball (smaller, has a checksum, no Xvfb). Decided: keep the .deb (plan.md, Decisions recorded, item 3).

## D4. Data directory

- Decision: `ORCA_USER_DATA=/var/lib/orca-server`, exported by the entrypoint and the control script.
- Rationale: orcad reads this variable first. No flag exists. Symlink is not needed.
- Risk: the Electron fallback may ignore it. Mitigation: set `ORCA_SERVE_RUNTIME=orcad` in the launch environment, and test that grants persist across a rebuild (criterion 9, manual).

## D5. Launch command

- Decision: `orca-ide serve --port <port> --pairing-address <addr> [--mobile-pairing] --refuse-public` (see D10), under `xvfb-run -a` only if no `DISPLAY` is set. Plain mode, not `--supervise`.
- Rationale: Orca starts its own Xvfb when no display exists (spec context), so `xvfb-run` may be unneeded. Orca's own Docker test wraps the call in `xvfb-run -a`. Decide by test in Slice 3.
- Alternatives: `--bind <tailscale ip>` (rejected: `--mobile-pairing` needs all interfaces).

## D6. Pairing URL extraction

- Decision: read stdout, take the first line that starts with `Pairing URL: `, strip the prefix, write it to `pairing-url.txt`.
- Rationale: the format comes from `serve-readiness.ts`. The link scheme is `orca://pair?code=`.
- Alternatives: `--json` readiness line (field names not verified).

## D7. Entrypoint structure

- Decision: the entrypoint truncates the log, writes its start line, runs `orca-server start` detached (`setsid`), which waits for Tailscale, resolves the address and starts Orca, then writes its exec line and runs `exec "$@"` at once. Every step before `exec` is guarded and an `ERR` trap runs `exec "$@"`.
- Rationale: meets the 2 s rule and principles II and VI.
- Risk: how several Feature entrypoints chain is not verified. A `_global` scenario tests it.

## D8. Release workflow

- Decision: `devcontainers/action@v1` with `publish-features`, `base-path-to-features: ./src`, `generate-docs`, and the three permissions.
- Rationale: documented in the action README. Docs arrive as a pull request. The repo setting "Allow GitHub Actions to create and approve pull requests" must be on.

## D10. `--refuse-public` and the Tailscale range

- Decision: always pass `--refuse-public`.
- Verified in source (v1.4.271 `main`): `network-source-class.ts` classifies 100.64.0.0/10 and fd7a:115c:a1e0::/48 as `tailnet`, checked before `private`. `ws-network-source-guard.ts` refuses only peers of class `public` (and not on-link global addresses). `serve-network-source-policy.ts` makes `--refuse-public` override grandfathering, remembered public sightings and the pairing-address rule.
- Why it is needed: a MagicDNS name such as `host.boga-amberjack.ts.net` classifies as `public` (it contains a dot and is not an IP), so without the flag `--pairing-address` opens Orca to public peers.
- Limits: the judgement uses the TCP peer address. A client behind a Docker port forward arrives as a private 172.x address and is accepted. A peer through Tailscale userspace networking arrives as loopback and is accepted. A client on a public path is refused.

## D11. Desktop and mobile links

- Decision: `url` runs `orca-ide pair --address <addr>`. `url --mobile` runs `orca-ide pair --mobile --address <addr>`. Extract the first token that starts with `orca://pair` from the output.
- Rationale: `serve --mobile-pairing` prints only the mobile link. `pair` asks the running server for the other kind without a restart. An unused offer is reused until `--rotate`, so repeated calls do not add grants. After a restart a new offer is made and the earlier link keeps working.
- Not verified: the exact text of `pair` output beyond `formatPairingOffer` in `src/cli/server/pair.ts`, which prints the link on its own line. The test checks the `orca://pair` token.

## D9. Tooling already present

- Decision: keep npm, `commitlint.config.mjs` and the existing `lefthook.yml` `commit-msg` hook. Add only `pre-commit`.
- Rationale: they already enforce principle IX, including the AI attribution check.
