# 005 Collection listing

- Project: DevcontainerFeatures (flumpiey/devcontainer-features)
- Mode: Existing project, attended, Claude Code (skills mode)
- Generated: 2026-11-23
- Supersedes: none
- Prefix: `/speckit-` (integration claude, invoke separator -, Spec Kit 1.4.4.dev0)
- Investigation source: none yet; the plan block writes docs/analysis/261123-collection-listing.md
- Update check: not run (no network check from this session)
- ClickUp: skipped (Dru, 2026-11-23)
- Canvas: https://claude.ai/artifact/AWUeDwRM2Jt8mWkQWhxo1d
- Deck: https://claude.ai/artifact/H8V83FuCStUpBqePQWTHjs

Prepares the containers.dev listing: README index of every Feature, the collection-index entry, and a check that the collection is public. Dru opens the PR.

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

- Gate: run after 002, 003 and 004 merge and publish, so the README and the listing cover all ten Features.
- Dru sets each GHCR package to public on github.com before step 10. The agent cannot do that.
- Steps 10a to 10e open a PR on devcontainers/devcontainers.github.io. That is a public post; Dru runs them himself.
- Maintenance owed: the speckit-runbook reference files still need the corrections listed in the skill. Mentioned once here.

## Manual steps

### 1. Specify

Run from up-to-date main after 004 merges.

```text
/speckit-specify Use feature number 005 and short name collection-listing: run create-new-feature.ps1 with -Number 5 -ShortName collection-listing -AllowExistingBranch.

Goal: prepare the listing of ghcr.io/flumpiey/devcontainer-features on containers.dev. NOT: the agent does not fork, push to, or open a PR on devcontainers/devcontainers.github.io. NOT: no Feature code changes.

Context: containers.dev lists a collection when a PR to devcontainers/devcontainers.github.io, branch gh-pages, adds an entry to _data/collection-index.yml. The release workflow publishes Features and the collection metadata with devcontainers/action. The collection holds orca-server, tailnet, node-guard, ts7-cli, spec-kit, serena, context-mode, agent-stack, git-guard and agent-browser.

Decided, do not re-ask in clarify:
1. Q: Who opens the PR? A: Dru. The agent prepares the entry only.
2. Q: Which fields does the entry have? A: the same fields as the existing entries in _data/collection-index.yml, read from that file at plan time. Expected: name, maintainer, contact, repository, ociReference.
3. Q: Entry values? A: name "Malva Dev Features", maintainer "Dru Connold", contact https://github.com/flumpiey/devcontainer-features/issues, repository https://github.com/flumpiey/devcontainer-features, ociReference ghcr.io/flumpiey/devcontainer-features.
4. Q: What does the README hold? A: one section per Feature with a one-line description and a devcontainer.json snippet.
5. Q: Who makes the packages public? A: Dru, on github.com.

User stories, in priority order:
P1 README. As a visitor, I see every Feature with a snippet I can paste.
P1 Entry file. As Dru, I paste a ready entry from docs/containers-dev/collection-index-entry.yml.
P2 Public check. As Dru, I run one script that confirms the collection metadata is readable without a login.

Out of scope: Feature code, release workflow changes, the PR itself.

Edge cases to specify: a package still private; the upstream file gains a new required field; a Feature missing from the README.

Acceptance criteria (put these in spec.md verbatim):
AC1. README.md has one section for each of the ten Features, each with a description line and a devcontainer.json snippet that names ghcr.io/flumpiey/devcontainer-features/<id>:1.
AC2. docs/containers-dev/collection-index-entry.yml is valid YAML with exactly the fields the upstream entries use, and the values in decision 3.
AC3. scripts/check-public.sh exits 0 when an anonymous request reads the collection metadata and every Feature manifest, and exits non-zero naming each one it cannot read.
AC4. bash scripts/verify.sh fast passes.

Success looks like: Dru pastes one entry into a PR and the collection appears on containers.dev after merge.

Open items to leave as clarifications: none.
```

### 2. Clarify

