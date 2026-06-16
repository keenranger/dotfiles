---
name: issue
description: Create GitHub issue. Use when user asks to create issue, file bug, request feature, or says /issue.
disable-model-invocation: true
argument-hint: "[title or description]"
---

Create a GitHub issue for: $ARGUMENTS

Agent usage:

- Use issue-creator agent for issue creation

Title: Start with action verb (Fix, Add, Update, Remove, Implement). Be specific, 50-70 characters. Include component/area.

Structure:

- Description (2-4 sentences: problem/feature, why it matters, impact)
- Current behavior (for bugs: what happens now, error messages, repro steps)
- Expected behavior (desired outcome, acceptance criteria)
- Technical details (if complex: architecture, requirements, implementation approach)
- Additional context (environment, screenshots, related issues/PRs, deadlines)

Output complete GitHub issue, then check available labels with `gh label list` and suggest only labels that exist in the repository, along with the gh issue create command.

Good issues are actionable, have clear acceptance criteria, and provide enough context for any developer.
