#!/bin/bash
set -euo pipefail
# Skill: list-ideas
# Lists all idea directories in the workspace with their status
# Usage: list-ideas.sh [search-directory]

show_help() {
  echo "Usage: $(basename "$0") [search-directory]"
  echo ""
  echo "Lists all *_idea/ directories with their phase, content stats, and last change."
  echo ""
  echo "Arguments:"
  echo "  search-directory   Directory to search in (default: current directory)"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

SEARCH_DIR="${1:-.}"

IDEA_DIRS=$(find "$SEARCH_DIR" -maxdepth 1 -type d -name "*_idea" 2>/dev/null | sort)

if [ -z "$IDEA_DIRS" ]; then
  echo "📋 No idea directories found in $(cd "$SEARCH_DIR" && pwd)"
  echo ""
  echo "Start a new idea with: ./skills/init-idea.sh <idea-name>"
  exit 0
fi

COUNT=$(echo "$IDEA_DIRS" | wc -l | tr -d ' ')

echo "═══════════════════════════════════════════"
echo "  📋 IDEAS IN WORKSPACE ($COUNT found)"
echo "═══════════════════════════════════════════"
echo ""

while IFS= read -r dir; do
  [ -d "$dir" ] || continue
  DIR_NAME=$(basename "$dir")
  IDEA_NAME="${DIR_NAME%_idea}"

  # Get phase
  PHASE="Unknown"
  if [ -f "$dir/CONTEXT.md" ]; then
    PHASE=$(grep "^## Status:" "$dir/CONTEXT.md" 2>/dev/null | head -1 | sed 's/^## Status: //' || echo "Unknown")
  fi

  # Count content
  FILES=$(find "$dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  EXPLORATIONS=$(find "$dir/explorations" -name "approach-*.md" 2>/dev/null | wc -l | tr -d ' ')
  DECISIONS=$(find "$dir/decisions" -name "decision-*.md" 2>/dev/null | wc -l | tr -d ' ')
  SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)

  # Last change
  LAST_CHANGE=""
  if [ -f "$dir/changelog.md" ]; then
    LAST_CHANGE=$(grep "^## " "$dir/changelog.md" 2>/dev/null | head -1 | sed 's/^## //')
  fi

  echo "  📁 $IDEA_NAME"
  echo "     Phase: $PHASE"
  echo "     Files: $FILES md | $EXPLORATIONS approaches | $DECISIONS decisions"
  echo "     Size: $SIZE"
  [ -n "$LAST_CHANGE" ] && echo "     Last: $LAST_CHANGE"
  echo ""
done <<< "$IDEA_DIRS"

echo "═══════════════════════════════════════════"
echo "  Use: idea-status.sh <name> for details"
echo "  Use: idea-tree.sh <name> for file tree"
echo "═══════════════════════════════════════════"
