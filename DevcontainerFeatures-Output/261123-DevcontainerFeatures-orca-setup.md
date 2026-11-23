# Orca setup: devcontainer-features

Detected: GitHub (flumpiey/devcontainer-features), no commits yet, local branch master (main expected), no package.json, no hooks, no commitlint, no CI, no MCP config, no CLAUDE.md or AGENTS.md, Spec Kit initialised (.specify/, .claude/skills/speckit-*), Serena (.serena/), Node v25.9.0 on Windows.
Assumptions: runtime WSL, solo repo, Claude Code only, orca.yaml committed, GitHub Actions for CI.

## 1. Identity
- Display Name: `devcontainer-features`
- Repo Icon / Color: Use GitHub Avatar

## 2. Hosts and runtime
- Available Hosts: Local Windows ready
- Project runtime: Windows (decided 2026-11-23; hooks run through Git Bash sh)
- Agents: Claude Code (permission preset Auto)
- Existing terminals keep their runtime; restart them after changing.

## 3. GitHub and worktrees
- GitHub Account: Default (ambient gh login)
- External worktrees: Use global
- Default Worktree Base: `main` (explicit; see Watch for)
- Worktree Location: Leave default
- CLI equivalent: `orca repo add --path "C:\Users\druco\orca\projects\Orca Server Feature\devcontainer-features" --json`, then `orca repo set-base-ref --repo id:<repoId> --ref origin/main --json`

## 4. Worktree hooks
### Setup script
```bash
# scripts/worktree-setup.sh
set -e
cd "$ORCA_WORKTREE_PATH"
if [ -f package-lock.json ]; then npm ci; fi
```
- Setup Script field (or orca.yaml scripts.setup): `bash scripts/worktree-setup.sh`
- When to run: Run by default
- Wait for setup to complete before starting agent: On (commitlint needs node_modules)
### Archive script
Leave empty
### Custom GitHub Issue Command
Leave empty

## 5. Action recipes
| Recipe | Setting | Agent | CLI args | Why |
|---|---|---|---|---|
| Commit message | Use global | Claude | `--model haiku` | No custom commitlint |
| Pull request details | Use global | Claude | `--model sonnet` | Same |
| Branch name | Use global | Claude | `--model haiku` | Spec Kit exception already in global |
| Commit failure fixes | Use global | Claude | `--model sonnet` | Same |
| Push failure fixes | Use global | Claude | `--model sonnet` | Same |
| Broken checks fixes | Use global | Claude | `--model sonnet` | GitHub, `gh` works |

## 6. Hosted-review creation defaults
| Setting | Value |
|---|---|
| Draft by default | Leave global (On) |
| Use review template when available | Leave default (On) |
| Generate details when opening Create PR | Leave default (On) |
| Open hosted review after creation | Leave default (Off) |

## 7. Worktree Shared Paths
None. Add nothing; node_modules must not be shared.

## 8. Sparse Checkout Presets
None.

## 9. MCP Configs
None found. Serena and fff are user-level; leave them out of the repo.

## 10. Repo files (commit these)
```yaml
# orca.yaml
scripts:
  setup: |
    bash scripts/worktree-setup.sh
```
- `scripts/worktree-setup.sh`: block in section 4.
- `.worktreeinclude`: not needed; the repo has no env files.
- Write none of these until you say go.

## 11. Commit guard (commitlint + attribution)
- Claude settings: missing. Merge into `%USERPROFILE%\.claude\settings.json`.
- commitlint: missing. See Bootstrap prompt.
- commit-msg hook: missing. See Bootstrap prompt (no hook manager, so lefthook).
- CI: missing. GitHub pr-hygiene is inside the Bootstrap prompt.
- Bootstrap prompt: below. Run it in PowerShell on Windows. Add `.gitattributes` with `*.sh text eol=lf` in the same commit.

