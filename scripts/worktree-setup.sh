#!/usr/bin/env bash
# scripts/worktree-setup.sh
set -euo pipefail
cd "$ORCA_WORKTREE_PATH"
if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; fi
