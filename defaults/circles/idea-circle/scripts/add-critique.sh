#!/bin/bash
set -euo pipefail
# Skill: add-critique
# Adds a new structured critique document and updates the index + changelog
# Usage: add-critique.sh <idea-name> <critique-title>
# Example: add-critique.sh "smart-home-hub" "Scalability Concerns"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <critique-title>"
  echo ""
  echo "Creates a new critique document in critiques/critique-NNN.md"
  echo "and automatically updates critiques/index.md + changelog.md."
  echo ""
  echo "Arguments:"
  echo "  idea-name        Name/slug of the idea"
  echo "  critique-title   Title of the critique"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") smart-home-hub \"Scalability Concerns\""
  echo "  $(basename "$0") \"my app\" \"Missing Auth Strategy\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
shift 2>/dev/null || true
CRITIQUE_TITLE="${*:-}"

if [ -z "$IDEA_NAME" ] || [ -z "$CRITIQUE_TITLE" ]; then
  echo "Error: Please provide idea name and critique title" >&2
  echo "Usage: $(basename "$0") <idea-name> <critique-title>" >&2
  exit 1
fi

# Sanitize name (portable — no grep -oP)
FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

if [ -z "$FOLDER_NAME" ]; then
  echo "Error: Idea name '$IDEA_NAME' produces an empty folder name after sanitization." >&2
  exit 1
fi

IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR/critiques" ]; then
  echo "Error: $IDEA_DIR/critiques not found. Run init-idea.sh first." >&2
  exit 1
fi

# Determine next number (portable — no grep -oP)
LAST_NUM=0
for f in "$IDEA_DIR/critiques"/critique-*.md; do
  [ -f "$f" ] || continue
  num=$(basename "$f" | sed 's/critique-\([0-9]*\)\.md/\1/')
  num=$((10#$num))
  [ "$num" -gt "$LAST_NUM" ] && LAST_NUM=$num
done
NEXT_NUM=$(printf "%03d" $((LAST_NUM + 1)))

FILENAME="critique-${NEXT_NUM}.md"
FILEPATH="$IDEA_DIR/critiques/$FILENAME"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
TODAY=$(date -u +"%Y-%m-%d")

cat > "$FILEPATH" << EOF
# Critique $NEXT_NUM: $CRITIQUE_TITLE

[← Back to Critiques](./index.md) | [← README](../README.md)

## Date
$TODAY

## Severity
*Rate: 🔴 Critical / 🟡 Important / 🟢 Nice-to-have*

## Observation
*What was found — be specific, cite related documents.*

## Impact
*What happens if this isn't addressed?*

## Suggestion
*Concrete improvement — not just "fix it".*

## Affected Areas
- *Which aspects of the idea are affected?*

## Risk Assessment
- **Probability**: High / Medium / Low
- **Impact**: High / Medium / Low
- **Mitigation**: *Proposed mitigation strategy*

## Status
Open

## Related
- [→ Explorations](../explorations/)
- [→ Decisions](../decisions/)
- [→ Questions](../questions/open.md)

---
*Created: $NOW*
EOF

# Auto-update index.md — insert row at end of table
INDEX="$IDEA_DIR/critiques/index.md"
if [ -f "$INDEX" ]; then
  TABLE_LINE="| $NEXT_NUM | [$CRITIQUE_TITLE](./$FILENAME) | ⏳ Open | *To be filled* |"

  # Insert after the last table row (line starting with |) or after header separator
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

  sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$INDEX" > "${INDEX}.tmp" && mv "${INDEX}.tmp" "$INDEX"
fi

# Add changelog entry
CHANGELOG="$IDEA_DIR/changelog.md"
if [ -f "$CHANGELOG" ]; then
  TEMP=$(mktemp)
  {
    head -3 "$CHANGELOG"
    echo ""
    echo "## $NOW — Critique Filed"
    echo "- **Added**: Critique $NEXT_NUM: $CRITIQUE_TITLE"
    echo "- **File**: critiques/$FILENAME"
    echo ""
    tail -n +4 "$CHANGELOG"
  } > "$TEMP"
  mv "$TEMP" "$CHANGELOG"
fi

echo "✅ Created: $FILEPATH"
echo "📝 Critique $NEXT_NUM: $CRITIQUE_TITLE"
echo "📋 Index updated: $INDEX"
echo "📜 Changelog updated"
echo ""
echo "Next: Fill in severity, observation, impact, and suggestion"
