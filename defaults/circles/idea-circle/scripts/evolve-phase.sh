#!/bin/bash
set -euo pipefail
# Skill: evolve-phase
# Updates the idea's phase/status across all tracking files
# Usage: evolve-phase.sh <idea-name> <phase>
# Phases: discovery, exploration, refinement, ready-to-build

show_help() {
  echo "Usage: $(basename "$0") <idea-name> <phase>"
  echo ""
  echo "Advances the idea to a new phase, updating all tracking files."
  echo ""
  echo "Phases (in order):"
  echo "  discovery       — Understanding the idea space"
  echo "  exploration     — Generating and evaluating approaches"
  echo "  refinement      — Narrowing down and detailing"
  echo "  ready-to-build  — Complete context for implementation"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") smart-home-hub exploration"
  echo "  $(basename "$0") smart-home-hub ready-to-build"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"
PHASE="${2:-}"

if [ -z "$IDEA_NAME" ] || [ -z "$PHASE" ]; then
  echo "Error: Please provide idea name and phase" >&2
  echo "Usage: $(basename "$0") <idea-name> <phase>" >&2
  echo "" >&2
  echo "Phases: discovery, exploration, refinement, ready-to-build" >&2
  exit 1
fi

FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
IDEA_DIR="${FOLDER_NAME}_idea"

if [ ! -d "$IDEA_DIR" ]; then
  echo "Error: $IDEA_DIR directory not found" >&2
  exit 1
fi

# Normalize phase name
PHASE_LOWER=$(echo "$PHASE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
case "$PHASE_LOWER" in
  discovery)
    PHASE_DISPLAY="Discovery"
    PHASE_EMOJI="🔍"
    PHASE_KEY="discovery"
    ;;
  exploration)
    PHASE_DISPLAY="Exploration"
    PHASE_EMOJI="🧭"
    PHASE_KEY="exploration"
    ;;
  refinement)
    PHASE_DISPLAY="Refinement"
    PHASE_EMOJI="🔧"
    PHASE_KEY="refinement"
    ;;
  ready-to-build|ready|build)
    PHASE_DISPLAY="Ready-to-Build"
    PHASE_EMOJI="🚀"
    PHASE_KEY="ready-to-build"
    ;;
  *)
    echo "Error: Unknown phase '$PHASE'" >&2
    echo "Valid: discovery, exploration, refinement, ready-to-build" >&2
    exit 1
    ;;
esac

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

# Update CONTEXT.md (portable sed with temp file)
if [ -f "$IDEA_DIR/CONTEXT.md" ]; then
  sed "s/^## Status:.*/## Status: $PHASE_DISPLAY/" "$IDEA_DIR/CONTEXT.md" > "$IDEA_DIR/CONTEXT.md.tmp"
  mv "$IDEA_DIR/CONTEXT.md.tmp" "$IDEA_DIR/CONTEXT.md"
  echo "✅ Updated CONTEXT.md → $PHASE_EMOJI $PHASE_DISPLAY"
fi

# Update README.md status badge
if [ -f "$IDEA_DIR/README.md" ]; then
  sed "s/> \*\*Status\*\*:.*/> **Status**: $PHASE_EMOJI $PHASE_DISPLAY/" "$IDEA_DIR/README.md" > "$IDEA_DIR/README.md.tmp"
  mv "$IDEA_DIR/README.md.tmp" "$IDEA_DIR/README.md"
  
  # Update checklist in README
  # Uncheck all, then check appropriate ones
  sed 's/- \[x\]/- [ ]/g' "$IDEA_DIR/README.md" > "$IDEA_DIR/README.md.tmp"
  mv "$IDEA_DIR/README.md.tmp" "$IDEA_DIR/README.md"
  
  case "$PHASE_KEY" in
    discovery)
      sed 's/- \[ \] Discovery/- [x] Discovery/' "$IDEA_DIR/README.md" > "$IDEA_DIR/README.md.tmp"
      ;;
    exploration)
      sed 's/- \[ \] Discovery/- [x] Discovery/;s/- \[ \] Exploration/- [x] Exploration/' "$IDEA_DIR/README.md" > "$IDEA_DIR/README.md.tmp"
      ;;
    refinement)
      sed 's/- \[ \] Discovery/- [x] Discovery/;s/- \[ \] Exploration/- [x] Exploration/;s/- \[ \] Refinement/- [x] Refinement/' "$IDEA_DIR/README.md" > "$IDEA_DIR/README.md.tmp"
      ;;
    ready-to-build)
      sed 's/- \[ \]/- [x]/g' "$IDEA_DIR/README.md" > "$IDEA_DIR/README.md.tmp"
      ;;
  esac
  mv "$IDEA_DIR/README.md.tmp" "$IDEA_DIR/README.md"
  echo "✅ Updated README.md → $PHASE_EMOJI $PHASE_DISPLAY"
fi

# Update .meta.json if exists
if [ -f "$IDEA_DIR/.meta.json" ]; then
  sed "s/\"phase\":.*$/\"phase\": \"$PHASE_KEY\",/" "$IDEA_DIR/.meta.json" > "$IDEA_DIR/.meta.json.tmp"
  sed "s/\"updated\":.*$/\"updated\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"/" "$IDEA_DIR/.meta.json.tmp" > "$IDEA_DIR/.meta.json"
  rm -f "$IDEA_DIR/.meta.json.tmp"
  echo "✅ Updated .meta.json"
fi

# Add changelog entry
CHANGELOG="$IDEA_DIR/changelog.md"
if [ -f "$CHANGELOG" ]; then
  TEMP=$(mktemp)
  {
    head -3 "$CHANGELOG"
    echo ""
    echo "## $NOW — Phase Advanced to $PHASE_DISPLAY"
    echo "- **Changed**: Project phase → $PHASE_EMOJI $PHASE_DISPLAY"
    echo "- **Trigger**: Phase advancement"
    echo ""
    tail -n +4 "$CHANGELOG"
  } > "$TEMP"
  mv "$TEMP" "$CHANGELOG"
  echo "✅ Added changelog entry"
fi

echo ""
echo "$PHASE_EMOJI Idea phase is now: $PHASE_DISPLAY"
echo ""

# Phase-specific guidance
case "$PHASE_KEY" in
  discovery)
    echo "📌 Focus: Ask probing questions, understand the idea space"
    ;;
  exploration)
    echo "📌 Focus: Generate 3-5 approaches, evaluate feasibility"
    ;;
  refinement)
    echo "📌 Focus: Deep-dive on top 1-2 approaches, make decisions"
    ;;
  ready-to-build)
    echo "📌 Focus: Finalize CONTEXT.md, validate completeness, export"
    echo "🎉 Ready to hand off! Run: export-context.sh $FOLDER_NAME"
    ;;
esac
