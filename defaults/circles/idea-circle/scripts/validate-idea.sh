#!/bin/bash
set -euo pipefail
# Skill: validate-idea
# Comprehensive validation of idea documentation (completeness, links, structure)
# Usage: validate-idea.sh <idea-name>
# Example: validate-idea.sh "smart-home-hub"
# Useful before exporting or advancing to ready-to-build phase

show_help() {
  echo "Usage: $(basename "$0") <idea-name>"
  echo ""
  echo "Runs comprehensive validation checks on idea documentation:"
  echo "  • Structure completeness (all required files exist)"
  echo "  • Content completeness (templates filled in)"
  echo "  • Link integrity (all cross-references valid)"
  echo "  • Index consistency (all items registered in their index)"
  echo "  • Phase appropriateness (enough content for current phase)"
  echo ""
  echo "Run before: export-context, zip-idea, or evolve-phase to ready-to-build"
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

echo "🔎 Validating: $IDEA_DIR/"
echo ""

WARNINGS=0
ERRORS=0

warn() { echo "  ⚠️  WARNING: $1"; WARNINGS=$((WARNINGS + 1)); }
error() { echo "  ❌ ERROR: $1"; ERRORS=$((ERRORS + 1)); }
pass() { echo "  ✅ $1"; }

# === 1. Structure Check ===
echo "━━━ Structure Check ━━━"

REQUIRED_FILES=(
  "README.md"
  "CONTEXT.md"
  "concept/core.md"
  "concept/vision.md"
  "concept/scope.md"
  "explorations/index.md"
  "decisions/index.md"
  "critiques/index.md"
  "enhancements/index.md"
  "questions/open.md"
  "questions/resolved.md"
  "roadmap.md"
  "glossary.md"
  "changelog.md"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$IDEA_DIR/$f" ]; then
    error "Missing required file: $f"
  fi
done

MISSING_COUNT=$ERRORS
if [ $MISSING_COUNT -eq 0 ]; then
  pass "All required files present (${#REQUIRED_FILES[@]} files)"
fi

# === 2. Content Completeness ===
echo ""
echo "━━━ Content Completeness ━━━"

check_not_template() {
  local file="$1"
  local label="$2"
  if [ ! -f "$file" ]; then return; fi
  
  # Count template markers using grep -E (extended regex, single pattern)
  local marker_count
  marker_count=$(grep -cE '^\*To be|\*Description|\*None yet|\*Item 1\*|\*Goal 1\*|\*Pro 1\*' "$file" 2>/dev/null) || marker_count=0
  
  if [ "$marker_count" -gt 3 ]; then
    warn "$label is mostly unfilled template ($marker_count template markers)"
  elif [ "$marker_count" -gt 0 ]; then
    pass "$label (partially filled, $marker_count items remaining)"
  else
    pass "$label (complete)"
  fi
}

check_not_template "$IDEA_DIR/concept/core.md" "Core Concept"
check_not_template "$IDEA_DIR/concept/vision.md" "Vision"
check_not_template "$IDEA_DIR/concept/scope.md" "Scope"
check_not_template "$IDEA_DIR/CONTEXT.md" "Context (handoff)"
check_not_template "$IDEA_DIR/roadmap.md" "Roadmap"

# === 3. Index Consistency ===
echo ""
echo "━━━ Index Consistency ━━━"

check_index_consistency() {
  local dir="$1"
  local pattern="$2"
  local index_file="$3"
  local label="$4"
  
  if [ ! -d "$dir" ] || [ ! -f "$index_file" ]; then return; fi
  
  local file_count
  file_count=$(find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' ')
  
  if [ "$file_count" -gt 0 ]; then
    local missing_refs=0
    for f in "$dir"/$pattern; do
      [ -f "$f" ] || continue
      local basename_f
      basename_f=$(basename "$f")
      if ! grep -q "$basename_f" "$index_file" 2>/dev/null; then
        missing_refs=$((missing_refs + 1))
        warn "$label: $basename_f not in index"
      fi
    done
    if [ $missing_refs -eq 0 ]; then
      pass "$label: all $file_count items indexed"
    fi
  else
    pass "$label: no items yet (ok)"
  fi
}

check_index_consistency "$IDEA_DIR/explorations" "approach-*.md" "$IDEA_DIR/explorations/index.md" "Explorations"
check_index_consistency "$IDEA_DIR/decisions" "decision-*.md" "$IDEA_DIR/decisions/index.md" "Decisions"
check_index_consistency "$IDEA_DIR/critiques" "critique-*.md" "$IDEA_DIR/critiques/index.md" "Critiques"
check_index_consistency "$IDEA_DIR/enhancements" "enhancement-*.md" "$IDEA_DIR/enhancements/index.md" "Enhancements"

# === 4. Link Check ===
echo ""
echo "━━━ Link Integrity ━━━"

BROKEN_LINKS=0
TOTAL_LINKS=0
while IFS= read -r file; do
  FILE_DIR=$(dirname "$file")
  # Extract markdown links: [text](path) — use perl-compatible regex for safety
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    case "$link" in http://*|https://*|mailto:*|"#"*) continue ;; esac
    TOTAL_LINKS=$((TOTAL_LINKS + 1))
    link_path="${link%%#*}"
    TARGET="$FILE_DIR/$link_path"
    if [ ! -f "$TARGET" ] && [ ! -d "$TARGET" ]; then
      BROKEN_LINKS=$((BROKEN_LINKS + 1))
      error "Broken link in $(basename "$file"): $link"
    fi
  done < <(grep -Eo '\]\([^)]+\)' "$file" 2>/dev/null | sed 's/^\](//' | sed 's/^(//' | sed 's/)$//' || true)
done < <(find "$IDEA_DIR" -name "*.md" -type f 2>/dev/null)

if [ $BROKEN_LINKS -eq 0 ]; then
  pass "All $TOTAL_LINKS links valid"
fi

# === 5. Phase Appropriateness ===
echo ""
echo "━━━ Phase Appropriateness ━━━"

PHASE="discovery"
if [ -f "$IDEA_DIR/.meta.json" ]; then
  PHASE=$(grep '"phase"' "$IDEA_DIR/.meta.json" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/') || PHASE="discovery"
elif [ -f "$IDEA_DIR/CONTEXT.md" ]; then
  RAW_PHASE=$(grep "^## Status:" "$IDEA_DIR/CONTEXT.md" 2>/dev/null | head -1 | sed 's/^## Status: //') || RAW_PHASE="Discovery"
  PHASE=$(echo "$RAW_PHASE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
fi

EXPLORATIONS=$(find "$IDEA_DIR/explorations" -name "approach-*.md" 2>/dev/null | wc -l | tr -d ' ')
DECISIONS=$(find "$IDEA_DIR/decisions" -name "decision-*.md" 2>/dev/null | wc -l | tr -d ' ')

case "$PHASE" in
  exploration*)
    if [ "$EXPLORATIONS" -lt 2 ]; then
      warn "In Exploration phase but only $EXPLORATIONS approaches (recommend 3+)"
    else
      pass "Exploration phase: $EXPLORATIONS approaches documented"
    fi
    ;;
  refinement*)
    if [ "$EXPLORATIONS" -lt 2 ]; then
      warn "In Refinement but only $EXPLORATIONS explorations done"
    fi
    if [ "$DECISIONS" -lt 1 ]; then
      warn "In Refinement but no decisions recorded yet"
    else
      pass "Refinement phase: $DECISIONS decisions, $EXPLORATIONS explorations"
    fi
    ;;
  ready*|build*)
    if [ "$DECISIONS" -lt 1 ]; then
      error "Ready-to-Build but no decisions recorded!"
    fi
    if [ "$EXPLORATIONS" -lt 1 ]; then
      error "Ready-to-Build but no explorations documented!"
    fi
    # Check CONTEXT.md is filled
    local ctx_templates
    ctx_templates=$(grep -cE '^\*To be|\*Not yet|\*Pending' "$IDEA_DIR/CONTEXT.md" 2>/dev/null) || ctx_templates=0
    if [ "$ctx_templates" -gt 2 ]; then
      error "CONTEXT.md has $ctx_templates unfilled sections — not ready for handoff!"
    else
      pass "Ready-to-Build: CONTEXT.md appears complete"
    fi
    ;;
  *)
    pass "Discovery phase: still early (no content minimums)"
    ;;
esac

# === Summary ===
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  🔎 Validation Results"
echo "═══════════════════════════════════════════════════════"
echo "  ❌ Errors:   $ERRORS"
echo "  ⚠️  Warnings: $WARNINGS"
echo "═══════════════════════════════════════════════════════"

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "  🛑 Fix errors before exporting or advancing phase."
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo ""
  echo "  ⚠️  Warnings present but not blocking. Consider addressing them."
  exit 0
else
  echo ""
  echo "  🎉 All checks passed! Idea documentation looks great."
  exit 0
fi
