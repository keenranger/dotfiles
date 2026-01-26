---
name: pr
description: Create GitHub pull request. Use when user asks to create PR, open pull request, or says /pr.
disable-model-invocation: true
argument-hint: "[description]"
---

Create a GitHub PR for: $ARGUMENTS

Agent usage:

- Use pr-creator agent for PR creation

Use conventional commit format for title (feat:, fix:, docs:). Be specific, 50-70 characters. Include issue number if relevant.

Structure the PR description with:

- Summary (2-3 sentences: what, why, approach)
- Key changes (3-7 bullets, highlight breaking changes)
- Type of change (bug fix, feature, breaking change, docs, refactor, performance)
- Testing performed (tests added/updated, manual testing, edge cases)
- Related issues (Closes #X, Related to #Y)

Provide complete PR description in Markdown, then check available labels with `gh label list` and suggest only labels that exist, along with the gh pr create command.

Focus on helping reviewers understand changes quickly.
