#!/bin/bash
set -euo pipefail
# Skill: init-idea
# Initializes the idea folder structure
# Usage: init-idea.sh <idea-name>
# Example: init-idea.sh "Smart Home Hub"

show_help() {
  echo "Usage: $(basename "$0") <idea-name>"
  echo ""
  echo "Initializes a structured <name>_idea/ folder for documenting an idea."
  echo ""
  echo "Arguments:"
  echo "  idea-name    The name of your idea (can contain spaces)"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") \"Smart Home Hub\""
  echo "  $(basename "$0") my-cool-app"
  exit 0
}

[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && show_help

IDEA_NAME="${1:-}"

if [ -z "$IDEA_NAME" ]; then
  echo "Error: Please provide an idea name" >&2
  echo "Usage: $(basename "$0") <idea-name>" >&2
  exit 1
fi

# Sanitize name (lowercase, hyphens, strip unsafe chars)
FOLDER_NAME=$(echo "$IDEA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

if [ -z "$FOLDER_NAME" ]; then
  echo "Error: Idea name '$IDEA_NAME' produces an empty folder name after sanitization." >&2
  echo "Please use a name with at least one alphanumeric character." >&2
  exit 1
fi

IDEA_DIR="${FOLDER_NAME}_idea"

if [ -d "$IDEA_DIR" ]; then
  echo "⚠️  Warning: $IDEA_DIR already exists. Skipping initialization."
  echo "   Use the existing structure or delete it first."
  exit 0
fi

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

echo "🚀 Initializing idea: $IDEA_NAME"
echo "📁 Creating structure: $IDEA_DIR/"

mkdir -p "$IDEA_DIR"/{concept,explorations,decisions,critiques,enhancements,questions}

# README.md — Main entry point
cat > "$IDEA_DIR/README.md" << EOF
# $IDEA_NAME

> **Status**: 🔍 Discovery

## Navigation

| Section | Description |
|---------|-------------|
| [CONTEXT.md](./CONTEXT.md) | Agent-handoff summary (start here for building) |
| [concept/](./concept/) | Core concept, vision, and scope |
| [explorations/](./explorations/) | Implementation approaches explored |
| [decisions/](./decisions/) | Decision records |
| [critiques/](./critiques/) | Constructive analyses |
| [enhancements/](./enhancements/) | Proposed improvements |
| [questions/](./questions/) | Open and resolved questions |
| [roadmap.md](./roadmap.md) | Phased implementation plan |
| [glossary.md](./glossary.md) | Key terms and definitions |
| [changelog.md](./changelog.md) | Evolution history |

## Quick Summary
*To be filled as the idea evolves.*

## Current Phase
- [x] Discovery — Understanding the idea space
- [ ] Exploration — Generating and evaluating approaches
- [ ] Refinement — Narrowing down and detailing
- [ ] Ready to Build — Complete context for implementation

---
*Last updated: $NOW*
EOF

# CONTEXT.md — Self-contained handoff document
cat > "$IDEA_DIR/CONTEXT.md" << EOF
# $IDEA_NAME — Complete Context

## Status: Discovery

## One-Line Summary
*To be defined.*

## Core Concept
*To be refined through exploration.*

## Key Decisions Made
*None yet.*

## Chosen Approach
*Not yet selected — exploring options.*

## Architecture Overview
*Pending implementation strategy.*

## Open Questions
- [ ] What is the core problem being solved?
- [ ] Who is the primary user/audience?
- [ ] What does success look like?

## Next Steps
1. Define core concept clearly
2. Explore implementation approaches
3. Evaluate and narrow down options

## Full Documentation
See: [README.md](./README.md)

---
*This file is designed to be self-contained. A builder agent can start working from this alone.*
*Last updated: $NOW*
EOF

# concept/core.md
cat > "$IDEA_DIR/concept/core.md" << EOF
# Core Concept

[← Back to README](../README.md) | [→ Vision](./vision.md) | [→ Scope](./scope.md)

## What is this?
*Description of the core idea.*

## Problem Statement
*What problem does this solve?*

## Target Audience
*Who benefits from this?*

## Core Value Proposition
*Why does this matter?*

---
*Last updated: $NOW*
EOF

# concept/vision.md
cat > "$IDEA_DIR/concept/vision.md" << EOF
# Vision & Goals

[← Back to README](../README.md) | [→ Core](./core.md) | [→ Scope](./scope.md)

## Long-term Vision
*Where is this heading?*

## Goals
- *Goal 1*
- *Goal 2*

## Success Metrics
*How do we know this is working?*

---
*Last updated: $NOW*
EOF

# concept/scope.md
cat > "$IDEA_DIR/concept/scope.md" << EOF
# Scope & Boundaries

[← Back to README](../README.md) | [→ Core](./core.md) | [→ Vision](./vision.md)

## In Scope
- *Item 1*

## Out of Scope (Non-Goals)
- *Item 1*

## Constraints
- *Constraint 1*

## Assumptions
- *Assumption 1*

---
*Last updated: $NOW*
EOF

# explorations/index.md
cat > "$IDEA_DIR/explorations/index.md" << EOF
# Explorations Index

[← Back to README](../README.md)

## Approaches Explored

| # | Approach | Status | Summary |
|---|----------|--------|---------|

## Comparison Matrix
*To be filled as approaches are evaluated.*

---
*Last updated: $NOW*
EOF

# decisions/index.md
cat > "$IDEA_DIR/decisions/index.md" << EOF
# Decision Log

[← Back to README](../README.md)

## Decisions Made

| # | Date | Decision | Status |
|---|------|----------|--------|

---
*Last updated: $NOW*
EOF

# critiques/index.md
cat > "$IDEA_DIR/critiques/index.md" << EOF
# Critiques Index

[← Back to README](../README.md)

## Critiques

| # | Target | Verdict | Summary |
|---|--------|---------|---------|

---
*Last updated: $NOW*
EOF

# enhancements/index.md
cat > "$IDEA_DIR/enhancements/index.md" << EOF
# Enhancements Backlog

[← Back to README](../README.md)

## Proposed Enhancements (Prioritized)

| # | Enhancement | Priority | Status |
|---|-------------|----------|--------|

---
*Last updated: $NOW*
EOF

# questions/open.md
cat > "$IDEA_DIR/questions/open.md" << EOF
# Open Questions

[← Back to README](../README.md) | [→ Resolved](./resolved.md)

## Active Questions

### High Priority
- What is the core problem being solved?
- Who is the primary user/audience?
- What does success look like?

### Medium Priority

### Low Priority

---
*Last updated: $NOW*
EOF

# questions/resolved.md
cat > "$IDEA_DIR/questions/resolved.md" << EOF
# Resolved Questions

[← Back to README](../README.md) | [→ Open](./open.md)

## Resolved

| Question | Answer | Date | Context |
|----------|--------|------|---------|

---
*Last updated: $NOW*
EOF

# roadmap.md
cat > "$IDEA_DIR/roadmap.md" << EOF
# Roadmap

[← Back to README](./README.md)

## Phases

### Phase 1: MVP
*To be defined after approach selection.*

### Phase 2: Growth
*To be defined.*

### Phase 3: Scale
*To be defined.*

---
*Last updated: $NOW*
EOF

# glossary.md
cat > "$IDEA_DIR/glossary.md" << EOF
# Glossary

[← Back to README](./README.md)

## Key Terms

| Term | Definition |
|------|-----------|

---
*Last updated: $NOW*
EOF

# changelog.md
cat > "$IDEA_DIR/changelog.md" << EOF
# Changelog

[← Back to README](./README.md)

## $NOW — Idea Initialized
- **Added**: Initial folder structure created
- **Added**: Template files for all sections
- **Phase**: 🔍 Discovery
- **Trigger**: User started a new idea: $IDEA_NAME

---
EOF

# .meta.json — Machine-readable metadata
cat > "$IDEA_DIR/.meta.json" << EOF
{
  "name": "$IDEA_NAME",
  "folder": "$IDEA_DIR",
  "sanitized_name": "$FOLDER_NAME",
  "phase": "discovery",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo ""
echo "✅ Idea structure created: $IDEA_DIR/"
echo ""
echo "📂 Structure:"
find "$IDEA_DIR" -type f | sort | sed 's/^/   /'
echo ""
echo "🎯 Next: Start defining the core concept in concept/core.md"
echo "📋 Run: idea-status.sh $FOLDER_NAME"
