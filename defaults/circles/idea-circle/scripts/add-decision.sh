#!/bin/bash
set -euo pipefail
# Skill: add-decision
# Records a decision in ADR (Architecture Decision Record) format
# Usage: add-decision.sh <idea-name> <decision-title>
# Example: add-decision.sh "smart-home-hub" "Use MQTT for device communication"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <decision-title>"
  echo ""
  echo "Creates a new decision record in decisions/decision-NNN.md (ADR format)"
  echo "and automatically updates decisions/index.md."
  echo ""
  echo "Arguments:"
  echo "  idea-name        Name/slug of the idea"
  echo "  decision-title   Title of the decision being recorded"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
shift 2>/dev/null || true
DECISION_TITLE="$*"

if [ -z "$IDEA_NAME" ] || [ -z "$DECISION_TITLE" ]; then
  echo "Error: Please provide idea name and decision title" >&2
  echo "Usage: $(basename "$0") <idea-name> <decision-title>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR/decisions" ]; then
  echo "Error: $IDEA_DIR/decisions not found. Run init-idea.sh first." >&2
  exit 1
fi

# Determine next number (portable)
LAST_NUM=0
for f in "$IDEA_DIR/decisions"/decision-*.md; do
  [ -f "$f" ] || continue
  num=$(basename "$f" | sed 's/decision-\([0-9]*\)\.md/\1/')
  num=$((10#$num))
  [ "$num" -gt "$LAST_NUM" ] && LAST_NUM=$num
done
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))

FILENAME="decision-${NEXT_NUM}.md"
FILEPATH="$IDEA_DIR/decisions/$FILENAME"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
TODAY=$(date -u +"%Y-%m-%d")

cat > "$FILEPATH" << EOF
# Decision $NEXT_NUM: $DECISION_TITLE

[← Back to Decisions](./index.md) | [← README](../README.md)

## Date
$TODAY

## Status
✅ Decided

## Context
*What prompted this decision? What situation or constraint led here?*

## Options Considered
1. **Option A**: *Description*
2. **Option B**: *Description*
3. **Option C**: *Description*

## Decision
*What was decided and why. Be specific.*

## Rationale
*Why this option over the others? What criteria were decisive?*

## Consequences
### Positive
- *Consequence 1*

### Negative / Trade-offs
- *Trade-off 1*

### Risks
- *Risk 1*

## Related
- [→ Explorations](../explorations/)
- [→ Critiques](../critiques/)

---
*Recorded: $NOW*
EOF

# Auto-update index.md
INDEX="$IDEA_DIR/decisions/index.md"
if [ -f "$INDEX" ]; then
  TABLE_LINE="| $NEXT_NUM | $TODAY | [$DECISION_TITLE](./$FILENAME) | ✅ Decided |"
  
  if grep -q "^| #\|| *#" "$INDEX" 2>/dev/null; then
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
  
  sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$INDEX" > "${INDEX}.tmp" && mv "${INDEX}.tmp" "$INDEX"
fi

# Add changelog entry
CHANGELOG="$IDEA_DIR/changelog.md"
if [ -f "$CHANGELOG" ]; then
  TEMP=$(mktemp)
  {
    head -3 "$CHANGELOG"
    echo ""
    echo "## $NOW — Decision Recorded"
    echo "- **Added**: Decision $NEXT_NUM: $DECISION_TITLE"
    echo "- **File**: decisions/$FILENAME"
    echo ""
    tail -n +4 "$CHANGELOG"
  } > "$TEMP"
  mv "$TEMP" "$CHANGELOG"
fi

echo "✅ Created: $FILEPATH"
echo "📝 Decision $NEXT_NUM: $DECISION_TITLE"
echo "📋 Index updated: $INDEX"
echo "📜 Changelog updated"
echo ""
echo "Next: Fill in context, options, rationale, and consequences"
