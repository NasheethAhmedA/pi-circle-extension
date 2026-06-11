# Coding Circle

Coding Circle is for full-lifecycle software development through coordinated specialists.

Use it for work such as:
- new features
- bug fixes
- refactors
- code review
- architecture changes
- performance work
- documentation tied to implementation

## Focus

Coding Circle coordinates the software delivery loop:
- understand the codebase
- plan the work
- design structure when needed
- implement and verify changes
- document what matters

## Agents used by this circle

| Agent | Role |
|-------|------|
| planner | breaks implementation work into steps |
| architect | handles structure, boundaries, and design |
| coder | implements, debugs, reviews, refactors, and verifies |
| documentor | maintains technical documentation |

## Typical workflows

| Goal | Usual path |
|------|------------|
| New feature | planner → architect (if needed) → coder |
| Bug fix | coder |
| Refactor | architect (if needed) → coder |
| Code review | coder |
| Performance work | coder → architect (if structural redesign is needed) |
| Architecture design | architect |
| Documentation | documentor |

## Scripts used by this circle

### Circle-owned workflow script

```bash
bash <resolved-circle-root>/scripts/project-scan.sh [args]
```

### Architect-owned reusable scripts

```bash
bash <resolved-agent-root>/architect/scripts/file-map.sh [args]
bash <resolved-agent-root>/architect/scripts/find-entry-points.sh [args]
bash <resolved-agent-root>/architect/scripts/dependency-check.sh [args]
```

### Coder-owned reusable scripts

```bash
bash <resolved-agent-root>/coder/scripts/run-tests.sh [args]
bash <resolved-agent-root>/coder/scripts/run-build.sh [args]
bash <resolved-agent-root>/coder/scripts/run-dev.sh [args]
bash <resolved-agent-root>/coder/scripts/run-script.sh [args]
bash <resolved-agent-root>/coder/scripts/run-lint.sh [args]
bash <resolved-agent-root>/coder/scripts/run-typecheck.sh [args]
bash <resolved-agent-root>/coder/scripts/coverage-report.sh [args]
bash <resolved-agent-root>/coder/scripts/dead-code-scan.sh [args]
bash <resolved-agent-root>/coder/scripts/scaffold-module.sh [args]
bash <resolved-agent-root>/coder/scripts/scaffold-test.sh [args]
bash <resolved-agent-root>/coder/scripts/git-checkpoint.sh [args]
bash <resolved-agent-root>/coder/scripts/git-status.sh [args]
bash <resolved-agent-root>/coder/scripts/git-diff-summary.sh [args]
bash <resolved-agent-root>/coder/scripts/git-log-recent.sh [args]
bash <resolved-agent-root>/coder/scripts/git-branch-context.sh [args]
```
