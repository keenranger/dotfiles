---
name: config-bump
description: Atomic config change with version bump and commit. Use when updating config values, changing thresholds, or says /config-bump.
disable-model-invocation: true
argument-hint: "[config change description]"
---

Atomic config update: $ARGUMENTS

Edit config file, bump version, and commit in one atomic workflow.

Process:

- Locate and edit the config file
- Bump version (minor for new values, patch for tweaks)
- Stage changes and commit with descriptive message
- Use signed commits (-S flag)

Output:

- Confirmation of changes made
- New version number
- Commit hash

Goal: Complete config changes atomically without stopping mid-workflow.
