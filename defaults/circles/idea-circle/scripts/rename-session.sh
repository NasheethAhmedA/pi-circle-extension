#!/bin/bash
set -euo pipefail
# Skill: rename-session
# Generates and outputs the recommended session name based on idea state
# Usage: rename-session.sh [custom-name]
# Note: Outputs the name. Actual platform rename depends on the agent harness.

show_help() {
  echo "Usage: $(basename "$0") [custom-name]"
  echo ""
  echo "Generates a session name based on the current idea and phase."
  echo "If no custom name given, auto-generates from the idea directory."
  echo ""
  echo "Format: 'Idea: <Name> [<Phase>]'"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0")                    # Auto-detect"
  echo "  $(basename "$0") \"My Custom Name\"   # Custom name"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

NEW_NAME="${1:-}"

if [ -z "$NEW_NAME" ]; then
  # Auto-detect from idea directories
  IDEA_DIR=$(find . -maxdepth 1 -type d -name "*_idea" 2>/dev/null | head -1 | sed 's|^./||')
  
  if [ -z "$IDEA_DIR" ]; then
    echo "Error: No idea directory found and no name provided" >&2
    echo "Usage: $(basename "$0") <new-name>" >&2
    exit 1
  fi
  
  # Extract human-readable name
  IDEA_SLUG="${IDEA_DIR%_idea}"
  IDEA_HUMAN=$(echo "$IDEA_SLUG" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g' 2>/dev/null || echo "$IDEA_SLUG")
  
  # Get current phase
  PHASE=""
  if [ -f "$IDEA_DIR/CONTEXT.md" ]; then
    PHASE=$(grep "^## Status:" "$IDEA_DIR/CONTEXT.md" 2>/dev/null | head -1 | sed 's/^## Status: //' || echo "")
  fi
  
  if [ -n "$PHASE" ]; then
    NEW_NAME="Idea: $IDEA_HUMAN [$PHASE]"
  else
    NEW_NAME="Idea: $IDEA_HUMAN"
  fi
fi

echo "📝 Recommended Session Name:"
echo ""
echo "   $NEW_NAME"
echo ""
echo "─────────────────────────────────────"
echo "To apply: Use your platform's session/chat rename feature."
echo ""
echo "Suggested naming patterns:"
echo "  • 'Idea: <Name> [Discovery]'"
echo "  • 'Idea: <Name> [Exploration]'"
echo "  • 'Idea: <Name> [Refinement]'"
echo "  • 'Idea: <Name> [Ready to Build]'"
echo "  • 'Idea: <Name> — Revisit #2'"
