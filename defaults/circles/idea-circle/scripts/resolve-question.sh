#!/bin/bash
set -euo pipefail
# Skill: resolve-question
# Moves a question from open to resolved
# Usage: resolve-question.sh <idea-name> <question-text> <answer>
# Example: resolve-question.sh "smart-home-hub" "How do we handle auth?" "Use OAuth2 with JWT"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <question-substring> <answer>"
  echo ""
  echo "Finds a matching open question, removes it from open.md,"
  echo "and adds it to resolved.md with the answer."
  echo ""
  echo "Arguments:"
  echo "  idea-name            Name/slug of the idea"
  echo "  question-substring   Part of the question text to match"
  echo "  answer               The resolution/answer"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") smart-home-hub \"auth\" \"Using OAuth2 with JWT tokens\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
QUESTION_MATCH="${2:-}"
ANSWER="${3:-}"

if [ -z "$IDEA_NAME" ] || [ -z "$QUESTION_MATCH" ] || [ -z "$ANSWER" ]; then
  echo "Error: Please provide idea name, question match, and answer" >&2
  echo "Usage: $(basename "$0") <idea-name> <question-substring> <answer>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"
OPEN_FILE="$IDEA_DIR/questions/open.md"
RESOLVED_FILE="$IDEA_DIR/questions/resolved.md"

if [ ! -f "$OPEN_FILE" ] || [ ! -f "$RESOLVED_FILE" ]; then
  echo "Error: Question files not found. Run init-idea.sh first." >&2
  exit 1
fi

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
TODAY=$(date -u +"%Y-%m-%d")

# Find the matching question
MATCHED_LINE=$(grep -i "$QUESTION_MATCH" "$OPEN_FILE" 2>/dev/null | grep "^- " | head -1 || true)

if [ -z "$MATCHED_LINE" ]; then
  echo "Error: No open question matching '$QUESTION_MATCH' found" >&2
  echo "" >&2
  echo "Open questions:" >&2
  grep "^- " "$OPEN_FILE" 2>/dev/null | head -10 >&2
  exit 1
fi

# Extract the full question text (strip the "- " prefix)
FULL_QUESTION="${MATCHED_LINE#- }"

echo "Found matching question:"
echo "   ❓ $FULL_QUESTION"
echo ""

# Remove from open.md (escape special chars for grep -v)
ESCAPED=$(echo "$MATCHED_LINE" | sed 's/[[\.*^$()+?{|]/\\&/g')
grep -v "^${ESCAPED}$" "$OPEN_FILE" > "${OPEN_FILE}.tmp" 2>/dev/null || cp "$OPEN_FILE" "${OPEN_FILE}.tmp"
mv "${OPEN_FILE}.tmp" "$OPEN_FILE"

# Add to resolved.md (append row to table)
# Find the end of the table header and add there
TEMP=$(mktemp)
awk -v q="$FULL_QUESTION" -v a="$ANSWER" -v d="$TODAY" -v ctx="Resolved during idea refinement" '
  /^\| *Question/ { in_table=1 }
  in_table && /^$/ { printf "| %s | %s | %s | %s |\n", q, a, d, ctx; in_table=0 }
  { print }
' "$RESOLVED_FILE" > "$TEMP"
mv "$TEMP" "$RESOLVED_FILE"

# Update timestamps
sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$OPEN_FILE" > "${OPEN_FILE}.tmp" && mv "${OPEN_FILE}.tmp" "$OPEN_FILE"
sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$RESOLVED_FILE" > "${RESOLVED_FILE}.tmp" && mv "${RESOLVED_FILE}.tmp" "$RESOLVED_FILE"

echo "✅ Question resolved!"
echo "   ❓ $FULL_QUESTION"
echo "   💡 $ANSWER"
echo ""
echo "📄 Removed from: $OPEN_FILE"
echo "📄 Added to: $RESOLVED_FILE"
