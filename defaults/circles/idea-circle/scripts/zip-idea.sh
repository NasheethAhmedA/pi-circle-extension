#!/bin/bash
set -euo pipefail
# Skill: zip-idea
# Creates a zip archive of the idea documentation
# Usage: zip-idea.sh <idea-name> [output-dir]
# Example: zip-idea.sh "smart-home-hub" ~/exports/

show_help() {
  echo "Usage: $(basename "$0") <idea-name> [output-dir]"
  echo ""
  echo "Creates a .zip archive of the <name>_idea/ folder."
  echo ""
  echo "Arguments:"
  echo "  idea-name    Name/slug of the idea (as used in folder name)"
  echo "  output-dir   Optional: directory to place the zip (default: current dir)"
  echo ""
  echo "Output: <name>_idea.zip"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
OUTPUT_DIR="${2:-.}"

if [ -z "$IDEA_NAME" ]; then
  # Auto-detect if only one idea directory exists
  IDEA_DIRS=$(find . -maxdepth 1 -type d -name "*_idea" 2>/dev/null)
  COUNT=$(echo "$IDEA_DIRS" | grep -c "." 2>/dev/null || echo 0)
  
  if [ "$COUNT" -eq 1 ]; then
    IDEA_DIR=$(echo "$IDEA_DIRS" | sed 's|^./||')
    FOLDER_NAME="${IDEA_DIR%_idea}"
  elif [ "$COUNT" -gt 1 ]; then
    echo "Error: Multiple idea directories found. Please specify which one:" >&2
    echo "$IDEA_DIRS" | sed 's|^./||;s|_idea$||' | sed 's/^/  /' >&2
    exit 1
  else
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
  echo "Available idea directories:" >&2
  find . -maxdepth 1 -type d -name "*_idea" -exec basename {} \; 2>/dev/null | sed 's/^/  /' >&2
  exit 1
fi

# Validate output dir
if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: Output directory '$OUTPUT_DIR' does not exist" >&2
  exit 1
fi

ZIP_FILE="${OUTPUT_DIR%/}/${FOLDER_NAME}_idea.zip"

# Check zip is available
if ! command -v zip &>/dev/null; then
  # Fallback to tar.gz
  TAR_FILE="${OUTPUT_DIR%/}/${FOLDER_NAME}_idea.tar.gz"
  echo "⚠️  'zip' not found. Using tar.gz instead."
  tar -czf "$TAR_FILE" "$IDEA_DIR/"
  echo ""
  echo "✅ Created: $TAR_FILE"
  echo "📦 Size: $(du -h "$TAR_FILE" | cut -f1)"
  echo "📂 Contains: $(tar -tzf "$TAR_FILE" | wc -l) files"
  exit 0
fi

# Remove old zip if exists
rm -f "$ZIP_FILE"

# Create zip (exclude OS junk files)
zip -r "$ZIP_FILE" "$IDEA_DIR/" \
  -x "*.DS_Store" \
  -x "*__MACOSX*" \
  -x "*.swp" \
  -x "*~" \
  -x "*.tmp" \
  2>/dev/null

FILE_COUNT=$(unzip -l "$ZIP_FILE" 2>/dev/null | grep -c "^\s" || echo "?")

echo ""
echo "✅ Created: $ZIP_FILE"
echo "📦 Size: $(du -h "$ZIP_FILE" | cut -f1)"
echo "📂 Files: $FILE_COUNT"
echo ""
echo "This zip contains the complete idea documentation."
echo "Share it or provide it as context to any builder agent."
