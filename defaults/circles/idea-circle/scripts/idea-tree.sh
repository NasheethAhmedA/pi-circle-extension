#!/bin/bash
set -euo pipefail
# Skill: idea-tree
# Shows a visual tree of the idea documentation structure
# Usage: idea-tree.sh [idea-name]

show_help() {
  echo "Usage: $(basename "$0") [idea-name]"
  echo ""
  echo "Displays a visual tree of the idea documentation structure."
  echo "Uses 'tree' if available, otherwise a portable fallback."
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"

if [ -z "$IDEA_NAME" ]; then
  # Auto-detect
  IDEA_DIR=$(find . -maxdepth 1 -type d -name "*_idea" 2>/dev/null | head -1 | sed 's|^./||')
  if [ -z "$IDEA_DIR" ]; then
    echo "Error: No idea directories found" >&2
    echo "Usage: $(basename "$0") <idea-name>" >&2
    exit 1
  fi
else
  FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  IDEA_DIR="${FOLDER_NAME}_idea"
fi

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

echo "📂 $IDEA_DIR/"
echo ""

# Use tree if available
if command -v tree &>/dev/null; then
  tree "$IDEA_DIR" --charset=utf-8 -I ".DS_Store|*.swp|*~"
else
  # Portable fallback using find
  find "$IDEA_DIR" -not -name ".DS_Store" -not -name "*.swp" | sort | while IFS= read -r path; do
    # Skip the root dir itself
    [ "$path" = "$IDEA_DIR" ] && continue
    
    # Get relative path from IDEA_DIR
    rel="${path#$IDEA_DIR/}"
    
    # Count depth
    depth=$(echo "$rel" | tr -cd '/' | wc -c)
    
    # Build indent
    indent=""
    i=0
    while [ $i -lt "$depth" ]; do
      indent="${indent}│   "
      i=$((i + 1))
    done
    
    # Get basename
    name=$(basename "$path")
    
    if [ -d "$path" ]; then
      echo "${indent}├── 📁 ${name}/"
    else
      echo "${indent}├── 📄 ${name}"
    fi
  done
fi

echo ""
echo "Total files: $(find "$IDEA_DIR" -type f | wc -l)"
echo "Total dirs:  $(find "$IDEA_DIR" -type d | wc -l)"