Claude settings block (remove `includeCoAuthoredBy` if present):
```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

Bootstrap prompt:

````text
Set up commitlint and lefthook in this repo so every commit message is linted and AI attribution is stripped. Work in the repo root. Inspect first, change only what is listed below, and do not push.

1. Inspect, and stop on a blocker
- Run: git status, node --version, sh --version. Check the git hooks path setting with: git config --get core.hooksPath
- Stop and report if: the working tree is not clean; Node is missing or older than 18; sh is missing; .husky/ or .pre-commit-config.yaml exists; the hooks path is set to anything other than .git/hooks.
- The repo has no lockfile today, so the package manager is npm.
- Note whether package.json, a lefthook config, a commitlint config and .github/workflows/ exist.

2. Dependencies
- If package.json is missing, create it with only: {"name": "devcontainer-features", "private": true, "scripts": {"prepare": "lefthook install"}}
- If package.json exists, add "prepare": "lefthook install" to scripts.
- Install as dev dependencies with npm, latest stable: @commitlint/cli @commitlint/config-conventional lefthook
- Make sure node_modules/ is in .gitignore.

3. commitlint config
- If no commitlint config exists, create commitlint.config.mjs with exactly this content:
```js
const AI_ATTRIBUTION =
  /^\s*(co-authored-by:.*(claude|anthropic|cursor|openai|codex|copilot|gemini|opencode)|claude-session:)|generated with \[?(claude|cursor|codex|copilot|gemini|opencode)|(claude\.ai|claude\.com)\/code/im;

export default {
  extends: ['@commitlint/config-conventional'],
  plugins: [
    {
      rules: {
        'no-ai-attribution': ({ raw }) => [
          !AI_ATTRIBUTION.test(raw ?? ''),
          'remove AI attribution (Co-Authored-By AI trailers, "Generated with ..." lines, Claude-Session lines)',
        ],
      },
    },
  ],
  rules: {
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 150],
    'no-ai-attribution': [2, 'always'],
  },
};
```
- If one exists, keep its extends and rules. Add the AI_ATTRIBUTION constant, the plugins entry and the "no-ai-attribution" rule from the content above.

4. lefthook config
- If no lefthook config exists, create lefthook.yml with this commit-msg block:
```yaml
commit-msg:
  piped: true
  commands:
    strip-ai-attribution:
      priority: 1
      run: |
        f="{1}"
        grep -viE '^[[:space:]]*(co-authored-by:.*(claude|anthropic|cursor|openai|codex|copilot|gemini|opencode)|claude-session:)|generated with \[?(claude|cursor|codex|copilot|gemini|opencode)|(claude\.ai|claude\.com)/code' "$f" > "$f.tmp" || true
        mv "$f.tmp" "$f"
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$f"
    commitlint:
      priority: 2
      run: npx --no -- commitlint --edit {1}
```
- Add no other commands. The repo defines no lint or test scripts.
- If a lefthook config exists, merge the block: keep every existing command, set piped: true under commit-msg, give strip-ai-attribution priority 1 and commitlint the next priority. Keep exactly one commitlint command.

5. CI
- Create .github/workflows/pr-hygiene.yml with this content:
```yaml
name: pr-hygiene
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
permissions:
  contents: read
  pull-requests: read
jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci
      - name: Lint PR commits
        run: npx --no -- commitlint --from "${{ github.event.pull_request.base.sha }}" --to "${{ github.event.pull_request.head.sha }}" --verbose
      - name: Lint PR title
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: printf '%s\n' "$TITLE" | npx --no -- commitlint --verbose
  no-ai-attribution:
    runs-on: ubuntu-latest
    steps:
      - name: Reject AI attribution in title, body and commits
        env:
          TITLE: ${{ github.event.pull_request.title }}
          BODY: ${{ github.event.pull_request.body }}
          GH_TOKEN: ${{ github.token }}
          PR: ${{ github.event.pull_request.number }}
          REPO: ${{ github.repository }}
        run: |
          pattern='co-authored-by:.*(claude|anthropic|cursor|openai|codex|copilot|gemini|opencode)|generated with \[?(claude|cursor|codex|copilot|gemini|opencode)|claude-session:|(claude\.ai|claude\.com)/code'
          msgs=$(gh api "repos/$REPO/pulls/$PR/commits" --paginate --jq '.[].commit.message')
          all=$(printf '%s\n%s\n%s\n' "$TITLE" "$BODY" "$msgs")
          if printf '%s\n' "$all" | grep -qiE "$pattern"; then
            printf '%s\n' "$all" | grep -niE "$pattern"
            echo "::error::AI attribution found in PR title, body or commits."
            exit 1
          fi
