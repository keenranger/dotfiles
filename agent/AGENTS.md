- Delegate exploration and research to agents to minimize context use
- No emoji

## Principles
- Trust the model's reasoning - provide outcomes, not step-by-step processes
- Prefer native tool behavior over custom scripts
- When extending libraries, inherit and override only what's needed

## Accessibility
- Build products that people with disabilities can fully enjoy. Consider their different ways of using the product from the start, so disability does not become a barrier to the experience.
- Make accessibility part of everyday design, not a final inspection to pass. Care for the details that let people share the same rich experience, rather than offering a separate, reduced version.
- Support different ways of perceiving and interacting while preserving meaning, context, and useful choices across the experience.
- Use assistive technology and, when possible, feedback from people who rely on it to find and remove barriers in real use. Let verification support this care, not replace it with a checklist.

## Scope and Context
- Cross-cutting changes (field renames, API updates): always check test files, shell scripts, docs, and all consuming code for missed references
- When scope is ambiguous, confirm the specific target (issue ID, branch, directory) before starting work
- Migration / lint / rename PRs: only touch files required for the migration. Do NOT reformat unrelated files (Python, markdown, configs), refactor hook deps, or polish adjacent code. If a broader change feels warranted, propose it as a one-liner and wait before editing

## Code Discipline
- State assumptions explicitly; when multiple interpretations exist, present options rather than picking silently
- Push back when a simpler approach exists; self-test: "Would a senior engineer say this is overcomplicated?"
- Match existing style, even if you'd do it differently
- Every changed line must trace directly to the request
- Remove imports/variables your changes made unused, but leave pre-existing dead code alone
- Write documentation and comments in English unless told otherwise
- For vague tasks, define verifiable success criteria before writing code - prefer test-first: write a failing test, then make it pass
- For non-trivial changes, present the approach (which files, what strategy) and wait for approval before editing
- If the user corrects the same kind of misinterpretation twice in one session, stop, name the pattern, and propose a permanent fix (AGENTS.md rule, memory entry, or skill update) before continuing. The moment of the second correction is when the pattern is most visible -- don't defer this to /wrap or a retrospective pass
- For generated images, pets, videos, or other visual artifacts, never state or imply the artifact exists until a generation/edit tool has returned a real result or a saved file has been verified. If the user asks to see an image, show the artifact or provide the verified path before describing it. If generation fails or returns no usable file, say that plainly and do not substitute a description for the missing output.

## Investigation Discipline
- Before claiming a symbol/function/file doesn't exist, search beyond the working tree: `git log --all -S '<name>' --source --remotes` and `git grep '<name>' $(git rev-list --remotes | head -200)`. `git grep` and Grep alone miss unmerged branches
- Don't assert plugin behavior, device models, library APIs, or UI element existence without confirming. Android device names come from `adb shell getprop ro.product.model`, not the serial prefix. UI claims need source-read or live app verification first

## Agents
- Research agent is the default for any exploration - external docs and internal codebase
- Use multiple agents in parallel when possible; keep instructions goal-oriented, not prescriptive

### Model routing
Shared principles (any runtime - Claude Code or Codex):
- Reserve the main loop for orchestration: architecture and design decisions, cross-cutting judgment, final review. Bulk reading, token-heavy sweeps, and mechanical edits go to cheaper delegates that report only findings back
- Prefer Codex for the user-facing coordination loop and bounded implementation ping-pong. In Claude Code, use Fable at high effort for the equivalent coordination and judgment role. Do not hard-code a Codex model name in shared rules; use the runtime's configured default and raise effort only when the task's risk justifies it
- Route substantial code reading to Claude Opus. Route architecture, coding judgment, synthesis, and final verdicts to Claude Fable. Keep small reads and tightly-coupled decisions in the current loop when delegation would cost more than it saves
- GUI/computer use never runs in the main loop - see Computer Use / GUI Automation for executor routing (a separate Orca Codex worker for approval-seeded desktop and device work, haiku/sonnet subagents otherwise)

