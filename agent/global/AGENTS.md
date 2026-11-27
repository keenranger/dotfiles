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
- Infer the target from the request and workspace without widening scope. State material assumptions; they are not consent. Continue independent authorized work, but pause dependent changes when unresolved ambiguity materially changes the result or risks an irreversible action.
- Migration/lint/rename PRs: touch only required files. Do not reformat unrelated Python, Markdown or configs, refactor hook dependencies, or polish adjacent code. Propose broader work in one line and wait before editing it.

## Code Discipline
- State material assumptions and resolve routine choices from context. Ask when alternatives materially change scope, behavior, API compatibility, data handling, security, operating cost or major dependencies.
- Push back when a simpler approach exists; self-test: "Would a senior engineer say this is overcomplicated?"
- No feature flags or runtime switches (SSM/Parameter Store values, env toggles, default-off config) to gate new behavior. Ship the behavior itself through the normal PR and deploy order; express version or platform gating as code constants. Do not propose one unless the user asks for a flag
- Match existing style, even if you'd do it differently
- Every changed line must trace directly to the request
- Remove imports/variables your changes made unused, but leave pre-existing dead code alone
- Write documentation and comments in English unless told otherwise
- For vague tasks, define verifiable success criteria before writing code - prefer test-first: write a failing test, then make it pass
- For non-trivial implementation, briefly name the files and strategy, then proceed within authorization; complexity alone is not an approval gate. Analysis/review/planning does not authorize edits. Honor explicit checkpoints.
- User authorization persists across turns for the same ongoing task, within its authorized targets, actions, and conditions. Later user instructions can narrow or revoke it. Do not carry authorization from a completed task into new work unless the user explicitly granted standing authorization. Do not ask again solely because the turn or commit changed; reassess when scope or consequences materially change. Preserve publishing and destructive-action approval requirements and runtime permission controls
- If the user corrects the same kind of misinterpretation twice in one session, pause affected changes, name the pattern, and state the corrected interpretation. Resume without renewed approval when the correction is clear or verified; ask only about remaining material uncertainty and continue independent authorized work. Propose a permanent fix (AGENTS.md rule, memory entry, or skill update) immediately, but do not apply it without authorization for that persistent change. Do not defer the proposal to /wrap or a retrospective pass
- For generated images, pets, videos, or other visual artifacts, never state or imply the artifact exists until a generation/edit tool has returned a real result or a saved file has been verified. If the user asks to see an image, show the artifact or provide the verified path before describing it. If generation fails or returns no usable file, say that plainly and do not substitute a description for the missing output.

## Investigation Discipline
- Before claiming a symbol/function/file doesn't exist, search beyond the working tree: `git log --all -S '<name>' --source --remotes` and `git grep '<name>' $(git rev-list --remotes | head -200)`. `git grep` and Grep alone miss unmerged branches
- Don't assert plugin behavior, device models, library APIs, or UI element existence without confirming. Android device names come from `adb shell getprop ro.product.model`, not the serial prefix. UI claims need source-read or live app verification first

## Agents
- Routing preferences remain subordinate to actual tool contracts, task scope and runtime controls. Preserve every exact user-named model request; a fallback cannot fulfill it without owner acceptance. Dispatched workers must honor a no-delegation task contract.
- Research agent is the default for any exploration - external docs and internal codebase
- Use multiple agents in parallel when possible; keep instructions goal-oriented, not prescriptive

### Model routing
Shared principles (any runtime - Claude Code or Codex):
- Keep architecture/design, cross-cutting judgment and evidence integration in the main loop. Reviewers own bounded verdicts; the coordinator integrates the final task outcome. Delegate bulk reading, token-heavy sweeps and mechanical edits to cheaper agents that return findings only.
- Prefer Codex for user-facing coordination and bounded implementation ping-pong; use its configured model, raising effort only for justified risk, without hard-coding a Codex model name. In Claude Code, use Opus at high effort for coordination and judgment.
- Route substantial code reading, architecture and coding review to Claude Opus, whose bounded verdict the coordinator integrates. Keep small reads and tightly coupled decisions local when delegation costs more than it saves.
- GUI/computer use never runs in the main loop - see Computer Use / GUI Automation for executor routing (a separate Orca Codex worker for approval-seeded desktop and device work, haiku/sonnet subagents otherwise)

