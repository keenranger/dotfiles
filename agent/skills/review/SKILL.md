---
name: review
description: Review local changes, a PR, or an issue for quality, correctness, security. Use when user asks for review, wants feedback on changes, or says /review.
---

Review target: $ARGUMENTS

Route to one of three modes based on the target, select reviewers for the current harness and risk, then synthesize a single verdict.

## 1. Classify the target

- Empty, file paths, "staged", or a commit range -> LOCAL changes
- Issue URL, "issue N", or #N that resolves to an issue -> ISSUE
- PR URL, "pr N", or #N that resolves to a PR -> PR

Resolve a bare #N with `gh pr view N`, falling back to `gh issue view N`. An explicit keyword in the arguments (`local`, `pr`, `issue`) overrides detection.

## 2. Assess risk and prepare evidence

- Small: one concern, localized behavior, low blast radius, and no security, concurrency, persistence, migration, release, or device implications
- Substantial: a large diff, multiple subsystems, or any high-risk category above. Diff size is only a heuristic; risk and subsystem breadth decide the route
- Fetch the target once. For a PR, pass the fetched patch to every reviewer instead of assuming the PR branch is checked out. Give each worker the exact diff, files, range, and question it needs

## 3. Dispatch by harness

Claude Code:

- Small LOCAL/PR: git-diff-reviewer with `model: fable`
- Substantial LOCAL/PR: an Opus research/general-purpose pass for source-anchored code evidence, then git-diff-reviewer with `model: fable` for the verdict, plus codex:codex-rescue for an independent adversarial pass
- ISSUE: pr-issue-reviewer with `model: fable`; add an Opus code-reading pass when feasibility depends on tracing substantial existing code
- codex:codex-rescue uses the Codex CLI's configured default. Never pin a Codex model name in this shared skill

Codex:

- In Orca, create supervised Claude workers in the current worktree. Small targets use Fable. Substantial targets use an Opus evidence worker followed by a Fable verdict worker; add one scoped `codex exec --ephemeral --sandbox read-only` reviewer with delegation forbidden as the independent pass
- Outside Orca, use bounded non-interactive Claude calls with explicit `opus` or `fable` model aliases when the Claude CLI is available. Pass the target directly and tell the worker not to invoke `/review`
- If Claude cannot be launched, run the scoped Codex reviewer and label the verdict `Codex-only; Claude cross-check unavailable`

All harnesses:

- Workers must not invoke `/review`; recursive review dispatch is forbidden
- Do not invoke `codex review --uncommitted` while it auto-activates the installed `review` skill; that path recursively launches reviewers in the current runtime. The interactive coordinator owns the single scoped Codex pass and any separate Claude cross-check
- Add an independent Codex pass only for substantial/critical targets or when the user requests a cross-check
- Report the roles that actually completed: Opus evidence, Fable verdict, Codex independent pass, or an explicit fallback

After all agents return, normalize each reviewer's severity labels into critical/major/minor (e.g. git-diff-reviewer's Suggestions, pr-issue-reviewer's Blockers/Important/Consider), then deduplicate and elevate issues flagged by multiple reviewers.

## 4. Focus areas (apply what fits the target)

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

## 5. Output

- Executive summary (1-2 paragraphs)
- Detailed findings (organized by severity: critical, major, minor)
- Risk assessment (low/medium/high with rationale)
- Verdict and recommended actions:
  - LOCAL: ready to commit / split into commits / fixes needed
  - PR: ready to merge / needs work
  - ISSUE: ready to implement (with a suggested approach) / needs clarification

Goal: Catch real issues while avoiding false positives.
