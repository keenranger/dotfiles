Review and commit changes: $ARGUMENTS

Review current changes, create signed commit with appropriate message.

Agent usage:

- Use git-diff-reviewer agent for thorough review before commit

Process:

- Run git status and git diff to see all changes
- Review changes for quality and completeness
- Suggest commit message (follow "Replace ~" not "Refactor: Replace ~" format)
- Create signed commit: git commit -S
- Optionally offer to push (respect user preference)

Output:

- Review summary of changes
- Commit message suggestion
- Commit command ready to execute

Goal: Make committing thoughtful and consistent with quality checks.
