---
name: enhance
description: Analyze work patterns and improve Claude Code or Codex configuration. Use when user asks to improve Claude Code or Codex setup, optimize workflow, or says /enhance.
---

Analyze work patterns and propose improvements to Claude Code or Codex configuration: $ARGUMENTS

Improve how your coding agent helps you by analyzing your work and suggesting configuration changes.

Agent usage:

- Use enhance agent for analysis and proposals
- Reference self-enhance skill for framework knowledge

Process:

- Identify the active runtime before reviewing its skills, agents, commands, and settings
- Keep Claude Code JSON settings and Codex TOML settings distinct; do not rename commands or models by substituting a product name
- Analyze GitHub activity for work patterns
- Identify gaps between current config and actual work
- Propose concrete improvements

Output:

- Summary of current Claude Code or Codex configuration
- Work pattern analysis from GitHub
- Prioritized improvement proposals
- Recommended next steps

Goal: Continuously improve your coding agent's ability to help you based on how you actually work.
