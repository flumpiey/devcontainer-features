#!/usr/bin/env bash
# scripts/commit-msg.sh
set -euo pipefail

# Lefthook splits {1} on spaces, so read the message path from git instead.
f="$(git rev-parse --git-path COMMIT_EDITMSG)"
grep -viE '^[[:space:]]*(co-authored-by:.*(claude|anthropic|cursor|openai|codex|copilot|gemini|opencode)|claude-session:)|generated with \[?(claude|cursor|codex|copilot|gemini|opencode)|(claude\.ai|claude\.com)/code' "$f" >"$f.tmp" || true
mv "$f.tmp" "$f"
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$f"
