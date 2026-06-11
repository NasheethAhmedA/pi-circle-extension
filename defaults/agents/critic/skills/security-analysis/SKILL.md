---
name: security-analysis
description: Analyze code, architecture, or workflows for security risks, attack surfaces, and unsafe assumptions.
---
# Security Analysis

## When This Applies
Use for security review, threat-focused critique, or hardening analysis.

## Process
1. Define the surface being reviewed.
2. Identify trust boundaries, attack surfaces, and unsafe assumptions.
3. Prioritize the most serious risks.
4. Distinguish confirmed risk from speculative concern.
5. Return concise findings and mitigations, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Fear-based vague warnings
- ❌ Treating every issue as critical
- ❌ Mixing implementation fixes into the analysis without separating them
