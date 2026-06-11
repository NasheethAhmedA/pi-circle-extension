#!/bin/bash
set -euo pipefail
# Skill: add-question
# Adds an open question to the questions tracking
# Usage: add-question.sh <idea-name> <priority> <question>
# Example: add-question.sh "smart-home-hub" high "How do we handle offline sync?"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <priority> <question>"
  echo ""
  echo "Adds a question to questions/open.md under the appropriate priority section."
  echo ""
  echo "Arguments:"
  echo "  idea-name   Name/slug of the idea"
  echo "  priority    Priority: high, medium, low"
  echo "  question    The question to add"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") smart-home-hub high \"How do we handle user auth?\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
PRIORITY="${2:-}"
shift 2 2>/dev/null || true
QUESTION="$*"

if [ -z "$IDEA_NAME" ] || [ -z "$PRIORITY" ] || [ -z "$QUESTION" ]; then
  echo "Error: Please provide idea name, priority, and question" >&2
  echo "Usage: $(basename "$0") <idea-name> <priority> <question>" >&2
  exit 1
fi

# Validate priority
PRIORITY_LOWER=$(echo "$PRIORITY" | tr '[:upper:]' '[:lower:]')
case "$PRIORITY_LOWER" in
  high|h) SECTION="### High Priority" ;;
  medium|med|m) SECTION="### Medium Priority" ;;
  low|l) SECTION="### Low Priority" ;;
  *)
    echo "Error: Invalid priority '$PRIORITY'. Use: high, medium, low" >&2
    exit 1
    ;;
esac

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"
OPEN_FILE="$IDEA_DIR/questions/open.md"

if [ ! -f "$OPEN_FILE" ]; then
  echo "Error: $OPEN_FILE not found. Run init-idea.sh first." >&2
  exit 1
fi

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

# Insert question after the appropriate section header
TEMP=$(mktemp)
awk -v section="$SECTION" -v question="- $QUESTION" '
  $0 == section { print; found=1; next }
  found && /^$/ { print question; found=0 }
  found && /^###/ { print question; print ""; found=0 }
  { print }
  END { if (found) print question }
' "$OPEN_FILE" > "$TEMP"
mv "$TEMP" "$OPEN_FILE"

# Update timestamp
sed "s/\*Last updated:.*\*/\*Last updated: $NOW\*/" "$OPEN_FILE" > "${OPEN_FILE}.tmp" && mv "${OPEN_FILE}.tmp" "$OPEN_FILE"

echo "✅ Added question ($PRIORITY_LOWER priority):"
echo "   ❓ $QUESTION"
echo ""
echo "📄 File: $OPEN_FILE"
