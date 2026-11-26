# Conventions

- Commits: Conventional Commits. Header max 100, body lines max 150, lowercase subject, no trailing period. Spec-only changes use `docs(spec)`.
- No AI attribution anywhere. Enforced by `scripts/commit-msg.sh`, commitlint rule `no-ai-attribution`, CI `pr-hygiene`. The three regexes must stay in step.
- Never skip hooks (`--no-verify`, `LEFTHOOK=0`). Never edit hook or CI config to bypass a failure.
- Shell: `set -euo pipefail` within the first 5 lines, `shellcheck` clean, `shfmt -i 2`, LF endings. Line 2 area carries a `# path` comment.
- Option or requirement comments cite the spec id (`FR-015`, `Decision 18`).
- Tests: `dev-container-features-test-lib` with `check` + `reportResults`; host-side tests are plain bash run from `verify.sh ci`.
- `docs/`, `specs/`, `README.md`, `NOTES.md`: British spelling, no en or em dashes, no emojis (`verify.sh fast` scans).
- Smallest change that meets the spec; the spec wins over ponytail.
- Branches: Spec Kit `NNN-name`; others `<type>-<kebab-slug>`.
- Generated output: `DevcontainerFeatures-Output/YYMMDD-DevcontainerFeatures-description.ext`.