Runs bare.

```text
/speckit-clarify 005-collection-listing
```

### 3. Plan

The first step writes the investigation document.

```text
/speckit-plan 005-collection-listing

First, write docs/analysis/261123-collection-listing.md as a read-only investigation of the anchors below. Where its findings disagree with this plan, the findings win; say so in plan.md.

Anchors:
- README.md: current orca-server section and Checks section.
- .github/workflows/release.yaml: devcontainers/action publish step with generate-docs.
- src/*/devcontainer-feature.json: id, name, description of each Feature.
- https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml: field names of existing entries.

Research (record in research.md with sources):
1. The OCI reference of the collection metadata that devcontainers/action publishes.
2. How to read a GHCR manifest anonymously (token endpoint for public packages).

Constitution principles to cite: II, VIII, X, XI.

Implementation plan (numbered slices, in order):
1. README sections for all ten Features. Hard stop before the entry file.
2. docs/containers-dev/collection-index-entry.yml and scripts/check-public.sh with a test. Hard stop: nothing touches the upstream repo.
```

### 4. Checklist

Writes the checklist implement gates on.

```text
/speckit-checklist 005-collection-listing documentation completeness
```

### 5. Tasks

Dependency-ordered tasks.

```text
/speckit-tasks 005-collection-listing
```

### 6. Analyze

Cross-checks spec, plan and tasks.

```text
/speckit-analyze 005-collection-listing
```

### 6b. Fix analyze findings

Closes findings and checklist items.

```text
Fix every finding in the latest /speckit-analyze report for 005-collection-listing, CRITICAL first, by editing spec.md, plan.md and tasks.md so the finding no longer applies; never by deleting the requirement it points at. Then open every file under specs/005-collection-listing/checklists/ and tick each item that is now true, with one line of evidence per item. Re-run /speckit-analyze 005-collection-listing. Repeat until analyze reports zero findings and no checklist item is unticked. Report the before and after counts and list any item you could not tick with the reason. Do not start implementation.
```

### 7a. Implement slice 1 (mechanical)

README.

```text
/speckit-implement Run slice 1 of the implementation plan in plan.md: README sections for all ten Features. Stop before slice 2.
```

### 7b. Implement slice 2 (mechanical)

Entry file and public check, the last slice.

```text
/speckit-implement Run slice 2 of the implementation plan in plan.md: the collection-index entry file and scripts/check-public.sh with its test. Then run every step in quickstart.md and tick each task in tasks.md that is done, with evidence.
```

### 8. Converge

Repeat until no gaps.

```text
/speckit-converge 005-collection-listing
```

### 9. Sign-off

Last Spec Kit step.

```text
Run bash scripts/verify.sh ci from the repo root. Fix every failure and rerun until it prints "verify: ci ok". Then check every acceptance criterion in specs/005-collection-listing/spec.md and report pass or fail for each, with the command and output that proves it. Do not mark the spec done while any criterion fails or tasks.md has an unticked task.
```

### 10a. Fork and clone (Dru)

Run in a folder outside the repo, after the packages are public.

```text
gh repo fork devcontainers/devcontainers.github.io --clone -- --branch gh-pages
```

### 10b. Branch (Dru)

Creates the PR branch.

```text
cd devcontainers.github.io && git switch -c add-flumpiey-devcontainer-features
```

### 10c. Add the entry (Dru)

Open _data/collection-index.yml, paste the entry from docs/containers-dev/collection-index-entry.yml in alphabetical position, then commit.

```text
git commit -am "Add flumpiey devcontainer-features collection"
```

### 10d. Push (Dru)

Pushes the branch to your fork.

```text
git push -u origin add-flumpiey-devcontainer-features
```

### 10e. Open the PR (Dru)

Opens the listing PR against gh-pages.

```text
gh pr create --repo devcontainers/devcontainers.github.io --base gh-pages --title "Add flumpiey devcontainer-features collection" --body "Adds the Malva Dev Features collection (ghcr.io/flumpiey/devcontainer-features)."
```
