# Tech stack

- Features: Bash, `devcontainer-feature.json`. Spec Kit scripts: PowerShell (plus one Python helper).
- Targets: Debian 12, Ubuntu 22.04, Ubuntu 24.04, x86_64 only.
- pnpm 12.3.4 (`pnpm-lock.yaml` is the only lockfile), for commit tooling only (commitlint, lefthook). `pnpm-workspace.yaml` allows the lefthook build.
- Node 22 in CI.
- Pins: devcontainer CLI 0.88.0 (`scripts/verify.sh` and both workflows), shellcheck 0.11.0 and shfmt 3.14.1 (`test.yaml`).
- CI: `pr-hygiene.yml` (commitlint, attribution), `test.yaml` (PRs and reusable), `release.yaml` (push to `main`: test, publish to GHCR, docs PR). Actions in test and release are pinned by SHA.
- Dev host: Windows 11, Git Bash, Docker Desktop. Orca project runtime is Windows, not WSL.
- Serena language servers: bash, json, powershell.
