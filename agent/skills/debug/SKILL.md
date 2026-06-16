---
name: debug
description: Debug issues systematically, especially mobile/platform-specific. Use when user asks to debug, diagnose, troubleshoot, or says /debug.
argument-hint: "[issue description]"
---

Debug issue: $ARGUMENTS

Systematic debugging for mobile and platform-specific issues.

Agent usage:

- Use research agent to find similar issues in git history and codebase
- Use parallel agents to check iOS and Android implementations separately when relevant

Skill reference:

- Consult react-native-patterns skill (especially platform.md) for known iOS/Android issues

Process:

- Identify symptoms and reproduction steps
- Search git history for recent changes to affected areas
- Check platform-specific implementations
- Identify root cause hypothesis

Output:

- Problem analysis with evidence
- Root cause hypothesis
- Proposed fix approach
- Related files to examine

Goal: Structured debugging that leverages codebase history and learned platform patterns.