Orca cross-runtime sessions:
- Any ORCA_* worktree/terminal context (including ORCA_WORKTREE_ID or ORCA_TERMINAL_HANDLE) identifies an Orca session; do not require ORCA_WORKSPACE_ID, which is absent in some terminals.
- For independent work benefiting from a full visible Claude Code/Codex session, use Orca's native current-worktree terminal and orchestration: separate conversation context, shared checkout.
- Visible unsupervised companion: `orca terminal create --worktree active --title "CLAUDE: <task>" --command "ORCA_COMPANION=1 claude" --json` (or CODEX/codex). For result-returning work, load `orchestration` and use a supervised worker.
- In-process subagents, `claude -p` and `codex exec` are bounded delegation, not separate Orca sessions. Use an Orca worker when requested or when independently visible work benefits the task.
- Shared-worktree sessions may work in parallel only when they are read-only or their write scopes are explicitly disjoint. The coordinator owns architecture, integrates results, and prevents overlapping edits
- A session launched with `ORCA_COMPANION=1` must not launch another Orca companion. It completes its assigned task and reports back to the coordinator

Claude Code:

| Work | Required routing |
|---|---|
| Substantial code reading | When possible use a separate Opus research/Explore/general-purpose agent and consume its report. This overrides sonnet defaults for code-heavy deep dives, multi-file tracing and large diffs; sonnet remains for breadth/non-code research and haiku for mechanical scans. |
| Exploration and codebase analysis | Default to the research agent pinned to sonnet. |
| Built-in Explore/Plan/general-purpose | Unspecified models normally inherit the session model under runtime selection rules. Explicitly pass sonnet for token-heavy mapping/bulk/multi-location sweeps and haiku for mechanical scans, including skill-spawned agents and extra feature-dev/review agents. |
| Implementation | Proactively hand well-specified, self-contained tasks to write-capable codex:codex-rescue to conserve Claude quota, not only when stuck. Use a haiku wrapper to write the handoff, run Codex and relay results. Keep context-dependent work or tight iteration in the main loop or code-implementation (Opus). |
| New custom agents | Pin `model:` in frontmatter to sonnet unless Opus-level judgment is needed; unpinned agents otherwise inherit the session model under the runtime's selection rules. |

Codex:
- Downshift scoped token-heavy Codex one-shots and side tasks with `-m <cheaper model>` or `-c model_reasoning_effort=low|medium` rather than using the main interactive thread.
- For an independent Codex review pass, use one scoped `codex exec --ephemeral --sandbox read-only` with a prompt that forbids delegation. Do not use `codex review --uncommitted` while the installed `review` skill auto-activates inside that command; it recursively launches more review processes in the current runtime
- When Codex needs Claude judgment, use supervised Orca Claude workers: Opus provides bounded code evidence and a decision. Outside Orca, `claude -p --model opus` is a best-effort fallback only after confirming the CLI is installed/authenticated and child processes are permitted. Restrict it to read-only tools and label it `Non-Orca Claude one-shot`; it has no Orca visibility, lifecycle or result handoff and is neither a Codex-native agent nor a Claude-model MCP bridge. `claude mcp serve` exposes tools, not an Opus reviewer. On missing prerequisites or incomplete execution, report the missing role. An authorized Codex-only pass can add evidence, but cannot fulfill an exact user-named model request without owner acceptance.

### Review routing
- Small, low-risk, single-concern change: Opus reviews directly. Add a Codex pass only when requested or when independence materially improves confidence
- Large diffs, cross-subsystem changes, migrations, security, concurrency, persistence, release, or device-sensitive work: Opus reads the code, produces source-anchored evidence, evaluates correctness, and gives its bounded review verdict; Codex supplies an independent adversarial pass
- Review workers receive the target diff or exact file/range plus a bounded prompt. They must not invoke the shared `/review` skill from inside a review worker, which would recursively dispatch more reviewers
- Report which model roles actually ran. Never imply a Claude cross-check happened when the harness could not launch Claude or the call did not complete

