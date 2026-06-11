#!/bin/bash
set -euo pipefail
# Skill: build-context
# Generates a comprehensive CONTEXT.md by aggregating key content from all idea docs
# Usage: build-context.sh <idea-name>
# Example: build-context.sh smart-home-hub

show_help() {
  echo "Usage: $(basename "$0") <idea-name>"
  echo ""
  echo "Regenerates CONTEXT.md by aggregating content from all idea documents."
  echo "This creates the definitive hand-off document for builder agents."
  echo ""
  echo "Example: $(basename "$0") smart-home-hub"
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

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
CONTEXT_FILE="$IDEA_DIR/CONTEXT.md"

# Read display name from .meta.json if available
DISPLAY_NAME="$IDEA_NAME"
if [ -f "$IDEA_DIR/.meta.json" ]; then
  META_NAME=$(grep '"name"' "$IDEA_DIR/.meta.json" | head -1 | sed 's/.*: *"\(.*\)".*/\1/' 2>/dev/null || echo "")
  [ -n "$META_NAME" ] && DISPLAY_NAME="$META_NAME"
fi

# Helper: extract meaningful content from a file (skip headers, nav links, empty templates)
# Rewrites relative links like (./foo.md) to (subdir/foo.md) so they work from CONTEXT.md
extract_content() {
  local file="$1"
  local max_lines="${2:-60}"
  if [ -f "$file" ]; then
    local file_dir
    file_dir=$(dirname "$file")
    local rel_prefix
    rel_prefix="${file_dir#"$IDEA_DIR"/}"
    local filtered
    filtered=$(grep -vE '^\[←|^---$|^\*Last updated|^$' "$file" | head -"$max_lines")
    # If file is in a subdirectory, rewrite (./ links to (subdir/ links
    if [ "$rel_prefix" != "$file_dir" ] && [ "$rel_prefix" != "." ] && [ -n "$rel_prefix" ]; then
      echo "$filtered" | sed "s|(\\./|(${rel_prefix}/|g"
    else
      echo "$filtered"
    fi
  fi
}

# Helper: check if file has real content (not just templates)
has_content() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return 1
  fi
  local total_lines
  total_lines=$(wc -l < "$file")
  local template_lines
  template_lines=$(grep -cE 'To be defined|To be filled|TBD|\*To be' "$file" 2>/dev/null) || template_lines=0
  local content_lines=$((total_lines - template_lines))
  [ "$content_lines" -gt 8 ]
}

