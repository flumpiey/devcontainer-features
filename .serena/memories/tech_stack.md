# Tech stack

- Runtime on this machine: Windows 11, PowerShell, Git Bash `sh` (bash 5.3). Orca project runtime is Windows, not WSL.
- Node v25.9.0, npm (lockfile `package-lock.json`). Node is used for commit tooling only.
- Dev dependencies: `@commitlint/cli` and `@commitlint/config-conventional` ^21.2.4, `lefthook` ^2.2.2.
- Feature scripts are bash. Spec Kit scripts are PowerShell.
- Forge and CI: GitHub, GitHub Actions (`pr-hygiene.yml`).
- Serena language servers: bash, json, powershell. Add yaml or markdown only if the repo needs symbol lookup in them.
