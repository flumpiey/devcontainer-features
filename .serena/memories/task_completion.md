# Task completion

- Feature, test or script change: `bash scripts/verify.sh ci` must pass before the commit (constitution VIII).
- Docs-only change: `bash scripts/verify.sh fast`.
- Feature change: update `test/<id>/` scenarios in the same commit.
- Shipped Feature behaviour change: bump `version` in `devcontainer-feature.json`, or the release publishes nothing.
- Commit through the normal hook path. Commit, push and PR only with explicit user permission.
- PR title must pass commitlint. The PR description records any constitution exception.
