- Delegate exploration and research to agents to minimize context use
- No emoji

## Principles
- Trust the model's reasoning - provide outcomes, not step-by-step processes
- Prefer native tool behavior over custom scripts
- When extending libraries, inherit and override only what's needed

## Code Discipline
- State assumptions explicitly; when multiple interpretations exist, present options rather than picking silently
- Push back when a simpler approach exists; self-test: "Would a senior engineer say this is overcomplicated?"
- Match existing style, even if you'd do it differently
- Every changed line must trace directly to the request
- Remove imports/variables your changes made unused, but leave pre-existing dead code alone
- For vague tasks, define verifiable success criteria before writing code - prefer test-first: write a failing test, then make it pass
- For multi-step tasks, state the plan with explicit verification at each step

## Agents
- Research agent is the default for any exploration - external docs and internal codebase
- Use multiple agents in parallel when possible; keep instructions goal-oriented, not prescriptive

## Git
- Always sign commits with GPG (`git commit -S`)
- Imperative messages: "Replace X", "Add Y" - no verbose prefixes like "Refactor: Replace ~"
- Commit from git diff, not chat history

## Python
- uv pip install (not pip), uv build backend for pyproject.toml
- httpx over requests
- ruff for lint/format, uvx ty for type checking
- 127.0.0.1 instead of localhost

## TypeScript
- pnpm (node-linker=hoisted for React Native + NativeWind)
- Biome for new projects (ESLint + Prettier in existing)
- Strict: noUnusedLocals, noUnusedParameters

## Secrets
- Sentry DSN is safe to expose publicly - it only allows sending events, not reading data

## Figma MCP
1. `get_metadata` - XML structure (node IDs, names, positions, sizes)
2. `get_design_context` - implementation details with `data-annotations`

Always use both: metadata for structure, design_context for annotations.
