#!/bin/bash
set -euo pipefail
# Formatted git status
# Usage: git-status.sh

echo "📋 Git Status"
echo "─────────────────────────────────────"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not a git repository"
  exit 1
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
echo "Branch: $BRANCH"

# Upstream info
UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "none")
if [ "$UPSTREAM" != "none" ]; then
  AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
  BEHIND=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
  echo "Upstream: $UPSTREAM (ahead: $AHEAD, behind: $BEHIND)"
fi

echo ""

# Staged
STAGED=$(git diff --cached --name-status 2>/dev/null)
if [ -n "$STAGED" ]; then
  echo "## Staged"
  echo "$STAGED" | sed 's/^/  /'
  echo ""
fi

# Modified
MODIFIED=$(git diff --name-status 2>/dev/null)
if [ -n "$MODIFIED" ]; then
  echo "## Modified (unstaged)"
  echo "$MODIFIED" | sed 's/^/  /'
  echo ""
fi

# Untracked
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)
if [ -n "$UNTRACKED" ]; then
  echo "## Untracked"
  echo "$UNTRACKED" | head -20 | sed 's/^/  /'
  COUNT=$(echo "$UNTRACKED" | wc -l)
  [ "$COUNT" -gt 20 ] && echo "  ... and $((COUNT - 20)) more"
  echo ""
fi

# Clean?
if [ -z "$STAGED" ] && [ -z "$MODIFIED" ] && [ -z "$UNTRACKED" ]; then
  echo "✅ Working tree clean"
fi
