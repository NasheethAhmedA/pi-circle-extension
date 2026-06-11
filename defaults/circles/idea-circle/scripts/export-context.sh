#!/bin/bash
set -euo pipefail
# Skill: export-context
# Generates a single comprehensive .md file containing the entire idea context.
# Designed to be self-sufficient: a builder agent can implement from this alone.
# Usage: export-context.sh <idea-name> [output-path]

show_help() {
  echo "Usage: $(basename "$0") <idea-name> [output-path]"
  echo ""
  echo "Generates a single comprehensive .md file containing the entire idea context."
  echo "Designed to be self-sufficient: a builder agent can implement from this alone."
  echo ""
  echo "Arguments:"
  echo "  idea-name     Name/slug of the idea"
  echo "  output-path   Optional: output file path (default: <name>_context_export.md)"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
OUTPUT_PATH="${2:-}"

if [ -z "$IDEA_NAME" ]; then
  echo "Error: Please provide an idea name" >&2
  echo "Usage: $(basename "$0") <idea-name> [output-path]" >&2
  exit 1
fi

# Sanitize name
FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

if [ -z "$FOLDER_NAME" ]; then
  echo "Error: Idea name '$IDEA_NAME' produces an empty folder name after sanitization." >&2
  exit 1
fi

IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

if [ -z "$OUTPUT_PATH" ]; then
  OUTPUT_PATH="${FOLDER_NAME}_context_export.md"
fi

echo "📤 Exporting context for: $IDEA_NAME"

# Helper: include a file's content, stripping nav links
include_file() {
  local file="$1"
  local strip_nav="${2:-true}"
  if [ -f "$file" ]; then
    if [ "$strip_nav" = "true" ]; then
      grep -v '^\[← ' "$file" 2>/dev/null || cat "$file"
    else
      cat "$file"
    fi
  fi
}

# Helper: include all .md files in a directory (sorted)
include_dir() {
  local dir="$1"
  local label="$2"
  if [ -d "$dir" ]; then
    local files
    files=$(find "$dir" -maxdepth 1 -name "*.md" -type f ! -name "index.md" 2>/dev/null | sort)
    if [ -n "$files" ]; then
      echo "# $label"
      echo ""
      while IFS= read -r f; do
        [ -f "$f" ] || continue
        include_file "$f" true
        echo ""
        echo "---"
        echo ""
      done <<< "$files"
    fi
  fi
}

# Build the export
{
  echo "# $IDEA_NAME — Full Context Export"
  echo ""
  echo "> **Exported**: $(date -u +"%Y-%m-%d %H:%M UTC")"
  echo "> **Source**: \`$IDEA_DIR/\`"
  echo "> **Purpose**: Self-contained context for a builder agent to implement this idea."
  echo ""
  echo "---"
  echo ""

  # CONTEXT.md first (most important)
  if [ -f "$IDEA_DIR/CONTEXT.md" ]; then
    echo "# Agent Handoff Context"
    echo ""
    include_file "$IDEA_DIR/CONTEXT.md" false
    echo ""
    echo "---"
    echo ""
  fi

  # Core concept files
  echo "# Detailed Concept"
  echo ""
  for f in "$IDEA_DIR/concept/"*.md; do
    [ -f "$f" ] || continue
    include_file "$f" true
    echo ""
  done
  echo ""
  echo "---"
  echo ""

  # All explorations
  include_dir "$IDEA_DIR/explorations" "Explorations & Approaches"

  # All decisions
  include_dir "$IDEA_DIR/decisions" "Decisions"

  # All critiques
  include_dir "$IDEA_DIR/critiques" "Critiques"

  # All enhancements
  include_dir "$IDEA_DIR/enhancements" "Enhancements"

  # Questions
  if [ -d "$IDEA_DIR/questions" ]; then
    echo "# Questions"
    echo ""
    for f in "$IDEA_DIR/questions/"*.md; do
      [ -f "$f" ] || continue
      include_file "$f" true
      echo ""
    done
    echo "---"
    echo ""
  fi

  # Roadmap
  if [ -f "$IDEA_DIR/roadmap.md" ]; then
    include_file "$IDEA_DIR/roadmap.md" true
    echo ""
    echo "---"
    echo ""
  fi

  # Glossary
  if [ -f "$IDEA_DIR/glossary.md" ]; then
    include_file "$IDEA_DIR/glossary.md" true
    echo ""
    echo "---"
    echo ""
  fi

  # Changelog (last 10 entries for context)
  if [ -f "$IDEA_DIR/changelog.md" ]; then
    echo "# Recent Changes (Last 10)"
    echo ""
    head -60 "$IDEA_DIR/changelog.md"
    echo ""
  fi

  echo "---"
  echo "*End of context export. This document is self-contained for implementation.*"

} > "$OUTPUT_PATH"

echo ""
echo "✅ Exported to: $OUTPUT_PATH"
echo "📦 Size: $(du -h "$OUTPUT_PATH" | cut -f1)"
WORD_COUNT=$(wc -w < "$OUTPUT_PATH")
echo "📝 Words: $WORD_COUNT (~$((WORD_COUNT * 4 / 3)) tokens estimated)"
echo ""
echo "Give this file to any builder agent as context to implement the idea."
