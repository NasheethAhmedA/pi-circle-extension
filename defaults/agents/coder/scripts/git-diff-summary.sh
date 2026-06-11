#!/bin/bash
set -euo pipefail
# Summarize changes since a reference
# Usage: git-diff-summary.sh [ref]
# Default: HEAD (unstaged changes)

REF="${1:-HEAD}"

echo "📊 Diff Summary (since $REF)"
echo "─────────────────────────────────────"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ Not a git repository"
  exit 1
fi

# Stat summary
echo ""
git diff --stat "$REF" 2>/dev/null || git diff --stat

echo ""
echo "─────────────────────────────────────"

# File-level summary
echo ""
echo "## Changed Files"
git diff --name-status "$REF" 2>/dev/null | while IFS=$'\t' read -r status file; do
  case "$status" in
    A) echo "  ➕ $file" ;;
    M) echo "  ✏️  $file" ;;
    D) echo "  🗑️  $file" ;;
    R*) echo "  🔄 $file" ;;
    *) echo "  ❓ $status $file" ;;
  esac
done

echo ""
INSERTIONS=$(git diff --shortstat "$REF" 2>/dev/null | grep -oP '\d+(?= insertion)' || echo "0")
DELETIONS=$(git diff --shortstat "$REF" 2>/dev/null | grep -oP '\d+(?= deletion)' || echo "0")
echo "Total: +$INSERTIONS -$DELETIONS"