{
  echo "# $DISPLAY_NAME — Complete Context"
  echo ""
  echo "> **Generated**: $NOW"
  echo "> **Purpose**: Self-contained context for any builder agent or developer."
  echo "> Give this file (or the entire \`$IDEA_DIR/\` directory) to start building."
  echo ""
  echo "---"
  echo ""
  
  # Phase/Status
  if [ -f "$IDEA_DIR/README.md" ]; then
    STATUS_LINE=$(grep "Status" "$IDEA_DIR/README.md" | head -1)
    [ -n "$STATUS_LINE" ] && echo "$STATUS_LINE" && echo ""
  fi
  
  # Core Concept
  echo "## 📌 Core Concept"
  echo ""
  if has_content "$IDEA_DIR/concept/core.md"; then
    extract_content "$IDEA_DIR/concept/core.md"
  else
    echo "*Core concept not yet defined. See [concept/core.md](concept/core.md).*"
  fi
  echo ""
  
  # Vision
  if has_content "$IDEA_DIR/concept/vision.md"; then
    echo "## 🎯 Vision & Goals"
    echo ""
    extract_content "$IDEA_DIR/concept/vision.md"
    echo ""
  fi
  
  # Scope
  if has_content "$IDEA_DIR/concept/scope.md"; then
    echo "## 📐 Scope & Constraints"
    echo ""
    extract_content "$IDEA_DIR/concept/scope.md"
    echo ""
  fi
  
  echo "---"
  echo ""
  
  # Explorations
  EXPLORATION_COUNT=$(find "$IDEA_DIR/explorations" -name "approach-*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$EXPLORATION_COUNT" -gt 0 ]; then
    echo "## 🧭 Implementation Approaches ($EXPLORATION_COUNT explored)"
    echo ""
    if has_content "$IDEA_DIR/explorations/index.md"; then
      extract_content "$IDEA_DIR/explorations/index.md" 40
    fi
    echo ""
    # Include summaries of each approach
    for f in "$IDEA_DIR/explorations/approach-"*.md; do
      if [ -f "$f" ]; then
        TITLE=$(head -1 "$f" | sed 's/^# //')
        echo "### $TITLE"
        extract_content "$f" 20
        echo ""
      fi
    done
    echo "---"
    echo ""
  fi
  
  # Decisions
  DECISION_COUNT=$(find "$IDEA_DIR/decisions" -name "decision-*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DECISION_COUNT" -gt 0 ]; then
    echo "## ✅ Key Decisions ($DECISION_COUNT made)"
    echo ""
    for f in "$IDEA_DIR/decisions/decision-"*.md; do
      if [ -f "$f" ]; then
        TITLE=$(head -1 "$f" | sed 's/^# //')
        echo "### $TITLE"
        extract_content "$f" 20
        echo ""
      fi
    done
    echo "---"
    echo ""
  fi
  
  # Roadmap
  if has_content "$IDEA_DIR/roadmap.md"; then
    echo "## 🗺️ Roadmap"
    echo ""
    extract_content "$IDEA_DIR/roadmap.md"
    echo ""
    echo "---"
    echo ""
  fi
  
  # Critiques / Risks
  CRITIQUE_COUNT=$(find "$IDEA_DIR/critiques" -name "critique-*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CRITIQUE_COUNT" -gt 0 ]; then
    echo "## ⚠️ Known Risks & Critiques ($CRITIQUE_COUNT filed)"
    echo ""
    if has_content "$IDEA_DIR/critiques/index.md"; then
      extract_content "$IDEA_DIR/critiques/index.md" 30
    fi
    echo ""
    echo "---"
    echo ""
  fi
  
  # Open Questions
  if has_content "$IDEA_DIR/questions/open.md"; then
    echo "## ❓ Open Questions"
    echo ""
    extract_content "$IDEA_DIR/questions/open.md" 30
    echo ""
    echo "---"
    echo ""
  fi
  
  # Glossary
  if has_content "$IDEA_DIR/glossary.md"; then
    echo "## 📖 Glossary"
    echo ""
    extract_content "$IDEA_DIR/glossary.md" 30
    echo ""
    echo "---"
    echo ""
  fi
  
  # File map for builder agent
  echo "## 📁 Full Documentation Map"
  echo ""
  echo "| Question | File |"
  echo "|----------|------|"
  echo "| What are we building? | [concept/core.md](concept/core.md) |"
  echo "| What's the vision? | [concept/vision.md](concept/vision.md) |"
  echo "| What's in/out of scope? | [concept/scope.md](concept/scope.md) |"
  echo "| What approaches were considered? | [explorations/](explorations/index.md) |"
  echo "| What was decided? | [decisions/](decisions/index.md) |"
  echo "| What are the risks? | [critiques/](critiques/index.md) |"
  echo "| What improvements are proposed? | [enhancements/](enhancements/index.md) |"
  echo "| What's the plan? | [roadmap.md](roadmap.md) |"
  echo "| What's unresolved? | [questions/open.md](questions/open.md) |"
  echo "| What changed? | [changelog.md](changelog.md) |"
  echo ""
  echo "---"
  echo "*Auto-generated by build-context.sh. For the most detailed info, refer to individual files.*"
  
} > "$CONTEXT_FILE"

echo "✅ Generated: $CONTEXT_FILE"
echo "📦 Size: $(du -h "$CONTEXT_FILE" | cut -f1)"
echo ""
echo "This file is now a self-contained context for any builder agent."
