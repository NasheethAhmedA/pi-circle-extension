#!/bin/bash
set -euo pipefail
# Skill: diff-idea
# Shows what changed in idea docs — recent modifications and changelog entries
# Usage: diff-idea.sh <idea-name> [--since YYYY-MM-DD | N]
# Example: diff-idea.sh smart-home-hub --since 2026-05-01
# Example: diff-idea.sh smart-home-hub 7

show_help() {
  echo "Usage: $(basename "$0") <idea-name> [--since YYYY-MM-DD | days-ago]"
  echo ""
  echo "Shows recently modified files and changelog entries."
  echo "Useful when returning to a session to see what's new."
  echo ""
  echo "Arguments:"
  echo "  idea-name            Name/slug of the idea"
  echo "  --since YYYY-MM-DD   Show changes since a specific date"
  echo "  days-ago             Number of days to look back (default: all)"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") smart-home-hub"
  echo "  $(basename "$0") smart-home-hub --since 2026-05-01"
  echo "  $(basename "$0") smart-home-hub 7"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"

if [ -z "$IDEA_NAME" ]; then
  echo "Error: Please provide an idea name" >&2
  echo "Usage: $(basename "$0") <idea-name> [--since YYYY-MM-DD | days-ago]" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

# Parse time arguments
SINCE_DATE=""
DAYS_AGO=""
shift 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --since|-s)
      SINCE_DATE="${2:-}"
      shift 2
      ;;
    *)
      if echo "$1" | grep -qE '^[0-9]+$'; then
        DAYS_AGO="$1"
      fi
      shift
      ;;
  esac
done

echo "═══════════════════════════════════════════"
echo "  📊 CHANGES: ${FOLDER_NAME//-/ }"
echo "═══════════════════════════════════════════"
echo ""

# Show files sorted by modification time (most recent first)
echo "📝 Recently Modified Files:"
echo ""

FIND_ARGS=("$IDEA_DIR" -name "*.md" -type f)

if [ -n "$SINCE_DATE" ]; then
  echo "  (since $SINCE_DATE)"
  echo ""
  # Create temp reference file for -newer (portable)
  TEMP_REF=$(mktemp)
  if ! touch -d "$SINCE_DATE" "$TEMP_REF" 2>/dev/null; then
    # macOS fallback
    if ! touch -t "$(echo "$SINCE_DATE" | tr -d '-')0000" "$TEMP_REF" 2>/dev/null; then
      echo "Error: Cannot parse date '$SINCE_DATE'. Use YYYY-MM-DD." >&2
      rm -f "$TEMP_REF"
      exit 1
    fi
  fi
  FIND_ARGS+=(-newer "$TEMP_REF")
  MODIFIED=$(find "${FIND_ARGS[@]}" 2>/dev/null | sort)
  rm -f "$TEMP_REF"
elif [ -n "$DAYS_AGO" ]; then
  echo "  (last $DAYS_AGO day(s))"
  echo ""
  FIND_ARGS+=(-mtime "-$DAYS_AGO")
  MODIFIED=$(find "${FIND_ARGS[@]}" 2>/dev/null | sort)
else
  MODIFIED=$(find "${FIND_ARGS[@]}" 2>/dev/null | sort)
fi

if [ -z "$MODIFIED" ]; then
  echo "  No modified files found."
else
  echo "$MODIFIED" | while IFS= read -r file; do
    [ -f "$file" ] || continue
    SIZE=$(wc -l < "$file" | tr -d ' ')
    # Portable modification time
    MOD_TIME=$(stat -c '%y' "$file" 2>/dev/null | cut -d'.' -f1 || \
               stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$file" 2>/dev/null || \
               echo "?")
    REL_PATH="${file#"$IDEA_DIR"/}"
    echo "  📄 $REL_PATH ($SIZE lines, modified: $MOD_TIME)"
  done

  TOTAL=$(echo "$MODIFIED" | wc -l | tr -d ' ')
  echo ""
  echo "  Total: $TOTAL files"
fi

echo ""

# Show recent changelog entries
if [ -f "$IDEA_DIR/changelog.md" ]; then
  echo "📋 Recent Changelog Entries:"
  echo ""
  awk '/^## /{count++} count<=5{print "  " $0}' "$IDEA_DIR/changelog.md"
fi

echo ""
echo "═══════════════════════════════════════════"
