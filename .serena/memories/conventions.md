# Conventions

- Commits: Conventional Commits. Header max 100, body lines max 150, lowercase subject, no trailing period. Spec-only changes use `docs(spec)`.
- No AI attribution anywhere: no `Co-Authored-By` for AI tools, no "Generated with" lines, no Claude-Session lines. Three layers enforce it: lefthook strip step, commitlint rule `no-ai-attribution`, CI `pr-hygiene`.
- Never use `--no-verify`, `LEFTHOOK=0` or other hook skips. Never edit hook or CI config to bypass a failure.
- All `*.sh` files use LF endings (`.gitattributes`). A CRLF script breaks `bash` in worktrees.
- Spec Kit branch names are `NNN-name`; other branches are `<type>-<kebab-slug>`.
- Generated output goes to `DevcontainerFeatures-Output/`, named `YYMMDD-DevcontainerFeatures-description.ext`.
- British/SA spelling, no em or en dashes, no emojis in code, comments and docs.
