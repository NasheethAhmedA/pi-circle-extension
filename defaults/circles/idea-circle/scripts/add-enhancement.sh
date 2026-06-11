#!/bin/bash
set -euo pipefail
# Skill: add-enhancement
# Adds a proposed enhancement/improvement to the idea
# Usage: add-enhancement.sh <idea-name> <priority> <enhancement-title>
# Example: add-enhancement.sh "smart-home-hub" high "Add offline mode support"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <priority> <enhancement-title>"
  echo ""
  echo "Creates an enhancement proposal in enhancements/enhancement-NNN.md"
  echo "and updates enhancements/index.md + changelog.md."
  echo ""
  echo "Arguments:"
  echo "  idea-name           Name/slug of the idea"
  echo "  priority            Priority level: high, medium, low, nice-to-have"
  echo "  enhancement-title   Title of the proposed enhancement"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") smart-home-hub high \"Add offline mode support\""
  echo "  $(basename "$0") smart-home-hub medium \"Dark theme for dashboard\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
PRIORITY="${2:-}"
shift 2 2>/dev/null || true
ENHANCEMENT_TITLE="$*"

if [ -z "$IDEA_NAME" ] || [ -z "$PRIORITY" ] || [ -z "$ENHANCEMENT_TITLE" ]; then
  echo "Error: Please provide idea name, priority, and enhancement title" >&2
  echo "Usage: $(basename "$0") <idea-name> <priority> <enhancement-title>" >&2
  exit 1
fi

# Validate priority
PRIORITY_LOWER=$(echo "$PRIORITY" | tr '[:upper:]' '[:lower:]')
case "$PRIORITY_LOWER" in
  high|h)
    PRIORITY_DISPLAY="🔴 High"
    PRIORITY_KEY="high"
    ;;
  medium|med|m)
    PRIORITY_DISPLAY="🟡 Medium"
    PRIORITY_KEY="medium"
    ;;
  low|l)
    PRIORITY_DISPLAY="🟢 Low"
    PRIORITY_KEY="low"
    ;;
  nice-to-have|nice|n)
    PRIORITY_DISPLAY="⚪ Nice-to-Have"
    PRIORITY_KEY="nice-to-have"
    ;;
  *)
    echo "Error: Invalid priority '$PRIORITY'" >&2
    echo "Valid: high, medium, low, nice-to-have" >&2
    exit 1
    ;;
esac

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR/enhancements" ]; then
  echo "Error: $IDEA_DIR/enhancements not found. Run init-idea.sh first." >&2
  exit 1
fi

# Determine next number (portable)
LAST_NUM=0
for f in "$IDEA_DIR/enhancements"/enhancement-*.md; do
  [ -f "$f" ] || continue
  num=$(basename "$f" | sed 's/enhancement-\([0-9]*\)\.md/\1/')
  num=$((10#$num))
  [ "$num" -gt "$LAST_NUM" ] && LAST_NUM=$num
done
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))

FILENAME="enhancement-${NEXT_NUM}.md"
FILEPATH="$IDEA_DIR/enhancements/$FILENAME"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

cat > "$FILEPATH" << EOF
# Enhancement $NEXT_NUM: $ENHANCEMENT_TITLE

[← Back to Enhancements](./index.md) | [← README](../README.md)

## Priority
$PRIORITY_DISPLAY

## Status
📋 Proposed

## Description
*What improvement is being proposed?*

## Motivation
*Why is this enhancement valuable? What problem does it solve or what value does it add?*

## User Impact
*How does this affect the end user experience?*

## Implementation Notes
*High-level approach to implementing this enhancement.*

## Effort Estimate
- **Complexity**: *Low / Medium / High*
- **Dependencies**: *What needs to exist first?*
- **Phase**: *When should this be implemented? (MVP / Growth / Scale)*

## Acceptance Criteria
- [ ] *Criterion 1*
- [ ] *Criterion 2*

## Related
- [→ Explorations](../explorations/)
- [→ Decisions](../decisions/)

---
*Created: $NOW*
EOF

# Auto-update index.md
INDEX="$IDEA_DIR/enhancements/index.md"
if [ -f "$INDEX" ]; then
  TABLE_LINE="| $NEXT_NUM | [$ENHANCEMENT_TITLE](./$FILENAME) | $PRIORITY_DISPLAY | 📋 Proposed |"

  if grep -q "^| #\|| *#" "$INDEX" 2>/dev/null; then
    TEMP=$(mktemp)
    awk -v row="$TABLE_LINE" '
      /^\| *#/ { in_table=1 }
      in_table && /^$/ { print row; in_table=0 }
      { print }
    ' "$INDEX" > "$TEMP"
    mv "$TEMP" "$INDEX"
  fi

  sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$INDEX" > "${INDEX}.tmp" && mv "${INDEX}.tmp" "$INDEX"
fi

# Changelog
CHANGELOG="$IDEA_DIR/changelog.md"
if [ -f "$CHANGELOG" ]; then
  TEMP=$(mktemp)
  {
    head -3 "$CHANGELOG"
    echo ""
    echo "## $NOW — Enhancement Proposed"
    echo "- **Added**: Enhancement $NEXT_NUM: $ENHANCEMENT_TITLE ($PRIORITY_DISPLAY)"
    echo "- **File**: enhancements/$FILENAME"
    echo ""
    tail -n +4 "$CHANGELOG"
  } > "$TEMP"
  mv "$TEMP" "$CHANGELOG"
fi

echo "✅ Created: $FILEPATH"
echo "✨ Enhancement $NEXT_NUM: $ENHANCEMENT_TITLE"
echo "📊 Priority: $PRIORITY_DISPLAY"
echo "📋 Index updated: $INDEX"
echo "📜 Changelog updated"
echo ""
echo "Next: Fill in description, motivation, and acceptance criteria"
