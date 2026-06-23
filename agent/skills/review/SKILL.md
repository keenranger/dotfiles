---
name: review
description: Review local changes, a PR, or an issue for quality, correctness, security. Use when user asks for review, wants feedback on changes, or says /review.
---

Review target: $ARGUMENTS

Route to one of three modes based on the target, dispatch the matching reviewers in parallel, then synthesize a single verdict.

## 1. Classify the target

- Empty, file paths, "staged", or a commit range -> LOCAL changes
- Issue URL, "issue N", or #N that resolves to an issue -> ISSUE
- PR URL, "pr N", or #N that resolves to a PR -> PR

Resolve a bare #N with `gh pr view N`, falling back to `gh issue view N`. An explicit keyword in the arguments (`local`, `pr`, `issue`) overrides detection.

## 2. Dispatch reviewers (parallel)

- LOCAL: git-diff-reviewer agent (Claude) + codex:codex-rescue agent (Codex/GPT-5.4)
- PR: pr-issue-reviewer agent (fetches `gh pr view` + `gh pr diff`) + codex:codex-rescue agent on the same patch
- ISSUE: pr-issue-reviewer agent (fetches `gh issue view`) + a general-purpose agent that investigates the codebase for feasibility
- Complex or critical targets: add 1-2 general-purpose agents for additional perspectives

After all agents return, deduplicate and elevate issues flagged by multiple reviewers.

## 3. Focus areas (apply what fits the target)

Code (LOCAL / PR):

- Code quality: readability, structure, patterns, technical debt
- Correctness: logic errors, edge cases, error handling
- Testing: coverage, test quality, missing scenarios
- Security: vulnerabilities, input validation, sensitive data
- Performance: bottlenecks, optimization opportunities
- Breaking changes: API changes, backward compatibility
- Scope: verify changes are limited to what was requested -- flag additions, refactors, or config changes beyond the stated purpose

Issue (ISSUE):

- Clarity: is the problem and desired outcome unambiguous?
- Reproducibility: steps, environment, expected vs actual behavior
- Acceptance criteria: is "done" defined and verifiable?
- Feasibility: grounded in the actual codebase, not assumptions
- Risks and unknowns: what could make this harder than it looks?

## 4. Output

- Executive summary (1-2 paragraphs)
- Detailed findings (organized by severity: critical, major, minor)
- Risk assessment (low/medium/high with rationale)
- Verdict and recommended actions:
  - LOCAL: ready to commit / split into commits / fixes needed
  - PR: ready to merge / needs work
  - ISSUE: ready to implement (with a suggested approach) / needs clarification

Goal: Catch real issues while avoiding false positives.
