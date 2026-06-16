---
name: feature-dev
description: Develop features end-to-end from planning to PR. Use when user asks to implement feature, build functionality, or says /feature-dev.
argument-hint: "[feature description]"
---

Develop feature: $ARGUMENTS

Comprehensive workflow: plan -> find similar -> implement -> review -> offer PR.

Phase 1 - Planning & Research:

- Understand requirements and constraints
- Search git history for similar implementations (query commit messages and diffs)
- Identify existing patterns to reuse or adapt
- Consider: minimal implementation, architecture fit, tests needed, edge cases
- Create implementation plan

Phase 2 - Implementation:

- Implement following discovered patterns
- Use code-implementation agent for focused work
- Use parallel agents for independent components (DB + API + UI)
- Make atomic commits as you progress
- Create feature branch if needed

Phase 3 - Completion:

- Self-review code quality
- Run tests if available
- Offer to create PR using /pr command (or user can do separately)

Agent usage:

- Use Explore agent to search codebase and git history for similar implementations
- Use code-implementation agent for focused implementation work
- Launch multiple parallel agents for independent subtasks that can be developed simultaneously

Goal: Ship complete, tested features from planning through PR, learning from codebase history.
