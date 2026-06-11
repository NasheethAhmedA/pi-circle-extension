#!/bin/bash
set -euo pipefail
# Skill: link-check
# Verifies all markdown links in the idea documentation are valid
# Usage: link-check.sh <idea-name>
# Checks relative links (./ and ../) and reports broken ones

show_help() {
  echo "Usage: $(basename "$0") <idea-name>"
  echo ""
  echo "Scans all .md files in the idea folder and verifies that"
  echo "relative markdown links point to existing files/directories."
  echo ""
  echo "Checks:"
  echo "  - [text](./path) style links"
  echo "  - [text](../path) style links"  
  echo "  - Reports broken links with file and line number"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"

if [ -z "$IDEA_NAME" ]; then
  echo "Error: Please provide an idea name" >&2
  echo "Usage: $(basename "$0") <idea-name>" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

echo "🔗 Checking links in: $IDEA_DIR/"
echo ""

BROKEN=0
TOTAL=0
VALID=0

# Use grep to extract links properly: matches [anything](path) 
# where path doesn't start with http/https/mailto/#
# We use a per-file approach with grep -n to get line numbers

while IFS= read -r file; do
  FILE_DIR=$(dirname "$file")

  # Extract all link targets with line numbers
  # Pattern: ]( followed by non-) chars followed by )
  # grep -no gives us line:match
  while IFS=: read -r line_num match; do
    [ -z "$match" ] && continue
    
    # Extract the URL part from ](url)
    link=$(echo "$match" | sed 's/^](//' | sed 's/)$//')
    
    [ -z "$link" ] && continue
    
    # Skip external links, anchors-only, absolute paths
    case "$link" in
      http://*|https://*|mailto:*|/*) continue ;;
      \#*) continue ;;
    esac

    TOTAL=$((TOTAL + 1))

    # Strip anchor from link (e.g., ./file.md#section -> ./file.md)
    link_path="${link%%\#*}"

    # Skip if empty after stripping anchor
    [ -z "$link_path" ] && { VALID=$((VALID + 1)); continue; }

    # Resolve the target path
    TARGET="$FILE_DIR/$link_path"
    # Normalize (remove trailing /)
    TARGET="${TARGET%/}"

    if [ -f "$TARGET" ] || [ -d "$TARGET" ] || [ -d "${TARGET}/" ]; then
      VALID=$((VALID + 1))
    else
      echo "  ❌ BROKEN: $file:$line_num"
      echo "     Link: $link → $TARGET"
      echo ""
      BROKEN=$((BROKEN + 1))
    fi
  done < <(grep -no ']([^)]*)'  "$file" 2>/dev/null || true)

done < <(find "$IDEA_DIR" -name "*.md" -type f | sort)

echo "═══════════════════════════════════════"
echo "  🔗 Link Check Results"
echo "═══════════════════════════════════════"
echo "  Total links checked: $TOTAL"
echo "  ✅ Valid:  $VALID"
echo "  ❌ Broken: $BROKEN"
echo "═══════════════════════════════════════"

if [ $BROKEN -gt 0 ]; then
  echo ""
  echo "⚠️  Fix broken links before exporting!"
  exit 1
else
  echo ""
  echo "✅ All links are valid!"
fi
