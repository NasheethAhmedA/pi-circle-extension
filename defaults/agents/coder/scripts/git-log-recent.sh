#!/bin/bash
set -euo pipefail
# Show recent commits
# Usage: git-log-recent.sh [count]

COUNT="${1:-10}"

echo "📜 Recent Commits (last $COUNT)"
echo "─────────────────────────────────────"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not a git repository"
  exit 1
fi

git log --oneline --decorate -n "$COUNT"
