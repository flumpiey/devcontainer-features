# 002 Env features

- Project: DevcontainerFeatures (flumpiey/devcontainer-features)
- Mode: Existing project, attended, Claude Code (skills mode)
- Generated: 2026-11-23
- Supersedes: none
- Prefix: `/speckit-` (integration claude, invoke separator -, Spec Kit 1.4.4.dev0)
- Investigation source: none yet; the plan block writes docs/analysis/261123-env-features.md
- Update check: not run (no network check from this session)
- ClickUp: skipped (Dru, 2026-11-23)
- Canvas: https://claude.ai/artifact/AWUeDwRM2Jt8mWkQWhxo1d
- Deck: https://claude.ai/artifact/H8V83FuCStUpBqePQWTHjs

Adds the tailnet, node-guard and ts7-cli Features and makes scripts/verify.sh and the release workflow cover every Feature under src/.

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

- Gate: slice 1 (verify.sh) is blocked until spec 001 (orca-server) merges to main, because both change scripts/verify.sh. Merging 001 first closes it.
- A Feature cannot map /dev/net/tun. tailnet documents the runArgs line; a repo still needs it in devcontainer.json.
- The repo has no verify-tasks or reconcile extension and no sdd-verify wrapper, so sign-off is bash scripts/verify.sh ci. It builds every Feature on three bases and takes a long time.
- release.yaml only triggers on src/orca-server/**. Slice 1 widens it to src/**, or nothing new publishes.
- The speckit-runbook command reference was verified on Spec Kit 0.16.2; this repo runs 1.4.4.dev0. The repo's own skills were used for the command names.
- The runbooks for specs 002 to 005 are saved in DevcontainerFeatures-Output/, which .gitignore does not list. Do not commit that folder.
- Maintenance owed: the speckit-runbook reference files still need the corrections listed in the skill. Mentioned once here.

## Manual steps

### 1. Specify

Run in a Claude Code session on a worktree branched from up-to-date main. The explicit number avoids a clash with 001.

```text
/speckit-specify Use feature number 002 and short name env-features: run create-new-feature.ps1 with -Number 2 -ShortName env-features -AllowExistingBranch.

Goal: add three Dev Container Features to flumpiey/devcontainer-features: tailnet, node-guard and ts7-cli. Make scripts/verify.sh and .github/workflows/release.yaml cover every Feature under src/, not orca-server only. NOT: no change to orca-server behaviour other than one installsAfter entry. NOT: no MCP or agent tooling (spec 003). NOT: no arm64.

Context: the repo publishes Features to ghcr.io/flumpiey/devcontainer-features. orca-server (spec 001) is the only Feature so far. Dru runs one dev container per Nx monorepo (pnpm, Biome) on dru-main-pc under Docker Desktop with a 17 GB WSL2 limit. Each dev container joins the tailnet boga-amberjack.ts.net through the ghcr.io/tailscale/codespace/tailscale Feature, with Tailscale SSH, tag tag:devcontainer and hostname <prefix>-<folder>-dev. Today every repo copies that block by hand. Agent-started test, type-check and build runs exhaust memory and make Docker Desktop unresponsive.

Decided, do not re-ask in clarify:
1. Q: Does tailnet install Tailscale itself? A: No. tailnet depends on ghcr.io/tailscale/codespace/tailscale through dependsOn and configures it.
2. Q: Where does the auth key come from? A: tailnet reads it at container start from the environment variable named by the authKeyVar option, default TS_AUTH_KEY. The key never enters an image layer.
3. Q: What does tailscale up use? A: Tailscale SSH on, the tags option (default tag:devcontainer), and hostname <hostnamePrefix>-<workspace folder name>-dev, lower case, with any character outside a-z, 0-9 and hyphen replaced by a hyphen.
4. Q: Can tailnet block container start? A: No. Its entrypoint starts the join in the background, logs failures, and ends with exec "$@" (Constitution VI).
5. Q: Does orca-server change? A: Only one line: orca-server adds tailnet to installsAfter.
6. Q: What does node-guard set? A: containerEnv only: NODE_OPTIONS=--max-old-space-size=2048, NX_PARALLEL=1, NX_DAEMON=false, and a test-runner worker limit of 1. It has no options. A repo overrides a value in devcontainer.json remoteEnv.
7. Q: Does ts7-cli replace tsc? A: No. It installs the TypeScript 7 CLI as a global npm package pinned by a version option, beside each repo's own TypeScript 6.
8. Q: Where does Node come from for ts7-cli? A: dependsOn ghcr.io/devcontainers/features/node.
9. Q: How does verify.sh find Features? A: From src/*/devcontainer-feature.json. fast, push and ci run for every Feature found.

