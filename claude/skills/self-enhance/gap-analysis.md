# Gap Analysis

How to identify what's missing in current Claude configuration.

## Process

### 1. Inventory Current State
```
skills/       → What knowledge exists?
agents/       → What executors exist?
commands/     → What workflows exist?
CLAUDE.md     → What preferences/context exists?
```

### 2. Map Recent Work
From GitHub and conversations:
- What domains were touched?
- What tasks were performed?
- What decisions were made?

### 3. Find Mismatches

**Missing Skill**: Domain knowledge used but not documented
- Sign: Repeated context-setting in conversations
- Fix: Create skill with that knowledge

**Missing Agent**: Task done repeatedly without specialization
- Sign: Same multi-step process done manually
- Fix: Create agent for that task

**Missing Command**: Workflow done often without shortcut
- Sign: Typing same instructions repeatedly
- Fix: Create command for that workflow

**Outdated Content**: Knowledge that has evolved
- Sign: Corrections to Claude's assumptions
- Fix: Update existing skill/agent/command

**Over-Engineering**: Complexity not providing value
- Sign: Skills/agents rarely used
- Fix: Simplify or remove

## Priority

High priority gaps:
1. Daily friction (most impact)
2. Error-prone areas (prevents mistakes)
3. Complex domains (hardest to re-explain)

Low priority:
1. Rare tasks
2. Simple tasks
3. Rapidly changing areas (will need constant updates)