### Real-device validation routing
- Opus defines device scenarios, acceptance criteria and the final pass/fail judgment; for substantial code reading, it first traces implementation and identifies observability points.
- A separate Orca Codex worker executes device and GUI actions. It must acquire the repository's serial-specific device lease before any mutable ADB, UI, BLE, install, permission, or app-data action, and release it when finished
- For development-stage apps owned by us, accepting the app's own required terms on test devices or test accounts is pre-authorized when needed for validation; do not pause for separate consent. This does not authorize third-party terms, production accounts, purchases, subscriptions, or unrelated permission grants
- Separate cold-start from warm-path checks. Keep build/install, launch, timed interaction, target-state UI/layout capture, visually checked same-state screenshots, logs/protocol evidence and reconnect/read-back as distinct gates where applicable.
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
- Korean IME: guard action-triggering Enter/Submit/key handlers with `e.nativeEvent.isComposing` in React Native or `e.isComposing` on web; otherwise Hangul composition can trigger mid-syllable and double-submit.
- SDK boundaries: when a library exports a discriminated identifier-union with a sibling brand mapper (e.g. `QuantityTypeIdentifier` + `UnitForIdentifier<T>`), encode the table as `as const satisfies readonly Generic[]` and wrap each row in a small helper `const m = <T extends ...>(x: Generic<T>): Generic<T> => x` so TS infers each row's specific `T` from the literal and enforces the (identifier, unit) correlation. A bare array literal widens `T` to the union and silently drops the per-row correlation. Don't reach for `as never` / `as unknown[]` at SDK boundaries when the lib already provides typed unions -- those casts are escape hatches that defeat exactly the typo-catching the lib was designed to give you

## Mobile Build Resources
- Default local work to source/configuration inspection, type checks, lint, targeted unit tests, and lightweight plist, manifest or archive preflight checks.
- When an EAS pipeline exists, use EAS Cloud (`eas build`, without `--local`) by default for full RN/native integration builds, native compilation, simulator binaries, archives and store binaries to conserve local disk space. Prefer an existing hosted build pipeline for other projects. A simulator-only target is still a native build; do not use it as an automatic local fallback when disk space is tight. Use a full local build only when explicitly requested or when a specific native diagnosis or compatibility proof cannot be obtained from the hosted pipeline; state that reason and check its disk requirements first.
- Preserve standalone native baseline branches. When native-only compatibility can change, verify one targeted clean native-only build, preferably hosted; integrated EAS success is not standalone-build, device or real-OAuth proof.
- Avoid repeating full builds across local, GitHub and EAS environments unless changed inputs, a failure or an unresolved verification gate justifies it. Keep required CI and release checks; do not retire a pipeline implicitly.
- Reuse validated artifacts/caches only with matching source and build inputs. Download only current validation needs, record provenance and preserve required evidence before proposing cleanup.
- Before heavy clone/install/build/archive work under disk pressure, inspect free space and scoped owned sizes, estimate scratch needs and defer if insufficient; do not invent universal thresholds.
- Cloud execution does not clean local worktrees, dependencies, caches or downloads. Identify local accumulation instead of retrying a space-bound operation.
- Cleanup requires explicit approval for exact paths, including disposable worktrees and generated artifacts. Present size, provenance, dirty state and active-use evidence; never delete source, signing material, secrets or datasets as an incidental build fix. Existing task-scoped authorization and publishing gates remain in force.

## Store release automation
- For documented App Store Connect/Google Play status, build selection/promotion, review submission and release operations, prefer official provider APIs/supported CLIs; use browser only for unsupported steps or interactive authentication. Verify current capabilities in official documentation; do not assume post-upload work always needs a console.
- Preserve the project's chosen build and upload pipeline (for example, EAS Cloud and EAS Submit). Where recurring post-upload work lacks automation, propose a small reviewed CLI/API integration instead of repeatedly handing console clicks to the user. Check existing authorized credential references first; if suitable authentication is unavailable, arrange the one-time scoped API-key or service-account setup. Never extract server-held credentials, print secrets, store keys in Git, or create new credentials without authorization.
- Reuse uploaded builds/version codes; never reupload just to promote or submit. Keep upload, review submission, approval and public availability distinct. Before mutations reconcile exact app/build, pending changes and release controls, preserving unrelated work. Check for an official final-publication API; otherwise use browser only for that step.
- API authentication does not override user authorization or runtime permissions. Continue already-authorized stages without duplicate consent, but never switch to a CLI/API or another executor to bypass an explicitly denied action. Do not promise full automation until the actual provider capabilities and authentication have been verified.