```

6. Install and verify
- Run: npm install, then: npx lefthook install
- Create a temporary branch: git switch -c chore-commitlint-verify
- a. git commit --allow-empty -m "Added stuff" must be rejected by commitlint.
- b. git commit --allow-empty -m "chore: verify commit hook" -m "Co-Authored-By: Claude <noreply@anthropic.com>" must succeed, and git log -1 --format=%B must show no Co-Authored-By line.
- c. printf 'feat: x\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n' | npx --no -- commitlint must fail with no-ai-attribution.
- Switch back to the original branch and delete the temporary branch with git branch -D chore-commitlint-verify.
- If any check behaves differently, stop and report; do not loosen the config to make it pass.

7. Commit
- Stage only the files you created or changed. Commit with header: build: add commitlint and lefthook commit-msg hook
- Body: "- " bullets, each line max 150 characters, listing what was added and why.
- No Co-Authored-By trailers, no "Generated with" lines, no tool or model names, no emojis.
- Never use --no-verify or LEFTHOOK=0. Do not push.

8. Report
- Package manager, files created or changed, installed versions of @commitlint/cli and lefthook, and the result of each verification step.
````

## 12. Unattended readiness
| Item | Status |
|---|---|
| scripts/worktree-setup.sh | Missing (section 4) |
| scripts/verify.sh | Missing |
| scripts/sdd-run.sh | Missing |
| .sdd/config.env | Missing |
| .sdd/claude-unattended.json, .sdd/opencode-unattended.json | Missing |
| .unattended/ in .git/info/exclude | Not set |
| Branch protection on base branch | Unchecked; no commits, no main branch yet |
| Base-branch baseline (lint e/w, tests p/f) | Not measurable; no code |
| Deny-hook literals | One known: Bash hook denies any command containing `core.hooksPath`. The brief must avoid that text. |
| Run-scoped settings file | Not applicable until a coordinator driver exists |

Not ready. Next: run orca-unattended-speckit, after the first commit, the Bootstrap prompt and `scripts/verify.sh` exist.

## Verification
1. Run `orca status --json` and `orca repo list --json`. Confirm the repo is listed with base ref `origin/main`.
2. Create a throwaway worktree `orca-setup-test` from `main`. Confirm setup ends clean.
3. In its terminal run `ls node_modules/.bin | head`. Confirm `commitlint` and `lefthook` exist.
4. Windows runtime: add `echo "shell=$0 ps=$PSVersionTable"` as the first line of the setup script. Read the output. Remove the line.
5. Run `git commit --allow-empty -m "Added stuff"`. Confirm commitlint rejects it. Run `git commit --allow-empty -m "chore: test hook" -m "Co-Authored-By: Claude <noreply@anthropic.com>"`. Confirm `git log -1 --format=%B` shows no trailer. Run `git reset --hard HEAD~1` in the throwaway worktree only.
6. Stage a trivial change. Run Generate commit message. Confirm it passes commitlint.
7. Open a draft PR titled "Added stuff" from a test branch. Confirm pr-hygiene fails. Close the PR and delete the branch.
8. Skip (no OpenCode).
9. Delete the test worktree. Confirm the branch is gone.

## Watch for
- The repo has zero commits and the local branch is `master`. Orca finds no base ref. Fix: `git switch -c main`, make the first commit, `git push -u origin main`, then set the base ref.
- Setup fails with `npm ci` errors before the Bootstrap commit lands. Fix: the script skips `npm ci` while `package-lock.json` is absent.
- Hooks do nothing in a fresh clone. Cause: `prepare` runs only on `npm install`. Fix: run `npm install` once per clone.
- Spec Kit branches (`001-name`) pass the Branch name recipe. The commit header scope for spec files is `docs(spec)`.