User stories, in priority order:
P1 tailnet. As Dru, I add tailnet to devcontainer.json and set TS_AUTH_KEY on the host. The container joins the tailnet as <prefix>-<folder>-dev with tag:devcontainer and Tailscale SSH.
P1 node-guard. As Dru, I add node-guard. Every process in the container, including agent-spawned terminals, has the heap cap and the Nx limits.
P2 ts7-cli. As Dru, I add ts7-cli and run the TypeScript 7 CLI by name for type checks.
P2 verify. As the maintainer, bash scripts/verify.sh ci tests every Feature on bookworm, jammy and noble, and release.yaml publishes every Feature.

Out of scope: Tailscale ACLs and tag owners; /dev/net/tun mapping (a Feature cannot add devices, so the tailnet NOTES.md documents the runArgs line); MCP config; Windows or macOS container bases.

Edge cases to specify: the auth key variable is unset; tailscaled is not running; Tailscale is already up with another hostname after a restart; the workspace folder name has spaces or capitals; install.sh runs twice; the base is not Debian 12, Ubuntu 22.04 or Ubuntu 24.04 on amd64.

Acceptance criteria (put these in spec.md verbatim):
AC1. With TS_AUTH_KEY set and /dev/net/tun mapped, a tailnet container reports BackendState Running in tailscale status --json within 120 seconds of start, with hostname <prefix>-<folder>-dev and tag tag:devcontainer.
AC2. With TS_AUTH_KEY unset, the container starts, a shell opens, and the tailnet log has one line that names the missing variable.
AC3. docker history and the repo secrets scan of a tailnet test image show no auth key.
AC4. In a node-guard container, a non-login shell prints --max-old-space-size=2048 for NODE_OPTIONS, 1 for NX_PARALLEL and false for NX_DAEMON.
AC5. In a ts7-cli container, the TypeScript 7 CLI prints the pinned version, and the repo's own tsc still prints its TypeScript 6 version.
AC6. Each new install.sh exits 0 when run twice and leaves the same result.
AC7. On an unsupported base, each new install.sh exits non-zero with one error line that names the supported bases.
AC8. bash scripts/verify.sh ci tests orca-server, tailnet, node-guard and ts7-cli on bookworm, jammy and noble, and prints "verify: ci ok".
AC9. src/orca-server/devcontainer-feature.json lists tailnet in installsAfter.
AC10. release.yaml triggers on a change to any path under src/.

Success looks like: Dru replaces the hand-copied Tailscale block and memory env lines in tal, captive-coalition and smartbiii-platform with three Feature lines.

Open items to leave as clarifications: none.
```

### 2. Clarify

Runs bare, because specify carried every decision.

```text
/speckit-clarify 002-env-features
```

### 3. Plan

Carries the anchors, research items and slice plan. The first step writes the investigation document.

```text
/speckit-plan 002-env-features

First, write docs/analysis/261123-env-features.md as a read-only investigation of the anchors below. Where its findings disagree with this plan, the findings win; say so in plan.md.

