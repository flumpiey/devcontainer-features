# Suggested commands

- Install tooling and hooks: `npm install` (the `prepare` script runs `lefthook install`). Required once per clone.
- Lint one message: `printf 'feat: x\n' | npx --no -- commitlint`
- Lint a range: `npx --no -- commitlint --from origin/main --to HEAD`
- Check line endings: `git ls-files --eol scripts/worktree-setup.sh` (expect `i/lf w/lf`).
- A Bash hook in Claude Code denies any command containing `core.hooksPath`. Ask the user to run it.
- Windows: run POSIX snippets in Git Bash, or translate to PowerShell.