## Android
- Tablet 2 / 2번 태블릿: Samsung SM-X133, serial R8YL5098D7A (portrait 800×1340 verified 2026-11-12). R8YYB0Z4T4E is a different SM-X133. Target by serial, not enumeration or transport ID, and recheck model/orientation before device work.
- App launch on a device: `android run --device=<serial> --apks=<path>` (the `android` CLI from android-cli skill). Do NOT use `adb shell monkey -c LAUNCHER` or `adb shell am start` for launching the app.
- Export JAVA_HOME/ANDROID_HOME in every Gradle shell, which does not share prior tool-call env. On this Mac use Android Studio JBR and ~/Library/Android/sdk: `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ANDROID_HOME="$HOME/Library/Android/sdk" ./gradlew ...`. Alternatively set org.gradle.java.home in ~/.gradle/gradle.properties and sdk.dir in local.properties; prefer properties when invoking Gradle more than three times.
- Test cold-start (fresh launch, cleared data, no granted permissions) before warm paths: BLE, foreground-service, permission and lifecycle bugs may appear only there. Warm success is not cold-start evidence.
- Manifest merging preserves transitive maxSdkVersion permission caps even when the consumer omits them: a library cap of 30 silently removes the permission on API31+. Legacy-only library permissions should instead be consumer-declared; document unavoidable library caps loudly. For "permission not declared", inspect app/build/outputs/logs/manifest-merger-debug-report.txt and override caps with `tools:remove="android:maxSdkVersion"`.

## Kotlin
- Byte.toInt() sign-extends: 0x99 becomes -103 and `%02x` can print ffffff99. Mask with `and 0xff` for bit operations or hex formatting: `String.format("%02x", b.toInt() and 0xff)`.
- `Double.roundToInt()` / `Float.roundToInt()` throw `IllegalArgumentException("Cannot round NaN value.")` on NaN (±Infinity is safe -- it saturates to `Int.MAX_VALUE`/`MIN_VALUE`). Any value from a division whose denominator can vanish (e.g. McCamy CIE-xy->CCT `n = (x - 0.3320) / (0.1858 - y)` at `y == 0.1858`) must be `.isNaN()`-guarded before rounding.

