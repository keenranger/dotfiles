## Agent Usage
- Use agents for all exploration and information gathering tasks to minimize context use
- The research agent is the default choice for any exploration - both external documentation and internal codebase
- Research agent should gather, filter, and return only essential information
- Delegate to agents rather than doing multi-step searches directly in the main context

## Engineering Philosophy
- Minimize code and code changes - the best code is no code, the best change is the smallest change
- Agent instructions should be clear but not rigid or verbose - focus on goals and principles, not prescriptive workflows that constrain reasoning

## Git and Version Control
- I always want to make signed commit
- Prefer 'Replace ~' over 'Refactor: Replace ~' when making commits.
- Try to commit by git diff, not by chat history(this could be contaminate commit)

## Personal Preferences
- I do not prefer using emoji

## Python Development
- Always use uv pip install instead of pip install
