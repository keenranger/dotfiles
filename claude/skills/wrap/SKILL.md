---
name: wrap
description: Pre-commit session analysis for docs and permissions. Use when user is finishing work, about to commit, has completed a significant task, or says /wrap.
context: fork
---

Pre-commit session analysis: $ARGUMENTS

Analyze session for documentation and permission updates before committing.

Agent usage:

- Run in parallel:
  - enhance agent: CLAUDE.md updates, automation opportunities, follow-ups
  - permission-analyzer agent: Permission whitelist proposals based on session activity
  - retrospective agent: Session guidance analysis and workflow suggestions

Pass session context to agents - they need conversation history to analyze.

Focus areas:

- Learnings: Technical discoveries, mistakes made, new patterns
- CLAUDE.md: Preferences or patterns worth persisting
- Permissions: Bash commands and domains used that should be whitelisted
- Automation: Repetitive patterns that could become skills/commands/agents
- Follow-ups: Incomplete work, TODO markers, next session priorities
- Retrospective: User guidance patterns that could be improved

Duplicate check:

- Before proposing, check both project (`.claude/`) and user (`~/.claude/`) locations
- Skip proposals that duplicate existing content

Permission placement:

- Project settings (`.claude/settings.json`) for project-specific permissions
- User settings (`~/.claude/settings.json`) for personal/global tools

Output:

- Summary of session activity
- Categorized proposals (docs, permissions, automations)
- Follow-up tasks for next session
- Workflow suggestions (from retrospective)
- User selection: which proposals to apply

User selection:

- Present options via AskUserQuestion
- Options: update CLAUDE.md, add permissions, create automations, skip
- Execute only selected actions

Goal: Enrich configuration before each commit.