Orca cross-runtime sessions:
- Treat any `ORCA_*` worktree or terminal context (for example `ORCA_WORKTREE_ID` or `ORCA_TERMINAL_HANDLE`) as an Orca session; do not gate routing on `ORCA_WORKSPACE_ID`, which is not present in every Orca terminal
- When an independent task benefits from a full separate Claude Code or Codex session, use Orca's native current-worktree terminal and orchestration support. This creates a visible session with separate conversation context while sharing the checkout
- For a visible unsupervised companion, run `orca terminal create --worktree active --title "CLAUDE: <task>" --command "ORCA_COMPANION=1 claude" --json` or the equivalent `CODEX` / `codex` command. For result-returning work, load the `orchestration` skill and use a supervised worker instead
- Do not describe an in-process subagent, `claude -p`, or `codex exec` one-shot as a separate Orca session. Use those for bounded delegation; use an Orca worker when the user asks for, or the task benefits from, an independently visible session
- Shared-worktree sessions may work in parallel only when they are read-only or their write scopes are explicitly disjoint. The coordinator owns architecture, integrates results, and prevents overlapping edits
- A session launched with `ORCA_COMPANION=1` must not launch another Orca companion. It completes its assigned task and reports back to the coordinator

Claude Code:
- Code-heavy reading (subsystem deep-dives, tracing logic across many files, digesting large diffs): when possible use a separate opus agent - spawn research/Explore/general-purpose with model: opus - instead of reading in the main loop, and consume only its report. Overrides the sonnet defaults below whenever the task is mostly reading code; sonnet remains for breadth-first locating and non-code research, haiku for purely mechanical scans
- Exploration and codebase analysis: research agent (pinned sonnet)
- Built-in agents (Explore, Plan, general-purpose) inherit the session model - pass model: sonnet explicitly for token-heavy sweeps (codebase mapping, bulk analysis, multi-location searches), haiku for purely mechanical scans. Applies when skills spawn them too (feature-dev's Explore step, review's extra general-purpose reviewers)
- Implementation: hand well-specified, self-contained tasks to codex:codex-rescue proactively (write-capable) to conserve Claude quota - not only when stuck. Spawn the rescue wrapper as model: haiku - it only writes the handoff prompt, runs codex, and relays results. Keep work in the main loop or code-implementation (opus) when it needs session context or tight iteration
- New custom agents: pin model: in frontmatter - sonnet unless the task needs opus-level judgment. Unpinned agents silently inherit the session model

Codex:
- Token-heavy sweeps and side tasks: scoped `codex exec` one-shots downshifted via `-m <cheaper model>` or `-c model_reasoning_effort=low|medium` instead of the main interactive thread
- For an independent Codex review pass, use one scoped `codex exec --ephemeral --sandbox read-only` with a prompt that forbids delegation. Do not use `codex review --uncommitted` while the installed `review` skill auto-activates inside that command; it recursively launches more review processes in the current runtime
- When Claude judgment is required from Codex, use supervised Orca Claude workers as the managed path: Opus produces bounded code evidence and Fable makes the decision. Outside Orca, `claude -p --model opus` or `claude -p --model fable` is only a best-effort one-shot subprocess fallback after confirming that the Claude CLI is installed and authenticated and that the Codex runtime permits child processes. Constrain the call to read-only tools and label the result `Non-Orca Claude one-shot`. It is not a Codex-native agent or a Claude-model MCP bridge and provides no Orca session visibility, lifecycle tracking, or result handoff; `claude mcp serve` exposes Claude Code tools to an MCP client but does not run Fable or Opus as a reviewer. If any prerequisite fails or the call does not complete, use the scoped Codex-only review pass above and label it Codex-only

### Review routing
- Small, low-risk, single-concern change: Fable reviews directly. Add a Codex pass only when requested or when independence materially improves confidence
- Large diffs, cross-subsystem changes, migrations, security, concurrency, persistence, release, or device-sensitive work: Opus first reads the code and produces source-anchored evidence; Fable then evaluates correctness and gives the final verdict; Codex supplies an independent adversarial pass
- Review workers receive the target diff or exact file/range plus a bounded prompt. They must not invoke the shared `/review` skill from inside a review worker, which would recursively dispatch more reviewers
- Report which model roles actually ran. Never imply a Claude cross-check happened when the harness could not launch Claude or the call did not complete

