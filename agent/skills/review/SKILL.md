---
name: review
description: Review code for quality, correctness, security. Use when user asks for code review, wants feedback on changes, or says /review.
---

Review code: $ARGUMENTS

Analyze changes for quality, correctness, and maintainability.

Agent usage:

- Always launch in parallel for independent full review:
  - git-diff-reviewer agent (Claude)
  - codex:codex-rescue agent (Codex/GPT-5.4)
- For complex/critical changes: Add 1-2 general-purpose agents for additional perspectives
- After all agents return, deduplicate and elevate issues flagged by multiple reviewers

Focus areas:

- Code quality: Readability, structure, patterns, technical debt
- Correctness: Logic errors, edge cases, error handling
- Testing: Coverage, test quality, missing scenarios
- Security: Vulnerabilities, input validation, sensitive data
- Performance: Bottlenecks, optimization opportunities
- Breaking changes: API changes, backward compatibility
- Scope: Verify changes are limited to what was requested -- flag additions, refactors, or config changes beyond the stated purpose

Output:

- Executive summary (1-2 paragraphs)
- Detailed findings (organized by severity: critical, major, minor)
- Risk assessment (low/medium/high with rationale)
- Recommended actions

Goal: Catch real issues while avoiding false positives.
