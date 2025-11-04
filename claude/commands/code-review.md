Review code: $ARGUMENTS

Analyze changes for quality, correctness, and maintainability.

Agent usage:

- For git diff review: Use git-diff-reviewer agent
- For complex/critical changes: Launch 2-3 general-purpose agents in parallel to review independently, then compare findings to reduce false positives

Focus areas:

- Code quality: Readability, structure, patterns, technical debt
- Correctness: Logic errors, edge cases, error handling
- Testing: Coverage, test quality, missing scenarios
- Security: Vulnerabilities, input validation, sensitive data
- Performance: Bottlenecks, optimization opportunities
- Breaking changes: API changes, backward compatibility

Output:

- Executive summary (1-2 paragraphs)
- Detailed findings (organized by severity: critical, major, minor)
- Risk assessment (low/medium/high with rationale)
- Recommended actions

Goal: Catch real issues while avoiding false positives.
