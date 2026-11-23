# 003 Agent tools

- Project: DevcontainerFeatures (flumpiey/devcontainer-features)
- Mode: Existing project, attended, Claude Code (skills mode)
- Generated: 2026-11-23
- Supersedes: none
- Prefix: `/speckit-` (integration claude, invoke separator -, Spec Kit 1.4.4.dev0)
- Investigation source: none yet; the plan block writes docs/analysis/261123-agent-tools.md
- Update check: not run (no network check from this session)
- ClickUp: skipped (Dru, 2026-11-23)
- Canvas: https://claude.ai/artifact/AWUeDwRM2Jt8mWkQWhxo1d
- Deck: https://claude.ai/artifact/H8V83FuCStUpBqePQWTHjs

Adds the spec-kit, serena, context-mode and agent-stack Features. agent-stack carries dstack, ponytail, fff and RTK.

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

- Gate: implement slice 1 is blocked until spec 002 merges, because 002 makes verify.sh test every Feature. Specify to analyze can run earlier.
- The ponytail skill has no public source I can confirm. The ponytail option defaults to false unless research finds one.
- RTK and context-mode both compress output. RTK hooks Claude Code only; do not let the agent add .cursorrules.
- dstack installs from GitHub at build time, so a build needs network to github.com and registry.npmjs.org.
- Maintenance owed: the speckit-runbook reference files still need the corrections listed in the skill. Mentioned once here.

## Manual steps

### 1. Specify

Run from up-to-date main with 002 merged, or with the explicit number if not.

```text
/speckit-specify Use feature number 003 and short name agent-tools: run create-new-feature.ps1 with -Number 3 -ShortName agent-tools -AllowExistingBranch.

Goal: add four Dev Container Features to flumpiey/devcontainer-features: spec-kit, serena, context-mode and agent-stack. agent-stack installs dstack, the ponytail skill, fff and RTK. NOT: no MCP server config in any repo. NOT: no Cursor rules files. NOT: no change to tailnet, node-guard, ts7-cli or orca-server.

Context: every Dru repo uses Spec Kit, Serena, context-mode, graphify, Honcho and fff for agents, plus his dstack PR skills (flumpiey/dstack), which must install inside his dev containers. Today each repo installs these by hand. RTK (rtk-ai/rtk) is a Rust CLI that compresses shell output for agents; rtk init --global adds a PreToolUse hook to Claude Code settings. fff (dmtrKovalenko/fff) is a Rust file-search MCP server.

Decided, do not re-ask in clarify:
1. Q: How does spec-kit install? A: uv tool install of specify-cli from github/spec-kit at the tag in the version option.
2. Q: How does serena install? A: uv tool install from oraios/serena at the tag in the version option.
3. Q: How does context-mode install? A: the context-mode npm package, installed globally at the version in the version option.
4. Q: Where do uv and Node come from? A: dependsOn on upstream Features. No Feature bundles its own runtime.
5. Q: For which user? A: every tool installs for $_REMOTE_USER, so it is on that user's PATH.
6. Q: Who writes MCP config? A: nobody in this spec. Features install binaries only; .mcp.json and .cursor/mcp.json stay in each repo.
7. Q: What are agent-stack's options? A: booleans dstack, ponytail, fff, rtk, and versions dstackRef, fffVersion, rtkVersion, each with a tested default.
8. Q: How does dstack install? A: the skills CLI (npx -y skills add) from flumpiey/dstack at dstackRef, all skills, global, for claude-code, codex and opencode, copied not linked, as $_REMOTE_USER.
9. Q: How do fff and RTK install? A: from pinned GitHub release binaries checked by SHA-256. Never through a curl-to-shell installer.
10. Q: Which agents does RTK hook? A: Claude Code only. agent-stack runs rtk init --global in its postCreateCommand. It never writes .cursorrules or Cursor settings. Cursor keeps context-mode.
11. Q: What if ponytail has no public source? A: the ponytail option defaults to false and NOTES.md says why.

User stories, in priority order:
P1 spec-kit. As Dru, I add spec-kit and specify runs as my user at the pinned version.
P1 agent-stack. As Dru, I add agent-stack and the dstack skills, fff and RTK are ready, with RTK hooked into Claude Code.
P2 serena. As Dru, I add serena and the serena command runs as my user.
P2 context-mode. As Dru, I add context-mode and its command runs as my user.

Out of scope: graphify and Honcho; MCP config; Cursor rules; arm64.

Edge cases to specify: github.com unreachable during build; a SHA-256 mismatch; the value latest; rtk init run twice; an existing ~/.claude/settings.json with other keys; a tool already installed by uv; install.sh run twice.

Acceptance criteria (put these in spec.md verbatim):
AC1. As $_REMOTE_USER, specify --version prints the pinned spec-kit version.
AC2. As $_REMOTE_USER, serena --help exits 0 and the installed serena version equals the pinned version.
AC3. As $_REMOTE_USER, the context-mode command prints the pinned version.
AC4. With agent-stack defaults, ~/.claude/skills/dstack-rules/SKILL.md exists for $_REMOTE_USER.
AC5. With agent-stack defaults, the fff and rtk binaries print their pinned versions.
AC6. After container create, ~/.claude/settings.json of $_REMOTE_USER contains an RTK PreToolUse hook and keeps every key it had before, and no .cursorrules file exists in the workspace.
AC7. With fff=false and rtk=false, neither binary is installed and postCreateCommand does nothing for RTK.
AC8. A wrong SHA-256 for fff or rtk fails the build with one error line that names the file.
AC9. Each new install.sh exits 0 when run twice and leaves the same result.
AC10. bash scripts/verify.sh ci passes with the four new Features included.

Success looks like: Dru's dev containers get the whole agent toolchain from four Feature lines.

Open items to leave as clarifications: none.
```

