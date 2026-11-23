# Task completion

- Commit through the normal hook path. The commit-msg hook must pass commitlint.
- If a Feature `install.sh` or `devcontainer-feature.json` changed: run the devcontainer CLI test for that Feature once a `test/` folder exists. No test runner is configured yet.
- If a shell script changed: run `git ls-files --eol <file>` and confirm `i/lf`.
- Do not push or open a PR without explicit user permission.
- A PR title must itself pass commitlint (it becomes the squash commit). CI job `pr-hygiene` checks it.
