#!/bin/bash
set -euo pipefail
# Stage all and commit (safe checkpoint)
# Usage: git-checkpoint.sh <message>

MESSAGE="${1:-}"

if [ -z "$MESSAGE" ]; then
  echo "Error: Please provide a commit message" >&2
  echo "Usage: $(basename "$0") <message>" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not a git repository"
  exit 1
fi

# Check if there's anything to commit
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "⚠️  Nothing to commit (working tree clean)"
  exit 0
fi

git add -A
git commit -m "$MESSAGE"

echo ""
echo "✅ Checkpoint: $MESSAGE"
echo "   Commit: $(git rev-parse --short HEAD)"
echo "   Files: $(git diff --name-only HEAD~1 2>/dev/null | wc -l) changed"
