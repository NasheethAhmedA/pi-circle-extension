#!/bin/bash
set -euo pipefail
# Skill: add-glossary
# Adds a term to the idea's glossary
# Usage: add-glossary.sh <idea-name> <term> <definition>
# Example: add-glossary.sh "smart-home-hub" "MQTT" "Message Queuing Telemetry Transport"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <term> <definition>"
  echo ""
  echo "Adds a term and its definition to the idea's glossary.md."
  echo ""
  echo "Arguments:"
  echo "  idea-name    Name/slug of the idea"
  echo "  term         The term to define"
  echo "  definition   The definition"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") smart-home-hub \"MQTT\" \"Message Queuing Telemetry Transport protocol\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
TERM="${2:-}"
DEFINITION="${3:-}"

if [ -z "$IDEA_NAME" ] || [ -z "$TERM" ] || [ -z "$DEFINITION" ]; then
  echo "Error: Please provide idea name, term, and definition" >&2
  echo "Usage: $(basename "$0") <idea-name> <term> <definition>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"
GLOSSARY="$IDEA_DIR/glossary.md"

if [ ! -f "$GLOSSARY" ]; then
  echo "Error: $GLOSSARY not found. Run init-idea.sh first." >&2
  exit 1
fi

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

# Check if term already exists
if grep -qi "| *$TERM *|" "$GLOSSARY" 2>/dev/null; then
  echo "⚠️  Term '$TERM' already exists in glossary. Updating..." 
  # Remove old entry
  grep -vi "| *$TERM *|" "$GLOSSARY" > "${GLOSSARY}.tmp"
  mv "${GLOSSARY}.tmp" "$GLOSSARY"
fi

# Add new entry to the table (after header row)
TABLE_LINE="| $TERM | $DEFINITION |"
TEMP=$(mktemp)
awk -v row="$TABLE_LINE" '
  /^\| *Term/ { in_table=1 }
  in_table && /^$/ { print row; in_table=0 }
  { print }
' "$GLOSSARY" > "$TEMP"
mv "$TEMP" "$GLOSSARY"

# Update timestamp
sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$GLOSSARY" > "${GLOSSARY}.tmp" && mv "${GLOSSARY}.tmp" "$GLOSSARY"

echo "✅ Added to glossary:"
echo "   📖 $TERM: $DEFINITION"
echo ""
echo "📄 File: $GLOSSARY"
