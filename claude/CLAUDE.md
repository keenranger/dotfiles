- Delegate exploration and research to agents to minimize context use
- No emoji

## Principles
- Trust the model's reasoning - provide outcomes, not step-by-step processes
- Prefer native tool behavior over custom scripts
- When extending libraries, inherit and override only what's needed

## Scope and Context
- Cross-cutting changes (field renames, API updates): always check test files, shell scripts, docs, and all consuming code for missed references
- When scope is ambiguous, confirm the specific target (issue ID, branch, directory) before starting work

## Code Discipline
- State assumptions explicitly; when multiple interpretations exist, present options rather than picking silently
- Push back when a simpler approach exists; self-test: "Would a senior engineer say this is overcomplicated?"
- Match existing style, even if you'd do it differently
- Every changed line must trace directly to the request
- Remove imports/variables your changes made unused, but leave pre-existing dead code alone
- Write documentation and comments in English unless told otherwise
- For vague tasks, define verifiable success criteria before writing code - prefer test-first: write a failing test, then make it pass
- For non-trivial changes, present the approach (which files, what strategy) and wait for approval before editing

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
- oxlint + oxfmt for new projects
- Strict: noUnusedLocals, noUnusedParameters

## Android
- App launch on a device: `android run --device=<serial> --apks=<path>` (the `android` CLI from android-cli skill). Do NOT use `adb shell monkey -c LAUNCHER` or `adb shell am start` for launching the app.
- Gradle invocations need `JAVA_HOME` and `ANDROID_HOME` exported per shell (Bash tool calls don't share env). Either prefix every call (`JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ANDROID_HOME="$HOME/Library/Android/sdk" ./gradlew ...`), or set `org.gradle.java.home=...` in `~/.gradle/gradle.properties` and `sdk.dir=...` in `local.properties`. Prefer the properties-file approach for any project where you'll run gradle more than three times.

## Kotlin
- `Byte.toInt()` sign-extends. `0x99.toByte().toInt()` is `-103`, and `String.format("%02x", _)` renders it as `ffffff99`. Always mask with `& 0xff` when formatting bytes as hex or feeding them to bit operations: `String.format("%02x", b.toInt() and 0xff)`.

## Secrets
- Sentry DSN is safe to expose publicly - it only allows sending events, not reading data

## CI Review Bots
- `gemini-code-assist[bot]` re-emits its prior review comments on every push; if the same comments re-appear in CI monitor output after a fix push, confirm against the file content before treating them as new findings.

## Figma MCP
1. `get_metadata` - XML structure (node IDs, names, positions, sizes)
2. `get_design_context` - implementation details with `data-annotations`

Always use both: metadata for structure, design_context for annotations.

### Implementation rules
- Never assume design values -- present extracted spacing, color, and typography to the user for confirmation before editing
- Trust the user's screenshot over tool output when they conflict
- If Tailwind JIT fails to generate a class, use arbitrary values (`gap-[12px]`) or CSS variables immediately
- After implementing, summarize every design value used so the user can verify at a glance
