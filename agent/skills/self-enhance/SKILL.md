---
name: self-enhance
description: Framework for improving Claude Code or Codex configuration (skills, agents, commands). Use when analyzing work patterns, proposing new skills, identifying knowledge gaps, reviewing Claude Code or Codex setup, or when user asks to improve how their coding agent helps them.
---

# Self-Enhancement Framework

Improve your coding agent's ability to help you by analyzing patterns and proposing configuration changes.

Identify the active runtime and keep its configuration format and tool names intact. Claude Code uses `.claude/settings.json` and `.claude/settings.local.json`; Codex uses `.codex/config.toml`. Do not translate commands or model identifiers by replacing product names.

## What This Skill Covers

- When to create skills vs agents vs commands
- How to discover patterns in work history
- How to identify knowledge gaps
- How to propose and structure improvements

## Quick Reference

| Type | Purpose | Trigger |
|------|---------|---------|
| Skill | Cross-project knowledge | Auto-discovered |
| Agent | Specialized executor | Task tool |
| Command | User workflow shortcut | /command |

## Supporting Files

- [patterns.md](patterns.md) - How to find patterns in work
- [gap-analysis.md](gap-analysis.md) - How to identify what's missing
- [proposal-format.md](proposal-format.md) - How to structure proposals
