---
name: performance-optimization
description: Diagnose and improve performance bottlenecks in code or system behavior.
---
# Performance Optimization

## When This Applies
Use for latency, throughput, memory, or efficiency improvements.

## Process
1. Identify the bottleneck and success metric.
2. Inspect the relevant path, hot spots, and unnecessary work.
3. Apply the simplest change that improves the measured problem.
4. Verify the improvement and note trade-offs.
5. Return bottleneck, change, and result, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Optimizing without a target bottleneck
- ❌ Trading clarity for tiny gains without reason
- ❌ Claiming improvement without verification
