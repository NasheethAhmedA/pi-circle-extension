#!/bin/bash
set -euo pipefail
# Skill: search-idea
# Full-text search across all idea documentation files
# Usage: search-idea.sh <idea-name> <search-term> [--context N]
# Example: search-idea.sh "smart-home-hub" "authentication" --context 2

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <search-term> [--context N]"
  echo ""
  echo "Searches all .md files in the idea folder for a term/pattern."
  echo "Returns matching lines with file paths and line numbers."
  echo ""
  echo "Arguments:"
  echo "  idea-name     Name/slug of the idea"
  echo "  search-term   Text or regex pattern to search for"
  echo "  --context N   Show N lines of context around matches (default: 1)"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") smart-home-hub \"authentication\""
  echo "  $(basename "$0") smart-home-hub \"TODO\\|FIXME\" --context 2"
  echo "  $(basename "$0") smart-home-hub \"scalab\" --context 0"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
SEARCH_TERM="${2:-}"
CONTEXT_LINES=1

# Parse optional --context flag
shift 2 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --context|-c|-C)
      CONTEXT_LINES="${2:-1}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$IDEA_NAME" ] || [ -z "$SEARCH_TERM" ]; then
  echo "Error: Please provide idea name and search term" >&2
  echo "Usage: $(basename "$0") <idea-name> <search-term>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

echo "🔍 Searching '$SEARCH_TERM' in $IDEA_DIR/"
echo "   Context: $CONTEXT_LINES lines"
echo ""
echo "═══════════════════════════════════════════════════════"

# Search with grep (case-insensitive, with context)
RESULTS=$(grep -rn -i --include="*.md" -C "$CONTEXT_LINES" "$SEARCH_TERM" "$IDEA_DIR/" 2>/dev/null || true)

if [ -z "$RESULTS" ]; then
  echo ""
  echo "  No matches found for: '$SEARCH_TERM'"
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "Tips:"
  echo "  • Try a shorter/broader term"
  echo "  • Use regex: \"auth.*token\""
  echo "  • Search is case-insensitive"
  exit 0
fi

# Count matches
MATCH_COUNT=$(echo "$RESULTS" | grep -c "^$IDEA_DIR/" 2>/dev/null || echo "0")

echo "$RESULTS" | while IFS= read -r line; do
  # Highlight the separator lines
  if [ "$line" = "--" ]; then
    echo "  ─────────────────────────────────────"
  else
    # Make path relative and indent
    echo "  $line"
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  📊 Matches: ~$MATCH_COUNT lines across idea docs"
echo "═══════════════════════════════════════════════════════"
