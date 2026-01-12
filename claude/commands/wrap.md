Wrap up session: $ARGUMENTS

End-of-session reflection and capture.

Quick mode:

- If $ARGUMENTS contains a commit message, create signed commit directly and skip analysis

Agent usage:

- Run in parallel:
  - enhance agent: CLAUDE.md updates, automation opportunities, follow-ups
  - permission-analyzer agent: Permission whitelist proposals based on session activity

Pass session context to agents - they need conversation history to analyze.

Focus areas:

- Learnings: Technical discoveries, mistakes made, new patterns
- CLAUDE.md: Preferences or patterns worth persisting
- Permissions: Bash commands and domains used that should be whitelisted
- Automation: Repetitive patterns that could become skills/commands/agents
- Follow-ups: Incomplete work, TODO markers, next session priorities

Duplicate check:

- Before proposing, agents must check existing content (CLAUDE.md, settings.local.json, skills/, commands/, agents/)
- Skip proposals that duplicate existing content

Output:

- Summary of session activity
- Categorized proposals (docs, permissions, automations)
- Follow-up tasks for next session
- User selection: which proposals to apply

User selection:

- Present options via AskUserQuestion
- Options: commit changes, update CLAUDE.md, add permissions, create automations, skip
- Execute only selected actions

Goal: Make session wrap-up a habit that enriches configuration over time.
