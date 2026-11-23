<!--
Sync Impact Report (temporary: remove before commit)
Version change: unfilled template -> 1.0.0
Modified principles: none (initial ratification)
Added principles: I to XI (see Core Principles)
Added sections: Platform and Distribution Constraints; Development Workflow and Quality Gates
Removed sections: none
Deferred items: none
-->
# devcontainer-features Constitution

Repository: flumpiey/devcontainer-features. Features publish to
ghcr.io/flumpiey/devcontainer-features.

## Core Principles

### I. Spec-Compliant Features
Every Feature MUST follow the containers.dev Feature reference. Each Feature MUST have
`src/<id>/devcontainer-feature.json`, `src/<id>/install.sh`, and `test/<id>/` containing
`test.sh` and `scenarios.json`.
Rationale: tooling such as the devcontainer CLI and the publish action relies on this layout.

### II. Bash Only for Scripts
Every script MUST be Bash and MUST start with `set -euo pipefail`. Every script MUST pass
`shellcheck` with no warnings and MUST pass `shfmt -d` with 2-space indent.
Rationale: one language and one strict mode keep failures loud and reviews short.

### III. Idempotent Installs
Running `install.sh` twice MUST give the same result and MUST NOT raise an error.
Rationale: image rebuilds and layered Features re-run installs.

### IV. Pinned Versions
Every downloaded artefact MUST be pinned by a Feature option. The option default MUST be a
tested version. The value `latest` is allowed only as an explicit choice by the user.
Rationale: a build must give the same result next month as today.

### V. No Secrets in Images
No token, auth key or pairing grant MAY be written into an image layer. Runtime secrets MUST
come from the environment or from a named volume.
Rationale: image layers are readable by anyone who can pull the image.

### VI. Entrypoints Never Block Container Start
An entrypoint MUST start its service in the background and MUST always end with `exec "$@"`.
A service failure MUST be logged and MUST NOT be fatal to the container.
Rationale: a broken service must not lock the user out of their dev container.

### VII. Debian and Ubuntu First
Supported bases are Debian 12, Ubuntu 22.04 and Ubuntu 24.04 on amd64. On any other base,
`install.sh` MUST fail with one clear error line.
Rationale: a narrow, tested matrix gives reliable installs and honest failures.

### VIII. Tests Before Done
A change is done only when `bash scripts/verify.sh ci` passes.
Rationale: one command is the single definition of done for people and agents.

### IX. Conventional Commits, No AI Attribution
Commits MUST follow Conventional Commits and MUST pass commitlint. Commits and pull requests
MUST NOT carry AI attribution: no "Generated with" lines and no AI `Co-Authored-By` trailers.
Rationale: history stays machine-readable and authorship stays with the people who accept it.

### X. Plain British Spelling in Docs
Documentation MUST use plain British spelling. Documentation MUST NOT contain em dashes, en
dashes or emojis.
Rationale: one consistent house style.

### XI. Smallest Change That Meets the Spec
Each change MUST be the smallest change that meets the spec. Follow the ponytail skill: no
speculative options, layers or abstractions. Ponytail MUST NOT remove a requirement or an
acceptance criterion from `spec.md`. Where ponytail and the spec conflict, the spec wins.
Rationale: less code means less to test, secure and maintain, but never less than the spec.

## Platform and Distribution Constraints

- Target architecture is amd64 only. Other architectures are out of scope until the
  constitution is amended.
- Features publish to ghcr.io/flumpiey/devcontainer-features.
- Each Feature MUST document its options, their defaults and the tested version in its
  `devcontainer-feature.json` option descriptions.

## Development Workflow and Quality Gates

- Run `bash scripts/verify.sh ci` before every commit that changes a Feature, a test or a
  script. A failing run blocks the change.
- Commit messages pass commitlint locally (lefthook) and in CI.
- A Feature change adds or updates its `test/<id>/` scenarios in the same commit.
- A reviewer MUST check each pull request against the Core Principles and note any
  justified exception in the pull request description.

## Governance

This constitution supersedes other practices in this repository. Where a template, script or
habit conflicts with it, the constitution wins.

Amendment procedure: propose the change in a pull request that edits
`.specify/memory/constitution.md`, state the rationale, and obtain maintainer approval. A
change that alters a principle MUST list any dependent templates or scripts that need updates.

Versioning policy: Semantic Versioning. MAJOR for removal or redefinition of a principle.
MINOR for a new principle or section, or materially expanded guidance. PATCH for wording and
clarifications.

Compliance review: every pull request is checked against the Core Principles. Exceptions are
recorded in the pull request description and expire when the pull request merges.

**Version**: 1.0.0 | **Ratified**: 2026-11-23 | **Last Amended**: 2026-11-23
