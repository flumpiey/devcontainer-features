# 004 Guard features

- Project: DevcontainerFeatures (flumpiey/devcontainer-features)
- Mode: Existing project, attended, Claude Code (skills mode)
- Generated: 2026-11-23
- Supersedes: none
- Prefix: `/speckit-` (integration claude, invoke separator -, Spec Kit 1.4.4.dev0)
- Investigation source: none yet; the plan block writes docs/analysis/261123-guard-features.md
- Update check: not run (no network check from this session)
- ClickUp: skipped (Dru, 2026-11-23)
- Canvas: https://claude.ai/artifact/AWUeDwRM2Jt8mWkQWhxo1d
- Deck: https://claude.ai/artifact/H8V83FuCStUpBqePQWTHjs

Adds git-guard, which blocks AI attribution in commits, and agent-browser with Chromium.

## Resolved decisions (261123)

1. Spec split: Four grouped specs: 002 env features, 003 agent tools, 004 guard features, 005 containers.dev listing.
2. Numbering: Run specify from main with an explicit number (-Number N -ShortName slug -AllowExistingBranch). Do not wait for 001.
3. RTK: RTK hooks Claude Code only, through agent-stack's postCreateCommand. Cursor keeps context-mode.
4. git-guard: Claude Code attribution setting plus strip-ai-attribution on PATH. No core.hooksPath, no template dir.
5. Runtimes: uv and Node come from dependsOn on upstream Features.
6. Pinning: Every download is pinned by a Feature option with a tested default and a SHA-256 where a binary is fetched. No curl-to-shell installers.
7. MCP config: Features install binaries only. MCP config stays in each repo.
8. Delivery: After sign-off, dstack full-stop with Claude, merge policy human. ClickUp sync skipped.

Earlier: orca-server pins its Orca version; the orca-server run is an attended Claude Code Spec Kit run (2026-11-23).

## Notes for Dru

- Gate: implement slice 1 is blocked until spec 002 merges (verify.sh covers every Feature).
- git-guard never sets core.hooksPath. Repos keep their own lefthook commit-msg hooks, and can call strip-ai-attribution from them.
- Maintenance owed: the speckit-runbook reference files still need the corrections listed in the skill. Mentioned once here.

## Manual steps

### 1. Specify

Run from up-to-date main.

```text
/speckit-specify Use feature number 004 and short name guard-features: run create-new-feature.ps1 with -Number 4 -ShortName guard-features -AllowExistingBranch.

Goal: add two Dev Container Features to flumpiey/devcontainer-features: git-guard and agent-browser. NOT: git-guard does not install commitlint or lefthook and does not change any repo's hooks. NOT: agent-browser does not install Lightpanda. NOT: no change to other Features.

Context: Dru never allows AI attribution in commits or PRs. This repo strips it with scripts/commit-msg.sh in a lefthook commit-msg hook, and turns it off for Claude Code in .claude/settings.json with an attribution block. Dru uses agent-browser with its default Chromium engine in his dev containers.

Decided, do not re-ask in clarify:
1. Q: What does git-guard install? A: /usr/local/bin/strip-ai-attribution, a port of scripts/commit-msg.sh that takes the commit message file path as its first argument and uses the same pattern.
2. Q: What does git-guard change in Claude Code? A: it merges {"attribution":{"commit":"","pr":"","sessionUrl":false}} into ~/.claude/settings.json of $_REMOTE_USER with jq, and keeps every other key.
3. Q: Does git-guard touch git config? A: No. It never sets core.hooksPath or init.templateDir.
4. Q: How does agent-browser install? A: the agent-browser npm package, globally, at the version in the version option, then its own command to install Chromium and its system libraries.
5. Q: Where does Node come from? A: dependsOn ghcr.io/devcontainers/features/node.

User stories, in priority order:
P1 git-guard. As Dru, I add git-guard and Claude Code adds no attribution to commits or PRs, and repos can call strip-ai-attribution from their commit-msg hooks.
P2 agent-browser. As Dru, I add agent-browser and an agent can drive headless Chromium with no extra setup.

Out of scope: commitlint, lefthook, Lightpanda, other agents' attribution settings.

Edge cases to specify: no ~/.claude/settings.json yet; a settings.json that is not valid JSON; a message with only attribution lines; a message with no attribution; install.sh run twice; Chromium libraries missing on a minimal base.

Acceptance criteria (put these in spec.md verbatim):
AC1. strip-ai-attribution on a message that holds a Co-Authored-By line for Claude and a Generated with Claude Code line removes both lines and keeps every other line.
AC2. strip-ai-attribution leaves a message with no attribution unchanged, byte for byte.
AC3. After install, ~/.claude/settings.json of $_REMOTE_USER has attribution.commit "", attribution.pr "" and attribution.sessionUrl false, and keeps every key it had before.
AC4. If settings.json is not valid JSON, install exits non-zero with one error line and leaves the file unchanged.
AC5. git config --system --get core.hooksPath and git config --global --get core.hooksPath print nothing after install.
AC6. agent-browser --version prints the pinned version, and opening about:blank headless exits 0.
AC7. Each new install.sh exits 0 when run twice and leaves the same result.
AC8. bash scripts/verify.sh ci passes with both new Features included.

Success looks like: no dev container can produce an AI-attributed commit through Claude Code, and agents have a browser.

Open items to leave as clarifications: none.
```

