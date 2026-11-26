# devcontainer-features core

- Dev Container Features repo, published to `ghcr.io/flumpiey/devcontainer-features`. One Feature: `orca-server`.
- Binding rules: `.specify/memory/constitution.md` (v1.0.0). It wins over templates, scripts and habits.
- `src/<id>/` Feature; `test/<id>/` tests; `test/_global/` cross-Feature; `specs/NNN-name/` Spec Kit; `test/verify-fast-untracked.sh` tests `verify.sh` itself and is run by hand.
- `.specify/scripts/powershell/` and `.claude/skills/speckit-*`: Spec Kit scaffolding, not product code.
- `DevcontainerFeatures-Output/`: generated docs, ignored by Serena. Its SPECS-INDEX holds the spec roadmap and may lag git.
- Read `mem:orca-server/core` before any change to the orca-server Feature or its tests.
- Commands: `mem:suggested_commands`. Done criteria: `mem:task_completion`. Versions and CI: `mem:tech_stack`. Style and commits: `mem:conventions`.
