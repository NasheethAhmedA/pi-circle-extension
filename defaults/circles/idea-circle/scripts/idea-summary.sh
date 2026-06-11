#!/bin/bash
set -euo pipefail
# Skill: idea-summary
# Generates a concise summary of the current idea state (for quick recall)
# Usage: idea-summary.sh <idea-name> [--json]
# Example: idea-summary.sh "smart-home-hub"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> [--json]"
  echo ""
  echo "Generates a quick-recall summary of the idea's current state."
  echo "Useful for beginning a session or handing off context."
  echo ""
  echo "Options:"
  echo "  --json    Output in JSON format (for programmatic use)"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
FORMAT="${2:-text}"

if [ -z "$IDEA_NAME" ]; then
  echo "Error: Please provide an idea name" >&2
  echo "Usage: $(basename "$0") <idea-name>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

# Extract key info
PHASE="Unknown"
ONE_LINE=""
if [ -f "$IDEA_DIR/CONTEXT.md" ]; then
  PHASE=$(grep "^## Status:" "$IDEA_DIR/CONTEXT.md" 2>/dev/null | head -1 | sed 's/^## Status: //' || echo "Unknown")
  ONE_LINE=$(grep "^## One-Line Summary" -A 1 "$IDEA_DIR/CONTEXT.md" 2>/dev/null | tail -1 | sed 's/^\*//' | sed 's/\*$//' || echo "")
fi

# Count items
EXPLORATIONS=$(find "$IDEA_DIR/explorations" -name "approach-*.md" 2>/dev/null | wc -l)
DECISIONS=$(find "$IDEA_DIR/decisions" -name "decision-*.md" 2>/dev/null | wc -l)
CRITIQUES=$(find "$IDEA_DIR/critiques" -name "critique-*.md" 2>/dev/null | wc -l)
ENHANCEMENTS=$(find "$IDEA_DIR/enhancements" -name "enhancement-*.md" 2>/dev/null | wc -l)
OPEN_Q=$(grep -c "^- " "$IDEA_DIR/questions/open.md" 2>/dev/null || echo "0")

# Get latest changelog
LAST_CHANGE=$(grep "^## " "$IDEA_DIR/changelog.md" 2>/dev/null | head -1 | sed 's/^## //' || echo "None")

# Get open questions (first 3)
TOP_QUESTIONS=$(grep "^- " "$IDEA_DIR/questions/open.md" 2>/dev/null | head -3 | sed 's/^- //' || echo "")

if [ "$FORMAT" = "--json" ]; then
  cat << ENDJSON
{
  "name": "$FOLDER_NAME",
  "phase": "$PHASE",
  "summary": "$ONE_LINE",
  "explorations": $EXPLORATIONS,
  "decisions": $DECISIONS,
  "critiques": $CRITIQUES,
  "enhancements": $ENHANCEMENTS,
  "open_questions": $OPEN_Q,
  "last_change": "$LAST_CHANGE"
}
ENDJSON
  exit 0
fi

# Text output
echo "┌─────────────────────────────────────────────────────┐"
echo "│  📋 IDEA SUMMARY: ${FOLDER_NAME//-/ }"
echo "├─────────────────────────────────────────────────────┤"
echo "│  Phase: $PHASE"
[ -n "$ONE_LINE" ] && [ "$ONE_LINE" != "To be defined." ] && echo "│  Summary: $ONE_LINE"
echo "│"
echo "│  📊 Stats:"
echo "│    Explorations: $EXPLORATIONS | Decisions: $DECISIONS"
echo "│    Critiques: $CRITIQUES | Enhancements: $ENHANCEMENTS"
echo "│    Open Questions: $OPEN_Q"
echo "│"
echo "│  📝 Last activity: $LAST_CHANGE"

if [ -n "$TOP_QUESTIONS" ] && [ "$OPEN_Q" -gt 0 ]; then
  echo "│"
  echo "│  ❓ Top open questions:"
  echo "$TOP_QUESTIONS" | head -3 | while IFS= read -r q; do
    echo "│    • $q"
  done
fi

echo "└─────────────────────────────────────────────────────┘"