Anchors (read, do not guess):
- scripts/verify.sh: fast() hardcodes src/orca-server paths in the shell-file find and in the FR-024 constant check; default_test() and scenarios() pass -f orca-server; ci runs test/orca-server/build-fails.sh and test/orca-server/secrets_scan.sh.
- .github/workflows/release.yaml: paths filter is src/orca-server/** only.
- .github/workflows/test.yaml: validate step uses base-path-to-features ./src.
- src/orca-server/devcontainer-feature.json: installsAfter list, entrypoint, version option pattern.
- src/orca-server/install.sh and entrypoint.sh: OS check, DEFAULT_VERSION constant, background start, exec "$@".
- test/_global/scenarios.json and test/_global/tailscale_stub: reuse the stub for tailnet tests.
- test/orca-server/: test.sh, scenarios.json, install_twice.sh, non_root.sh, secrets_scan.sh as patterns.

Data model: three Feature directories src/tailnet, src/node-guard, src/ts7-cli, each with devcontainer-feature.json, install.sh, NOTES.md, and test/<id>/ with test.sh and scenarios.json.
- tailnet options: hostnamePrefix (string, default empty meaning the host's HOSTNAME_PREFIX environment variable), tags (string, default tag:devcontainer), authKeyVar (string, default TS_AUTH_KEY), ssh (boolean, default true). capAdd NET_ADMIN and NET_RAW. dependsOn ghcr.io/tailscale/codespace/tailscale. Entrypoint script.
- node-guard: containerEnv only, no options.
- ts7-cli: version option with a tested default; dependsOn ghcr.io/devcontainers/features/node.

Reuse: the orca-server OS check, constant-equals-default check, entrypoint shape and test scripts. Do not touch orca-server logic.

Research before writing code (use Context7 and the upstream repos; record answers in research.md with sources):
1. Feature dependsOn and installsAfter semantics, and whether a Feature can add devices (expected: no).
2. How an entrypoint finds the workspace folder name, and whether containerEnv expands ${containerWorkspaceFolderBasename}.
3. The ghcr.io/tailscale/codespace/tailscale Feature: options, whether it starts tailscaled, and its userspace fallback.
4. The npm package and binary name of the TypeScript 7 CLI and its current stable version.
5. The environment variables that cap workers for Vitest and Jest.

Constitution principles to cite: I, II, III, IV, V, VI, VII, VIII, XI.

Implementation plan (numbered slices, in order):
1. Generalise verify.sh and release.yaml. Discover Features from src/*/devcontainer-feature.json; loop default_test and scenarios per Feature; run build-fails.sh and secrets_scan.sh per Feature only where present; apply the constant-equals-default check to every Feature that has a version option; widen release.yaml paths to src/**. Hard stop: orca-server still passes ci; no new Feature yet.
2. node-guard. Feature, NOTES.md and tests for AC4, AC6, AC7. Hard stop before ts7-cli.
3. ts7-cli. Feature, NOTES.md and tests for AC5, AC6, AC7. Hard stop before tailnet.
4. tailnet. Feature, entrypoint, NOTES.md with the runArgs line, tests with the tailscale stub for AC1 to AC3, AC6, AC7, and the orca-server installsAfter line for AC9. Hard stop: README gains the three Features.
```

### 4. Checklist

Writes the requirement-quality checklist that implement gates on.

```text
/speckit-checklist 002-env-features security, idempotency and pinned versions
```

### 5. Tasks

Breaks the plan into dependency-ordered tasks per slice.

```text
/speckit-tasks 002-env-features
```

### 6. Analyze

Cross-checks spec, plan and tasks before any code.

```text
/speckit-analyze 002-env-features
```

### 6b. Fix analyze findings

Implement refuses to start while a checklist item is unticked; this closes them.

```text
Fix every finding in the latest /speckit-analyze report for 002-env-features, CRITICAL first, by editing spec.md, plan.md and tasks.md so the finding no longer applies; never by deleting the requirement it points at. Then open every file under specs/002-env-features/checklists/ and tick each item that is now true, with one line of evidence per item. Re-run /speckit-analyze 002-env-features. Repeat until analyze reports zero findings and no checklist item is unticked. Report the before and after counts and list any item you could not tick with the reason. Do not start implementation.
```

### 7a. Implement slice 1 (mechanical)

Blocked until 001 merges to main.

```text
/speckit-implement Run slice 1 of the implementation plan in plan.md: generalise scripts/verify.sh and release.yaml to every Feature under src/. Stop before slice 2.
```

### 7b. Implement slice 2 (mechanical)

node-guard.

```text
/speckit-implement Run slice 2 of the implementation plan in plan.md: the node-guard Feature and its tests. Stop before slice 3.
```

### 7c. Implement slice 3 (mechanical)

ts7-cli.

```text
/speckit-implement Run slice 3 of the implementation plan in plan.md: the ts7-cli Feature and its tests. Stop before slice 4.
```

### 7d. Implement slice 4 (judgement)

tailnet, the last slice.

```text
/speckit-implement Run slice 4 of the implementation plan in plan.md: the tailnet Feature, its tests, the orca-server installsAfter line and the README entries. Then run every step in quickstart.md and tick each task in tasks.md that is done, with evidence.
```

### 8. Converge

Repeat implement and converge until converge reports no gaps.

```text
/speckit-converge 002-env-features
```

### 9. Sign-off

Last step. The merge waits on this.

```text
Run bash scripts/verify.sh ci from the repo root. Fix every failure and rerun until it prints "verify: ci ok". Then check every acceptance criterion in specs/002-env-features/spec.md and report pass or fail for each, with the command and output that proves it. Do not mark the spec done while any criterion fails or tasks.md has an unticked task.
```