### 2. Clarify

Runs bare.

```text
/speckit-clarify 003-agent-tools
```

### 3. Plan

The first step writes the investigation document.

```text
/speckit-plan 003-agent-tools

First, write docs/analysis/261123-agent-tools.md as a read-only investigation of the anchors below. Where its findings disagree with this plan, the findings win; say so in plan.md.

Anchors:
- src/orca-server/install.sh: download, SHA-256 check against DEFAULT_DEB_SHA256, OS check, idempotency guard.
- scripts/verify.sh after spec 002: per-Feature loops and the constant-equals-default check.
- test/orca-server/install_twice.sh, non_root.sh, secrets_scan.sh, build-fails.sh: test patterns.
- src/node-guard and src/ts7-cli from spec 002: dependsOn node pattern.

Data model: src/spec-kit, src/serena, src/context-mode, src/agent-stack, each with devcontainer-feature.json, install.sh, NOTES.md, and test/<id>/ with test.sh and scenarios.json. agent-stack adds a postCreateCommand that runs rtk init --global only when rtk is true.

Reuse the orca-server download and checksum code shape. Do not touch Features from 001 or 002.

Research before writing code (Context7 and upstream repos; record answers with sources in research.md):
1. The uv Feature to depend on (id and options) and how uv tool install behaves for a non-root user at build time.
2. github/spec-kit release tags and the specify-cli install command.
3. oraios/serena install from a tag and its command name.
4. The context-mode npm package name, binary and current version.
5. The skills CLI syntax for a git ref (owner/repo@ref or a flag).
6. fff and rtk release asset names for linux x86_64, their binary names and published checksums.
7. What rtk init --global writes, and whether a second run duplicates the hook.
8. Whether Feature lifecycle commands (postCreateCommand) run as $_REMOTE_USER.
9. A public source for the ponytail skill.

Constitution principles to cite: I, II, III, IV, V, VII, VIII, XI.

Implementation plan (numbered slices, in order):
1. spec-kit and serena, both on uv. Hard stop before context-mode.
2. context-mode. Hard stop before agent-stack.
3. agent-stack part 1: dstack and ponytail options, install as $_REMOTE_USER, tests for AC4 and AC9. Hard stop before fff and RTK.
4. agent-stack part 2: fff and RTK pinned downloads with SHA-256, postCreateCommand for rtk init --global, tests for AC5 to AC8, README entries.
```

### 4. Checklist

Writes the checklist implement gates on.

```text
/speckit-checklist 003-agent-tools pinned downloads, checksums and non-root installs
```

### 5. Tasks

Dependency-ordered tasks per slice.

```text
/speckit-tasks 003-agent-tools
```

### 6. Analyze

Cross-checks spec, plan and tasks.

```text
/speckit-analyze 003-agent-tools
```

### 6b. Fix analyze findings

Closes findings and checklist items before implement.

```text
Fix every finding in the latest /speckit-analyze report for 003-agent-tools, CRITICAL first, by editing spec.md, plan.md and tasks.md so the finding no longer applies; never by deleting the requirement it points at. Then open every file under specs/003-agent-tools/checklists/ and tick each item that is now true, with one line of evidence per item. Re-run /speckit-analyze 003-agent-tools. Repeat until analyze reports zero findings and no checklist item is unticked. Report the before and after counts and list any item you could not tick with the reason. Do not start implementation.
```

### 7a. Implement slice 1 (mechanical)

Blocked until 002 merges.

```text
/speckit-implement Run slice 1 of the implementation plan in plan.md: the spec-kit and serena Features and their tests. Stop before slice 2.
```

### 7b. Implement slice 2 (mechanical)

context-mode.

```text
/speckit-implement Run slice 2 of the implementation plan in plan.md: the context-mode Feature and its tests. Stop before slice 3.
```

### 7c. Implement slice 3 (judgement)

agent-stack dstack and ponytail.

```text
/speckit-implement Run slice 3 of the implementation plan in plan.md: agent-stack with the dstack and ponytail options and their tests. Stop before slice 4.
```

### 7d. Implement slice 4 (judgement)

agent-stack fff and RTK, the last slice.

```text
/speckit-implement Run slice 4 of the implementation plan in plan.md: agent-stack fff and RTK downloads, the rtk postCreateCommand, tests and README entries. Then run every step in quickstart.md and tick each task in tasks.md that is done, with evidence.
```

### 8. Converge

Repeat until no gaps.

```text
/speckit-converge 003-agent-tools
```

### 9. Sign-off

Last step.

```text
Run bash scripts/verify.sh ci from the repo root. Fix every failure and rerun until it prints "verify: ci ok". Then check every acceptance criterion in specs/003-agent-tools/spec.md and report pass or fail for each, with the command and output that proves it. Do not mark the spec done while any criterion fails or tasks.md has an unticked task.
```
