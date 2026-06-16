# Proposal Format

How to propose improvements to Claude configuration.

## Structure

### Summary
One sentence: what improvement and why.

### Type
- New Skill
- New Agent
- New Command
- Update Existing
- Remove/Simplify

### Evidence
What signals led to this proposal:
- GitHub activity showing pattern
- Conversation showing repeated context
- Gap analysis finding

### Proposed Change

For Skill:
```
skills/{name}/
├── SKILL.md      # Core definition
└── {topic}.md    # Supporting knowledge
```

For Agent:
```markdown
# Agent Name
Description, tools, process
```

For Command:
```markdown
# /command
What it does, when to use
```

### Impact
- What improves?
- What's the effort?
- Any risks?

## Example Proposal

```markdown
## Summary
Create `api-design` skill for consistent API patterns across projects.

## Type
New Skill

## Evidence
- 5 PRs in last month adding API endpoints
- Repeated decisions about error formats, pagination
- Corrections about preferred HTTP status codes

## Proposed Change
skills/api-design/
├── SKILL.md
├── rest-conventions.md
├── error-handling.md
└── pagination.md

## Impact
- Consistent APIs without re-explaining preferences
- Effort: Medium (need to document patterns)
- Risk: Low
```
