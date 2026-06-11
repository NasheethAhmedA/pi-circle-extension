#!/bin/bash
set -euo pipefail
# Skill: idea-status
# Shows current status dashboard of an idea's documentation
# Usage: idea-status.sh [idea-name]
# If no name given, auto-detects or lists available ideas

show_help() {
  echo "Usage: $(basename "$0") [idea-name]"
  echo ""
  echo "Shows a comprehensive status dashboard for an idea."
  echo "If no name provided, lists all available idea directories."
  echo ""
  echo "Output: JSON-structured status (for agent consumption) + visual summary"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"

if [ -z "$IDEA_NAME" ]; then
  # Auto-detect
  IDEA_DIRS=$(find . -maxdepth 1 -type d -name "*_idea" 2>/dev/null | sed 's|^./||' | sort)
  if [ -z "$IDEA_DIRS" ]; then
    echo "Error: No idea directories found in current directory" >&2
    echo "Run init-idea.sh first to create one." >&2
    exit 1
  fi
  COUNT=$(echo "$IDEA_DIRS" | wc -l)
  if [ "$COUNT" -eq 1 ]; then
    IDEA_DIR="$IDEA_DIRS"
    FOLDER_NAME="${IDEA_DIR%_idea}"
  else
    echo "📋 Found $COUNT idea directories:"
    echo ""
    while IFS= read -r dir; do
      NAME="${dir%_idea}"
      PHASE="unknown"
      if [ -f "$dir/CONTEXT.md" ]; then
        PHASE=$(grep "^## Status:" "$dir/CONTEXT.md" 2>/dev/null | head -1 | sed 's/^## Status: //' || echo "unknown")
      fi
      echo "  • $NAME ($PHASE)"
    done <<< "$IDEA_DIRS"
    echo ""
    echo "Run: $(basename "$0") <name> for details"
    exit 0
  fi
else
  FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  IDEA_DIR="${FOLDER_NAME}_idea"
fi

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

# Gather stats
TOTAL_FILES=$(find "$IDEA_DIR" -type f -name "*.md" | wc -l)
TOTAL_SIZE=$(du -sh "$IDEA_DIR" 2>/dev/null | cut -f1)

EXPLORATIONS=$(find "$IDEA_DIR/explorations" -name "approach-*.md" 2>/dev/null | wc -l)
DECISIONS=$(find "$IDEA_DIR/decisions" -name "decision-*.md" 2>/dev/null | wc -l)
CRITIQUES=$(find "$IDEA_DIR/critiques" -name "critique-*.md" 2>/dev/null | wc -l)
ENHANCEMENTS=$(find "$IDEA_DIR/enhancements" -name "enhancement-*.md" 2>/dev/null | wc -l)

OPEN_Q=0
if [ -f "$IDEA_DIR/questions/open.md" ]; then
  OPEN_Q=$(grep -c "^- " "$IDEA_DIR/questions/open.md" 2>/dev/null || echo "0")
fi

RESOLVED_Q=0
if [ -f "$IDEA_DIR/questions/resolved.md" ]; then
  RESOLVED_Q=$(grep -c "^|" "$IDEA_DIR/questions/resolved.md" 2>/dev/null || echo "0")
  RESOLVED_Q=$((RESOLVED_Q > 1 ? RESOLVED_Q - 2 : 0))  # subtract header rows
fi

PHASE="Unknown"
if [ -f "$IDEA_DIR/CONTEXT.md" ]; then
  PHASE=$(grep "^## Status:" "$IDEA_DIR/CONTEXT.md" 2>/dev/null | head -1 | sed 's/^## Status: //' || echo "Unknown")
fi

LAST_CHANGE=""
if [ -f "$IDEA_DIR/changelog.md" ]; then
  LAST_CHANGE=$(grep "^## " "$IDEA_DIR/changelog.md" 2>/dev/null | head -1 | sed 's/^## //')
fi

# Display
echo "═══════════════════════════════════════════════════════"
echo "  📊 IDEA STATUS: ${FOLDER_NAME//-/ }"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🎯 Phase: $PHASE"
echo "📁 Files: $TOTAL_FILES markdown files ($TOTAL_SIZE)"
echo ""
echo "📊 Content Breakdown:"
echo "   📐 Explorations:  $EXPLORATIONS approaches documented"
echo "   📋 Decisions:     $DECISIONS decisions recorded"
echo "   🔍 Critiques:     $CRITIQUES critiques filed"
echo "   ✨ Enhancements:  $ENHANCEMENTS enhancements proposed"
echo "   ❓ Open questions: $OPEN_Q"
echo "   ✅ Resolved:      $RESOLVED_Q"
echo ""
if [ -n "$LAST_CHANGE" ]; then
  echo "📝 Latest change: $LAST_CHANGE"
  echo ""
fi

# Completeness check
echo "📋 Completeness:"
check_filled() {
  local file="$1"
  local label="$2"
  if [ ! -f "$file" ]; then
    echo "   ⬜ $label (missing)"
  elif grep -q "^\*To be\|^\*Description\|^\*None yet" "$file" 2>/dev/null; then
    echo "   🟡 $label (template — needs content)"
  else
    echo "   ✅ $label"
  fi
}

check_filled "$IDEA_DIR/concept/core.md" "Core Concept"
check_filled "$IDEA_DIR/concept/vision.md" "Vision & Goals"
check_filled "$IDEA_DIR/concept/scope.md" "Scope & Boundaries"
check_filled "$IDEA_DIR/roadmap.md" "Roadmap"
check_filled "$IDEA_DIR/CONTEXT.md" "Context (handoff)"

echo ""
echo "═══════════════════════════════════════════════════════"

# Also output JSON for programmatic consumption
cat << ENDJSON > /dev/null
{
  "name": "$FOLDER_NAME",
  "phase": "$PHASE",
  "files": $TOTAL_FILES,
  "explorations": $EXPLORATIONS,
  "decisions": $DECISIONS,
  "critiques": $CRITIQUES,
  "enhancements": $ENHANCEMENTS,
  "open_questions": $OPEN_Q,
  "resolved_questions": $RESOLVED_Q
}
ENDJSON
