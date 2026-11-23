# devcontainer-features core

- Purpose: Dev Container Features repo (GitHub flumpiey/devcontainer-features, default branch `main`). As of 2026-11-23 it holds tooling only, no Feature code yet.
- Planned Feature layout (devcontainers spec): `src/<id>/devcontainer-feature.json` + `install.sh`; tests in `test/<id>/`.
- Tooling files at root: `package.json` (commit tooling only, private), `commitlint.config.mjs`, `lefthook.yml`, `orca.yaml`, `.gitattributes` (`*.sh` forced LF), `.github/workflows/pr-hygiene.yml`.
- `scripts/worktree-setup.sh`: Orca worktree setup, runs `npm ci` only if `package-lock.json` exists.
- `.specify/` and `.claude/skills/speckit-*`: Spec Kit scaffolding (PowerShell scripts, Windows). Constitution at `.specify/memory/constitution.md` is still the unfilled template.
- `DevcontainerFeatures-Output/`: generated docs, ignored by Serena. Holds the Orca setup sheet.
- Never commit AI attribution. See `mem:conventions`.
- Commands: `mem:suggested_commands`. Done-criteria: `mem:task_completion`. Stack: `mem:tech_stack`.
