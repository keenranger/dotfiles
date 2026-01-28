- Use agents for all exploration and information gathering tasks to minimize context use
## Agent Usage
- The research agent is the default choice for any exploration - both external documentation and internal codebase
- Research agent should gather, filter, and return only essential information
- Delegate to agents rather than doing multi-step searches directly in the main context
- Use multiple agents in parallel when possible for faster execution

## Engineering Philosophy
- Minimize code and code changes - the best code is no code, the best change is the smallest change
- Prefer native tool behavior over custom scripts - use tools as designed rather than adding wrappers
- When extending libraries, inherit and override only what's needed - don't reimplement entire classes
- Agent instructions should be clear but not rigid or verbose - focus on goals and principles, not prescriptive workflows that constrain reasoning

## Git and Version Control
- I always want to make signed commit
- Commit message style:
  - Use imperative ("Replace X", "Add Y", "Update Z")
  - Avoid verbose prefixes like "Refactor: Replace ~" - just "Replace ~"
- Try to commit by git diff, not by chat history (this could contaminate commit)

## Personal Preferences
- I do not prefer using emoji

## Python Development
- Always use uv pip install instead of pip install
- Prefer httpx over requests for HTTP requests
- Use ruff for linting and formatting (not black or other tools)
- Prefer uvx ty for type checking instead of mypy
- Use uv build backend for pyproject.toml (https://docs.astral.sh/uv/concepts/build-backend/)
- Use 127.0.0.1 instead of localhost for local servers (SAM local, etc.) - avoids DNS resolution issues

## TypeScript Development
- pnpm preferred (use node-linker=hoisted for React Native + NativeWind)
- Biome for new projects (ESLint + Prettier in existing)
- Strict TypeScript (noUnusedLocals, noUnusedParameters)

## Secrets and Keys
- Sentry DSN is safe to expose publicly - it only allows sending events, not reading data