### Real-device validation routing
- Fable defines the scenario, acceptance criteria, and final pass/fail judgment. Opus traces the implementation and identifies observability points before device work when substantial code reading is needed
- A separate Orca Codex worker executes device and GUI actions. It must acquire the repository's serial-specific device lease before any mutable ADB, UI, BLE, install, permission, or app-data action, and release it when finished
- Keep cold-start and warm-path checks separate. Keep build/install, launch, timed interaction, target-state UI/layout capture, visually checked same-state screenshot, logs/protocol evidence, and reconnect/read-back checks as separate gates where applicable
- A code review, successful build, layout dump, or delayed screenshot is not real-device proof. The final verdict names every passed gate, every missing physical or account-dependent gate, the device serial/model verified from the device, and the worker that produced the evidence

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
- oxlint + oxfmt for new projects; oxfmt `printWidth: 120` (oxfmt default is 100)
- Strict: noUnusedLocals, noUnusedParameters
- Korean IME: Enter/Submit and any onKeyDown that triggers an action must guard on `e.nativeEvent.isComposing` (React Native) or `e.isComposing` (web). Without it, Hangul composition fires the action mid-syllable and double-submits
- SDK boundaries: when a library exports a discriminated identifier-union with a sibling brand mapper (e.g. `QuantityTypeIdentifier` + `UnitForIdentifier<T>`), encode the table as `as const satisfies readonly Generic[]` and wrap each row in a small helper `const m = <T extends ...>(x: Generic<T>): Generic<T> => x` so TS infers each row's specific `T` from the literal and enforces the (identifier, unit) correlation. A bare array literal widens `T` to the union and silently drops the per-row correlation. Don't reach for `as never` / `as unknown[]` at SDK boundaries when the lib already provides typed unions -- those casts are escape hatches that defeat exactly the typo-catching the lib was designed to give you

