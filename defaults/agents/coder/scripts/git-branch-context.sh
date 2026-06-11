#!/bin/bash
set -euo pipefail
# Show branch context
# Usage: git-branch-context.sh

echo "🌿 Branch Context"
echo "─────────────────────────────────────"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not a git repository"
  exit 1
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached HEAD")
echo "Current: $BRANCH"

# Upstream
UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")
if [ -n "$UPSTREAM" ]; then
  AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
  BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
  echo "Upstream: $UPSTREAM"
  echo "Ahead: $AHEAD commits"
  echo "Behind: $BEHIND commits"
else
  echo "Upstream: (not set)"
fi

echo ""
echo "## Local Branches"
git branch -v --sort=-committerdate | head -10

echo ""
echo "## Last Commit"
git log -1 --format="  %h %s (%ar)"
