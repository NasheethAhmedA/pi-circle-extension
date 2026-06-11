#!/bin/bash
set -euo pipefail
# Skill: add-exploration
# Adds a new approach/exploration document and updates the index
# Usage: add-exploration.sh <idea-name> <approach-title>
# Example: add-exploration.sh "smart-home-hub" "Event-Driven Architecture"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <approach-title>"
  echo ""
  echo "Creates a new exploration/approach document in explorations/approach-NNN.md"
  echo "and automatically updates explorations/index.md."
  echo ""
  echo "Arguments:"
  echo "  idea-name       Name/slug of the idea"
  echo "  approach-title  Title describing this approach"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") smart-home-hub \"Event-Driven Architecture\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
shift 2>/dev/null || true
APPROACH_TITLE="$*"

if [ -z "$IDEA_NAME" ] || [ -z "$APPROACH_TITLE" ]; then
  echo "Error: Please provide idea name and approach title" >&2
  echo "Usage: $(basename "$0") <idea-name> <approach-title>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR/explorations" ]; then
  echo "Error: $IDEA_DIR/explorations not found. Run init-idea.sh first." >&2
  exit 1
fi

# Determine next number (portable — no grep -oP)
LAST_NUM=0
for f in "$IDEA_DIR/explorations"/approach-*.md; do
  [ -f "$f" ] || continue
  # Extract number from filename: approach-001.md → 001
  num=$(basename "$f" | sed 's/approach-\([0-9]*\)\.md/\1/')
  num=$((10#$num))  # force base-10
  [ "$num" -gt "$LAST_NUM" ] && LAST_NUM=$num
done
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))

FILENAME="approach-${NEXT_NUM}.md"
FILEPATH="$IDEA_DIR/explorations/$FILENAME"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

cat > "$FILEPATH" << EOF
# Approach $NEXT_NUM: $APPROACH_TITLE

[← Back to Explorations](./index.md) | [← README](../README.md)

## Summary
*Brief description of this approach.*

## How It Works
*Detailed explanation of this implementation strategy.*

## Pros
- *Pro 1*

## Cons
- *Con 1*

## Technical Feasibility
- **Complexity**: *Low / Medium / High*
- **Time to MVP**: *Estimate*
- **Dependencies**: *List any external dependencies*
- **Risk Level**: *Low / Medium / High*

## Trade-offs
*Key trade-offs compared to other approaches.*

## Comparison Notes
*How this compares to other explored approaches.*

## Status: 🟡 Under Review

## Related
- [→ Critiques](../critiques/)
- [→ Decisions](../decisions/)

---
*Created: $NOW*
EOF

# Auto-update index.md — insert row before the empty line after table header
INDEX="$IDEA_DIR/explorations/index.md"
if [ -f "$INDEX" ]; then
  # Find the last line of the table (header + separator + existing rows)
  # and append our new row
  TABLE_LINE="| $NEXT_NUM | [$APPROACH_TITLE](./$FILENAME) | 🟡 Under Review | *To be filled* |"
  
  # Insert before the first empty line after the table header
  if grep -q "^| #" "$INDEX" 2>/dev/null; then
    # Append to the end of the table section (before the next blank line after |---|)
    # Use a temp file for portability (avoids sed -i differences)
    TEMP=$(mktemp)
    awk -v row="$TABLE_LINE" '
      /^\|/ { last_table_line = NR }
      { lines[NR] = $0; total = NR }
      END {
        for (i = 1; i <= total; i++) {
          print lines[i]
          if (i == last_table_line) print row
        }
        if (last_table_line == 0) print row
      }
    ' "$INDEX" > "$TEMP"
    mv "$TEMP" "$INDEX"
  fi
  
  # Update timestamp
  sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$INDEX" > "${INDEX}.tmp" && mv "${INDEX}.tmp" "$INDEX"
fi

echo "✅ Created: $FILEPATH"
echo "📝 Title: Approach $NEXT_NUM: $APPROACH_TITLE"
echo "📋 Index updated: $INDEX"
echo ""
echo "Next: Fill in the details (summary, pros/cons, feasibility)"
