#!/usr/bin/env bash
# scripts/worktree-setup.sh
set -euo pipefail
cd "$ORCA_WORKTREE_PATH"
if [ -f package-lock.json ]; then npm ci; fi