### 2. Clarify

Runs bare.

```text
/speckit-clarify 004-guard-features
```

### 3. Plan

The first step writes the investigation document.

```text
/speckit-plan 004-guard-features

First, write docs/analysis/261123-guard-features.md as a read-only investigation of the anchors below. Where its findings disagree with this plan, the findings win; say so in plan.md.

Anchors:
- scripts/commit-msg.sh: the grep pattern and blank-line trim to port.
- .claude/settings.json: the attribution block to merge.
- src/orca-server/install.sh: OS check and idempotency guard.
- test/orca-server/install_twice.sh and non_root.sh: test patterns.

Data model: src/git-guard and src/agent-browser, each with devcontainer-feature.json, install.sh, NOTES.md, and test/<id>/ with test.sh and scenarios.json. git-guard ships strip-ai-attribution as a file under src/git-guard.

Research before writing code (Context7 and upstream; record in research.md with sources):
1. The agent-browser npm package version and its Chromium install command with system dependencies.
2. The agent-browser command that opens a page headless and exits.
3. The current Claude Code attribution settings keys.

Constitution principles to cite: I, II, III, IV, V, VII, VIII, IX, XI.

Implementation plan (numbered slices, in order):
1. git-guard: strip-ai-attribution, settings merge, tests for AC1 to AC5 and AC7. Hard stop before agent-browser.
2. agent-browser: install, Chromium, tests for AC6 and AC7, README entries.
```

### 4. Checklist

Writes the checklist implement gates on.

```text
/speckit-checklist 004-guard-features idempotency and settings safety
```

### 5. Tasks

Dependency-ordered tasks.

```text
/speckit-tasks 004-guard-features
```

### 6. Analyze

Cross-checks spec, plan and tasks.

```text
/speckit-analyze 004-guard-features
```

### 6b. Fix analyze findings

Closes findings and checklist items.

```text
Fix every finding in the latest /speckit-analyze report for 004-guard-features, CRITICAL first, by editing spec.md, plan.md and tasks.md so the finding no longer applies; never by deleting the requirement it points at. Then open every file under specs/004-guard-features/checklists/ and tick each item that is now true, with one line of evidence per item. Re-run /speckit-analyze 004-guard-features. Repeat until analyze reports zero findings and no checklist item is unticked. Report the before and after counts and list any item you could not tick with the reason. Do not start implementation.
```

### 7a. Implement slice 1 (mechanical)

Blocked until 002 merges.

```text
/speckit-implement Run slice 1 of the implementation plan in plan.md: the git-guard Feature and its tests. Stop before slice 2.
```

### 7b. Implement slice 2 (mechanical)

agent-browser, the last slice.

```text
/speckit-implement Run slice 2 of the implementation plan in plan.md: the agent-browser Feature, its tests and README entries. Then run every step in quickstart.md and tick each task in tasks.md that is done, with evidence.
```

### 8. Converge

Repeat until no gaps.

```text
/speckit-converge 004-guard-features
```

### 9. Sign-off

Last step.

```text
Run bash scripts/verify.sh ci from the repo root. Fix every failure and rerun until it prints "verify: ci ok". Then check every acceptance criterion in specs/004-guard-features/spec.md and report pass or fail for each, with the command and output that proves it. Do not mark the spec done while any criterion fails or tasks.md has an unticked task.
```