## macOS
- TCC + iCloud Drive containers: `~/Library/Mobile Documents/iCloud~*/` is TCC-protected. Background processes (launchd agents, MCP servers, headless tools) launched outside an interactive Terminal with Full Disk Access typically cannot read it -- reads silently succeed with empty results, not an error. The naive workaround (launchd user agent that mirrors the container under the user's account) does NOT work: the agent inherits launchd's TCC attribution and also returns empty. Correct fix is a signed `.app` bundle holding `com.apple.developer.icloud-container-identifiers` matching the source container, reading via `URLForUbiquityContainerIdentifier` + `NSFileCoordinator` + `startDownloadingUbiquitousItem`, and re-exporting to a TCC-free path (e.g. `~/.healthdrop/`). See HealthDrop ADR-001 for the full rationale and the closed `keenranger/healthdrop-skills` PR #2 for the cautionary tale.
- Diagnose silent-empty TCC reads by running the same read from a Terminal (works) vs. via `osascript -e 'do shell script ...'` or a launchd-loaded agent (returns empty). If both fail, the consumer process needs its own entitlement, not FDA.

## Homebrew
- Homebrew tap repositories require a homebrew- prefix: `brew tap user/foo` resolves github.com/user/homebrew-foo, not a non-prefixed repo.
- For self-distributed apps below homebrew-core popularity/maintenance/use thresholds, use a private product tap `<user>/homebrew-<product>` with one Casks/<name>.rb or Formula/<name>.rb (e.g. hashicorp/homebrew-tap). Maintenance is a version/SHA bump per release.
- Automate tap bumps in release workflows with goreleaser (writes its own cask) or dawidd6/action-homebrew-bump-formula.

## Secrets
- Sentry DSN is safe to expose publicly - it only allows sending events, not reading data

## CI Review Bots
- `gemini-code-assist[bot]` re-emits its prior review comments on every push; if the same comments re-appear in CI monitor output after a fix push, confirm against the file content before treating them as new findings.

## Figma MCP
1. Follow the current Figma tool contract's required session/skill entry points, then get_metadata for XML structure (IDs, names, positions, sizes).
2. Use get_design_context for implementation details and data-annotations. Preserve both structure and annotations; follow any current tool-required order rather than assuming these two steps are the complete protocol.

Use both metadata and design context; the tool contract governs prerequisites.

### Implementation rules
- Implement supplied spacing/color/type values; separate extracted values from assumptions. Use project conventions for routine gaps and ask only about missing/conflicting values still material after applying the designated reference.
- Follow the user's designated reference; otherwise trust the user's screenshot over tool output when they conflict
- If Tailwind JIT fails to generate a class, use arbitrary values (`gap-[12px]`) or CSS variables immediately
- Visually compare the result to the design and report every design value used for owner verification.

## Computer Use / GUI Automation
GUI loops consume substantial context. Delegate them to cheaper executors and consume text summaries; the main model must NOT drive GUI loops in-process except the exceptions below. Executor preferences never override current tool contracts, required entry points/handoffs or runtime controls.

Executor routing:
- **Desktop/device, approval-seeded app:** a separate root-managed Orca Codex worker with the configured Codex default and computer-use@openai-bundled. Discover its current actions/observation contract rather than assuming a fixed nine-tool set or screenshot interface; use get_app_state where supplied. Consume its text/evidence instead of an in-session codex:codex-rescue GUI loop.
- **Desktop, unapproved app before denial or capability/transport failure without denial:** haiku (sonnet for judgment) drives the available mcp__computer-use__ tools discovered through ToolSearch. The main loop uses the documented approval entry point where available before handoff. Automatic denial remains denial, never permission to switch executors. Return text findings, not screenshots.
- **Web/browser:** haiku/sonnet drives claude-in-chrome tools and returns pass/fail plus evidence. The 2026-07-03 headless Codex-from-Claude probe found no browser surfaces; the Chrome-extension and in-app-browser restrictions were executor-specific evidence, not proof of current universal availability or absence. Discover current support; retest the Codex Chrome executor if the required extension becomes available.
- If Codex browser capability is unavailable or transport fails without a denial, use a supervised Orca Claude browser executor before declaring a blocker or asking for manual work. Verify its actual capabilities/result, not presumed parity with Codex. Login authorization's no-bypass rules still apply.
- **Per-app elicitation:** the earlier codex-rescue CODEX_CI=1 path auto-denied unseen apps and could drive only bundle IDs with stored approval. Do not send an unapproved app through that path unless its current documented contract provides an interactive approval surface and the applicable grant has been obtained. Before any denial, use that executor's documented interactive approval entry point when required (historically, direct terminal Codex provided seeding); proceed only with an applicable grant. After any automatic/explicit denial, preserve the blocker and use only the original executor's supported action-scoped grant mechanism; never switch executors or reclassify denial to bypass it.
- In the previously observed seatbelt sandbox (CODEX_SANDBOX=seatbelt, missing display entitlement), screencapture/AppleScript failed. Do not retry those same failed inputs; use the current supported observation contract, including get_app_state where supplied.

Main-loop exceptions: documented approval seeding (`request_access` only if that executor provides it), one verification screenshot after the executor finishes, or the user's explicit request for the main model to drive GUI.

## Login authorization
- Use `company-login` skill for company sign-in and account switching. When the user explicitly asks Codex to perform the login instead of Claude, honor that executor choice within actual runtime permissions and relay the verified outcome to the existing Claude task. If a prior action was denied, first present the exact app/origin, verified account, blocked action and required supported runtime approval; do not treat changing executors as a grant. Resume only after an actual grant applicable to that executor and action, then verify app sign-in and any separately requested Aterms record before reporting success. Keep the approval request concrete and singular rather than repeatedly asking the user to perform the login manually.
- Before committing to a provider-dependent release step, verify the required account and the executor's access to the exact provider origins. Distinguish missing user authorization, a runtime permission denial, and a transport failure; changing these instructions cannot grant runtime access.
- When an observed access gate requires user action, report the blocked origin/action and supporting evidence once, with the single next action needed. Preserve that blocker across turns, continue independent authorized work, and resume dependent work when the prerequisite changes. Do not repeat denied actions through another executor, repeat manual-switch requests, or promise release progress while the gate remains unchanged. Answer user-requested status checks concisely without presenting the unchanged blocker as new work.
- An explicit request to log in authorizes selecting the verified existing user/company account and confirming standard `openid`, `email`, and `profile` sign-in scopes for the requested app/origin. Continue without duplicate consent. It does not authorize purchases, provider/admin changes, broader OAuth scopes, unrelated external writes, credential extraction or secret storage.
- When sign-in requires switching accounts, use supported account-switching controls to select the verified existing company account before asking the user to do it; request user action only for an observed MFA, unavailable credential, or runtime permission gate, without extracting credentials or changing provider/admin settings.
- For company store-console work, including Google Play Console and App Store Connect, use the verified existing company account rather than a personal account. Inspect existing company browser sessions and perform supported account switching yourself within the authorized task; do not routinely hand account switching back to the user. Preserve runtime permission boundaries and unrelated accounts.
- Pass verbatim owner authorization and exact app/origin/account scope to browser executors and approval requests; coordinator "GO" is not direct user approval. Arrange any required manual handoff before a short-lived OAuth transaction.
- Instructions cannot override runtime permission controls or guarantee automatic approval. If a click is denied, stop that action. Before a manual handoff, the original executor must check for its documented action-scoped approval/elicitation mechanism and, when available, submit the user's renewed verbatim authorization and exact app/origin/account action through it. Continue only after an actual runtime grant; a chat instruction or configuration edit is not a grant. If the mechanism is unavailable or grants no access, preserve the blocker without restarting OAuth or repeatedly requesting manual clicks. Do not change permission settings, allowlists or classifiers, reword prompts to evade the denial, or retry through another executor.

## AUMS company sign-in
- Before reporting an AUMS login blocker, load `aums-login` skill and pass it to the browser executor. Check existing company browser profiles and authenticated AUMS tabs before asking the user to sign in; an unauthenticated profile or a Google email-entry page alone does not prove that user input is needed.
- Use authorized normal SSO, verified company selection and saved-login methods. Distinguish credential/MFA gates from transport failure; recover transport only through documented methods or a supported executor with changed inputs, preserving Login authorization's denial barriers and freshness guards. Never extract browser auth material or incidentally restart the browser.
- Continue independent authorized implementation/review/release while AUMS is blocked. Resume from the exact observed state when the prerequisite changes, without renewed authorization. Ask the user only at a step authorized tools cannot complete; login grants neither provider writes nor release-gate exemption.

## PR / Push discipline
- Attach real before/after screenshots directly to the GitHub PR description using GitHub-hosted attachments, preserving the existing description. Do not substitute a ZIP archive or a PR comment for the requested comparison. Never commit validation screenshots, images, or archives to the repository, including separate or orphan evidence branches; they add clutter and slow downloads. If supported attachment tooling is unavailable, report the concrete blocker instead of silently storing binaries in Git.
- Deployed changes must follow local review -> ordinary PR -> PR-head review/required checks -> exact committed PR head deployed to TEST and runtime-verified -> authorized merge -> merged revision deployed to LIVE and verified. Run targeted tests/lint/types earlier as needed; TEST means the deployed environment. Determine applicability from the project/tooling; never skip a requested gate. General deploy/go-live/handle-everything requests waive nothing; skipping a named gate requires explicit user instruction.
- Use the `release-flow` skill, resuming valid evidence and already-authorized stages without repeat approval per turn/commit/stage. The skill itself grants no missing PR, merge or deployment authority.
- Never deploy application changes from an uncommitted worktree. Never deploy directly from an unmerged feature branch to LIVE. Record the PR, tested commit, TEST deployment identity and verification, merge commit, and LIVE deployment identity. Do not remove the worktree until the source is preserved remotely and this chain is complete; an existing deployment is not a substitute for Git history.
- NEVER `git push` or `gh pr create` without explicit user instruction. Local checkpoint commits are fine. Prep a PR means prepare, not publish. If publishing was not requested, list local readiness and wait; when authorized, complete only that publishing action and necessary prerequisites within named scope/targets, without asking again.
- A request to push existing commits authorizes only those commits, not PR creation or unrequested commits. Publishing specified changes includes necessary commit/push, and requesting a PR includes its creation. Neither permits merge, release, force-push or unexpected destinations. Check remote state before retrying an uncertain publication.
- Vague autonomous goals like `/goal "알아서해결해"` or `/goal "handle it"` do not authorize external writes, including `gh issue create`. Publishing requires an explicit request or standing authorization naming the target and action; classifier acceptance is not user authorization. Do not retry denied actions through alternate tools or executors. Report blocked publishing and wait for the specific authorization while continuing independent local work.
- If a stop hook repeats denied or unauthorized publishing demands, report the deadlock once and wait for explicit action-specific user authorization and/or an actual supported runtime grant, as required. Neither replaces the other. Hook repetition grants no authority to retry or bypass through another executor.

## Mirakle on this Mac

- This Mac's default Gradle home automatically loads ~/.gradle/init.d/mirakle.gradle and ~/.gradle/mirakle/ helpers; alternate GRADLE_USER_HOME does not. Keep these machine-local routing instructions out of shared project docs.
- Ordinary non-empty wrapper tasks default to mirakle-sleephub, without project/Debug allowlists, using native rsync upload/remote Gradle/output download. Do not add per-build source hash manifests or generated-output scans.
- Run normal wrapper tasks (e.g. ./gradlew build), adding -x mirakle for local work. Empty/model/dry-run and native recursion/fallback behavior stay native/local; non-Gradle tools are outside this routing.
- Keep project-specific adaptation separate from global routing. Only the identified SleepHub app receives its existing runtime credentials and unsigned-Debug/local-signing hooks. Never send those credentials or certificate assumptions to other projects. Signing keys stay on the Mac. Other projects need their own remote-compatible JDK, SDK, dependencies and private-repository authentication; tasks requiring local devices or signing keys may need `-x mirakle`.
- Authentication uses the existing SSH key through the unlocked macOS SSH agent. If a background shell cannot authenticate, check `SSH_AUTH_SOCK` before changing keys or remote authorization. Never print credentials or place them in command-line arguments.
- Verified 2026-11-13: independent plain-Gradle remote build/repeat, local opt-out, native property preservation and mixed SleepHub Debug assemble/help with local signing. IDE, other Android/JDK/Gradle versions and Release/private signing remain unverified; no general speedup is established.

## SleepRoutine DB on this Mac

- SleepRoutine MySQL is reachable through the AWS Login app's local DB gateway (`dbgw`, Keycloak login; `"/Applications/AWS Login.app/Contents/Resources/bin/dbgw" list` shows connections): `sleeproutine-dev` at `127.0.0.1:15432`, `sleeproutine-live` at `127.0.0.1:15433`. Use it for DB lookups instead of extracting RDS credentials from Secrets Manager or opening SSM tunnels.
- The gateway injects authentication: connect with an empty user and no password. No local mysql client is installed; use `uv run -q --with pymysql python -I <script>`. Schemas are `user` and `money_sleep`; timestamps are UTC.
- The live session is `admin` with `@@read_only=0` (verified 2026-11-25), so it can write. Wrap every live session in `START TRANSACTION READ ONLY` ... `ROLLBACK`; live writes require explicit task-specific authorization. Select only the columns the task needs and avoid PII columns (email, subject, phone, payload) unless required.