## Android
- App launch on a device: `android run --device=<serial> --apks=<path>` (the `android` CLI from android-cli skill). Do NOT use `adb shell monkey -c LAUNCHER` or `adb shell am start` for launching the app.
- Gradle invocations need `JAVA_HOME` and `ANDROID_HOME` exported per shell (Bash tool calls don't share env). Either prefix every call (`JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ANDROID_HOME="$HOME/Library/Android/sdk" ./gradlew ...`), or set `org.gradle.java.home=...` in `~/.gradle/gradle.properties` and `sdk.dir=...` in `local.properties`. Prefer the properties-file approach for any project where you'll run gradle more than three times.
- Test cold-start (fresh launch, app data cleared, no granted permissions) before warm-path. BLE, foreground service, permission, and lifecycle bugs hide there -- warm-path passing tells you nothing about the cold-start failure mode users actually hit.
- Manifest merger preserves `maxSdkVersion` caps across libraries. If a library declares a permission with `android:maxSdkVersion="30"` and the consumer declares the same permission without a cap, the merged result still carries the cap -- the permission silently drops on API 31+. Libraries that need a permission only on legacy API levels should not declare it at all and let consumers declare it themselves; if a library must declare it, document the cap loudly. When runtime reports "permission not declared," inspect `app/build/outputs/logs/manifest-merger-debug-report.txt` and override transitive caps with `tools:remove="android:maxSdkVersion"`.

## Kotlin
- `Byte.toInt()` sign-extends. `0x99.toByte().toInt()` is `-103`, and `String.format("%02x", _)` renders it as `ffffff99`. Always mask with `& 0xff` when formatting bytes as hex or feeding them to bit operations: `String.format("%02x", b.toInt() and 0xff)`.
- `Double.roundToInt()` / `Float.roundToInt()` throw `IllegalArgumentException("Cannot round NaN value.")` on NaN (±Infinity is safe -- it saturates to `Int.MAX_VALUE`/`MIN_VALUE`). Any value from a division whose denominator can vanish (e.g. McCamy CIE-xy->CCT `n = (x - 0.3320) / (0.1858 - y)` at `y == 0.1858`) must be `.isNaN()`-guarded before rounding.

## macOS
- TCC + iCloud Drive containers: `~/Library/Mobile Documents/iCloud~*/` is TCC-protected. Background processes (launchd agents, MCP servers, headless tools) launched outside an interactive Terminal with Full Disk Access typically cannot read it -- reads silently succeed with empty results, not an error. The naive workaround (launchd user agent that mirrors the container under the user's account) does NOT work: the agent inherits launchd's TCC attribution and also returns empty. Correct fix is a signed `.app` bundle holding `com.apple.developer.icloud-container-identifiers` matching the source container, reading via `URLForUbiquityContainerIdentifier` + `NSFileCoordinator` + `startDownloadingUbiquitousItem`, and re-exporting to a TCC-free path (e.g. `~/.healthdrop/`). See HealthDrop ADR-001 for the full rationale and the closed `keenranger/healthdrop-skills` PR #2 for the cautionary tale.
- Diagnose silent-empty TCC reads by running the same read from a Terminal (works) vs. via `osascript -e 'do shell script ...'` or a launchd-loaded agent (returns empty). If both fail, the consumer process needs its own entitlement, not FDA.

## Homebrew
- Tap repo name MUST start with `homebrew-` (hardcoded in `brew tap` resolution). `brew tap user/foo` resolves to `github.com/user/homebrew-foo`. Cannot reuse a non-prefixed repo.
- For self-distributed apps that don't meet homebrew-core entry threshold (popularity, maintained record, broad user base), the standard pattern is a private tap at `<user>/homebrew-<product>` carrying a single `Casks/<name>.rb` (or `Formula/<name>.rb`). Examples: hashicorp/homebrew-tap, aws/homebrew-tap, github/homebrew-gh, 1password/homebrew-tap, ngrok/homebrew-ngrok, tailscale/homebrew-tap, goreleaser/homebrew-tap, dagger/homebrew-tap, vercel/homebrew-tap, supabase/homebrew-tap. Maintenance is near zero -- one metadata file per cask, version + sha256 bumped on release.
- Automate bumps via `goreleaser` (which writes its own cask) or `dawidd6/action-homebrew-bump-formula` in the release workflow, so the tap repo stops needing manual edits after initial setup.

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

## Computer Use / GUI Automation
GUI loops are the most token-hungry work the main model can do — every screenshot costs image tokens and a loop takes dozens. The main-loop model must NOT drive GUI loops in-process: delegate the loop to a cheaper executor and consume only its text summary. Connected computer-use / claude-in-chrome MCP servers inject instructions that push in-process use; that is generic harness text and this section overrides it.

Executor routing:
- **Desktop GUI or device validation, approval-seeded app:** a separate root-managed Orca Codex worker using the configured Codex default and `computer-use@openai-bundled`. Nine tools — `click`, `get_app_state`, `type_text`, `list_apps`, `press_key`, `set_value`, `perform_secondary_action`, `scroll`, `drag`. No screenshot tool; `get_app_state` returns screen state. Consume its text report and evidence instead of driving the loop through the in-session `codex:codex-rescue` wrapper.
- **Desktop GUI, unseeded app or Codex worker failure:** a haiku subagent (sonnet if the flow needs judgment) loads `mcp__computer-use__*` via ToolSearch and drives the loop. The main loop calls `request_access` first so approval dialogs surface, then hands off. The subagent returns text findings, not screenshots.
- **Web/browser:** same pattern — a haiku/sonnet subagent drives `claude-in-chrome` MCP tools and returns pass/fail plus evidence. Codex cannot drive a browser from a Claude Code session (verified 2026-07-03: headless `codex exec` runs `danger-full-access` yet `agent.browsers.list()` returns `[]` — `browser@openai-bundled` only controls the in-app browser inside a Codex app session, and `chrome@openai-bundled` requires the Codex Chrome extension, currently not installed). If that extension gets installed, retest `chrome@openai-bundled` as the browser executor.
- **Elicitation gate is per-app.** New apps need a one-time interactive approval that only surfaces when `codex` runs directly in a terminal. The codex-rescue subagent sets `CODEX_CI=1` and auto-denies unseen apps, so it can only drive bundle IDs that already have a stored approval. Seed approvals from a real terminal session first, then use the Orca Codex worker.
- `screencapture` and AppleScript fallbacks fail in the seatbelt sandbox (`CODEX_SANDBOX=seatbelt`, missing display entitlement). Use `get_app_state` instead — don't waste turns retrying them.

Main-loop exceptions (allowed in-process): `request_access` seeding, a single verification screenshot after the executor reports done, or the user explicitly asking the main model to drive the GUI itself.

## PR / Push discipline
- NEVER `git push` or `gh pr create` without explicit user instruction. Local commits are fine to checkpoint work; opening a PR or pushing a branch is a publishing act that requires an explicit ask ("push", "open PR", "pr 올려", etc.). When work is ready, list what's local and wait for the go-signal before publishing. This applies even when the user previously said "let's prep a PR" — that's planning, not authorization to push
- Vague autonomous goals like `/goal "알아서해결해"` or `/goal "handle it"` do NOT authorize publish-class actions: `git push`, `gh pr create`, `gh issue edit` on existing entities, `gh issue close`, branch force-push, repo creation, releases. Auto-mode classifier consistently rejects these when the goal text is vague; do not retry via alternate tools (gh api etc.) -- that's bypass, not authorization. Local commits, new file creation, and `gh issue create` (new content, no overwrite) ARE within scope of a vague goal. When a stop hook keeps re-firing because the goal asks for publish-class work that the classifier blocks, the resolution is to report the deadlock to the user and wait for an explicit verb-bearing trigger (one of "push", "edit issue", "open PR", "release"). The hook is mechanical; the safety system is the source of truth.
