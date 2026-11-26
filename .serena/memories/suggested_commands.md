# Suggested commands

Run POSIX commands in Git Bash on Windows.

- Install tooling and hooks, once per clone: `pnpm install` (`prepare` runs `lefthook install`).
- Static checks: `bash scripts/verify.sh fast` (needs shellcheck, shfmt, jq on PATH; checks tracked files only, so `git add` new files first).
- Fast plus default test on bookworm: `bash scripts/verify.sh push` (Docker).
- Full matrix: `bash scripts/verify.sh ci` (Docker, 3 bases; CI timeout is 120 minutes).
- Test of the verify script: `bash test/verify-fast-untracked.sh`.
- Lint commits: `npx --no -- commitlint --from origin/main --to HEAD`.
- Passing container paths to `docker` in Git Bash: set `MSYS_NO_PATHCONV=1`; pass host paths to the devcontainer CLI through `cygpath -m`.
- A Claude Code Bash hook denies any command containing `core.hooksPath`. Ask the user to run it.
