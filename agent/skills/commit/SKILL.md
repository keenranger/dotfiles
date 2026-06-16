---
name: commit
description: Prepare git commit with review. Use when user asks to commit, review changes for commit, or says /commit.
disable-model-invocation: true
---

Prepare commit: $ARGUMENTS

Review current changes and prepare commit for user approval.
Call git-diff-reviewer agent and toss process to it.

Process:

- Run git status and git diff to see all changes
- Review changes for quality and completeness
- Suggest commit message (use imperative form)

Output:

- Review summary of changes
- Suggested commit message
- Wait for user approval before executing commit

Goal: Thoughtful commit preparation without auto-committing.
