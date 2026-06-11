# Coding Circle

Full-lifecycle software development through coordinated specialists — planning, architecture, coding, verification, and documentation.

## Architecture

- **Center** — The coordinator. Handles only trivial tasks directly, delegates everything else. Owns workflow orchestration.
- **Agents** — Generic specialists (4 total). No coding-circle-specific knowledge. Reusable in any circle.

## Agents

| Agent | Role | Modes |
|-------|------|-------|
| planner | Task Decomposition | Plan |
| architect | System Design | Design / Structure / Analysis |
| coder | Implementation and Verification | Implement / Refactor / Review / Debug / Write tests |
| documentor | Documentation | Maintain /SPEC folder |

## Center's Decision Logic

- **Trivial** (explicit command, single read) → Center handles directly
- **Everything else** → Delegates to the appropriate agent
- **After code changes** → Prefer verification (tests, typecheck, build)
- **Findings/issues** → Ask user before auto-fixing by default

## Workflows

| Trigger | Pipeline |
|---------|----------|
| New feature | planner → architect (if needed) → coder |
| Bug fix | coder |
| Code review | coder |
| Refactor | architect (if needed) → coder |
| Security audit | critic → coder (if fixes needed) |
| Performance | coder → architect (if structural redesign needed) |
| Architecture | architect |
| Documentation | documentor |
| "Why is this happening?" | coder |

## Script Ownership

### Circle-owned workflow script
These remain specific to coding-circle orchestration:

```bash
bash <resolved-circle-root>/scripts/project-scan.sh [args]
```

### Architect-owned reusable scripts
These are now specialist-owned and reusable:

```bash
bash <resolved-agent-root>/architect/scripts/file-map.sh [args]
bash <resolved-agent-root>/architect/scripts/find-entry-points.sh [args]
bash <resolved-agent-root>/architect/scripts/dependency-check.sh [args]
```

### Coder-owned reusable scripts
These are now specialist-owned and reusable:

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
