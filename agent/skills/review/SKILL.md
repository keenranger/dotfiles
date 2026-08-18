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

## 3. Select roles, then dispatch by harness and Orca context

Select Claude roles from risk before choosing the execution mechanism:

- Small LOCAL/PR: use a Fable verdict worker
- Substantial LOCAL/PR: use an Opus evidence worker for source-anchored code reading, then a Fable verdict worker
- ISSUE: use a Fable verdict worker; add an Opus evidence worker when feasibility depends on tracing substantial existing code

Treat any `ORCA_*` worktree or terminal context, including `ORCA_WORKTREE_ID` or `ORCA_TERMINAL_HANDLE`, as Orca. Do not gate this decision only on `ORCA_WORKSPACE_ID`. When no `ORCA_*` variable reaches the agent shell, use a successful `orca worktree current --json` lookup as the fallback signal that the current directory is an Orca-managed worktree.

### Claude Code in Orca

- Run Fable and Opus roles as native Claude agents: git-diff-reviewer or pr-issue-reviewer with `model: fable`, and research/general-purpose with `model: opus`
- When an independent Codex pass is required, load the `orchestration` skill and dispatch a supervised Orca Codex worker in the current worktree. Put these constraints in the worker task specification: direct review only, read-only, do not load or invoke the shared review skill, and no delegation. Do not use codex:codex-rescue for this Orca-managed pass

### Claude Code outside Orca

- Run Fable and Opus roles as the same native Claude agents
- When an independent Codex pass is required, use codex:codex-rescue. It uses the Codex CLI's configured default; never pin a Codex model name in this shared skill

### Codex in Orca

- Use the managed cross-runtime path: load the `orchestration` skill and dispatch supervised Orca Claude workers in the current worktree. Start the evidence worker with `worker-start --agent claude --model opus`, wait for its bounded evidence, then pass that evidence to the verdict worker started with `worker-start --agent claude --model fable`. Put these constraints in both worker task specifications: direct review only, read-only, do not load or invoke the shared review skill, and no delegation
- When an independent Codex pass is required, add one scoped `codex exec --ephemeral --sandbox read-only` reviewer with delegation forbidden

### Codex outside Orca

- Treat `claude -p --model opus` or `claude -p --model fable` only as a best-effort one-shot subprocess fallback for the selected Claude roles. First confirm that the Claude CLI is installed and authenticated and that the Codex runtime permits child processes. Constrain it to read-only tools, pass the target directly, forbid `/review`, and label the result `Non-Orca Claude one-shot`; this is not a Codex-native agent or a Claude-model MCP bridge and has no supervised worker lifecycle. `claude mcp serve` exposes Claude Code tools to an MCP client but does not run Fable or Opus as a reviewer
- If the one-shot prerequisites fail or the call does not complete, run the scoped Codex reviewer and label the verdict `Codex-only; Claude cross-check unavailable`

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
