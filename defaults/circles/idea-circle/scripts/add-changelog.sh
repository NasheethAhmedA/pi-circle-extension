#!/bin/bash
set -euo pipefail
# Skill: add-changelog
# Adds a manual changelog entry to the idea
# Usage: add-changelog.sh <idea-name> <title> <description>
# Example: add-changelog.sh "smart-home-hub" "Scope Updated" "Added IoT gateway to scope"

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <title> <description>"
  echo ""
  echo "Manually adds a timestamped changelog entry."
  echo "(Most other scripts auto-add changelog entries, but this is for custom ones.)"
  echo ""
  echo "Arguments:"
  echo "  idea-name     Name/slug of the idea"
  echo "  title         Short title for the change"
  echo "  description   Longer description of what changed"
  echo ""
  echo "Example:"
  echo "  $(basename "$0") smart-home-hub \"Scope Revised\" \"Removed mobile app from MVP\""
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
TITLE="${2:-}"
DESCRIPTION="${3:-}"

if [ -z "$IDEA_NAME" ] || [ -z "$TITLE" ]; then
  echo "Error: Please provide idea name and title" >&2
  echo "Usage: $(basename "$0") <idea-name> <title> [description]" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"
CHANGELOG="$IDEA_DIR/changelog.md"

if [ ! -f "$CHANGELOG" ]; then
  echo "Error: $CHANGELOG not found. Run init-idea.sh first." >&2
  exit 1
fi

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

TEMP=$(mktemp)
{
  head -3 "$CHANGELOG"
  echo ""
  echo "## $NOW — $TITLE"
  if [ -n "$DESCRIPTION" ]; then
    echo "- **Changed**: $DESCRIPTION"
  fi
  echo "- **Trigger**: Manual changelog entry"
  echo ""
  tail -n +4 "$CHANGELOG"
} > "$TEMP"
mv "$TEMP" "$CHANGELOG"

echo "✅ Changelog entry added:"
echo "   📝 $TITLE"
[ -n "$DESCRIPTION" ] && echo "   📋 $DESCRIPTION"
echo ""
echo "📄 File: $CHANGELOG"
