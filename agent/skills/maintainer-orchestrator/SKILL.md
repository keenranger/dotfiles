---
name: maintainer-orchestrator
description: "Coordinate recurring maintainer orchestration in Codex across the fixed /Users/mark/src repos. Use for heartbeat/control-plane work, canonical repository worker threads, cross-repo queue monitoring, decision-ready owner briefs, live-proof gates, and release gating for ai, sleephub-android, hue-ble-android, listener-ai, healthdrop, actions, and internal-skills."
---

# Maintainer Orchestrator

Act as the root control plane. Inspect, triage, delegate to repository workers, monitor, ask owner decisions, and report. Keep substantial repository investigation, implementation, review, live proof, landing, and release execution in repository worker threads.

This skill is adapted from `references/upstream-maintainer-orchestrator.md`. Load that reference only when updating the skill or resolving ambiguity about upstream behavior.

## Local Overrides

These rules override the upstream defaults:

- Monitor only these repositories under `/Users/mark/src`: `ai`, `sleephub-android`, `hue-ble-android`, `listener-ai`, `healthdrop`, `actions`, and `internal-skills`.
- Do not add repositories from git history, adjacent worktrees, memory, ownership inference, or nearby activity unless Mark explicitly changes this fixed scope.
- Use one durable canonical repository worker thread per fixed repo. Do not create one worker per issue, PR, branch, or task.
- Keep work for one repo in that repo's canonical thread. If a task-specific thread already exists for a fixed repo, treat it as canonical unless it is clearly unusable or duplicate.
- Root owns thread lifecycle: create, reuse, fork, rename, archive, deduplicate, assign, and steer workers only from this coordinator.
- Workers must not create subworkers, delegate work, manage other chats, perform portfolio triage, or manage thread lifecycle.
- For `sleephub-android` and `hue-ble-android`, assume Mark's real SleepHub-connected setup/device is connected, permissioned, reachable, and available for ordinary non-destructive live proof unless a command proves otherwise.
- Push, PR creation/update, remote CI rerun/fix, merge, close, release, version bump, tag, registry publish, GitHub Release, destructive cleanup, account changes, firmware changes, purchase/payment actions, and broad data mutation all require explicit Mark approval.
- Do not review or monitor the X post that originally inspired this workflow. It is background only.

## Control-Plane Loop

On each heartbeat or orchestration turn:

1. Read the root-thread ledger: canonical repo thread ids, active items, completed work, blockers, ignored items, and pending owner decisions.
2. Sweep all seven fixed repositories every heartbeat at lightweight depth. A pending owner decision or active lane in one repo does not exempt the other repos from queue/status checks.
3. Assume a person or agent may have steered each worker since the last poll.
4. Before sending a worker message, read that worker's latest state, newest user/delegation messages, thread-local instructions, and active turn.
5. Classify each worker as active, completed, blocked, idle, out of scope, duplicate, or needing explicit permission.
6. Send nothing when an active worker has a coherent plan and is progressing.
7. Intervene only for explicit coordination requests, confirmed blockers, exhausted autonomous work, completed work needing a next lane, repeated failures with a concrete correction, wrong repo/item, unauthorized mutation, destructive action, security risk, release-gate violation, direct conflict with Mark's latest instruction, or gross task divergence.
8. If a repo thread is idle/completed, refresh that repo's current queue and do exactly one: assign the next autonomous item, prepare a decision-ready owner question, or document why no release/work is warranted.

Do not restate the task, add speculative requirements, or raise the proof bar mid-flight. Apply the live-proof gate from initial delegation.

## Queue Discovery

For each fixed repo, maintain a current queue from:

- open issues and PRs;
- CI/check state and mergeability;
- local git status, branch, remotes, and recent commits;
- latest release, package metadata, unreleased changelog, and release notes;
- repo-specific docs, scripts, and workflows.

Use `github-project-triage` for item cards and classification. Prefer GitHub connector or `gh`, native package managers, Gradle/npm/pnpm scripts, and existing workflows over custom scripts.

Classify every queue item:

- `Autonomous`: clear fit, reproducible or inspectable, bounded implementation, and usable verification path within granted permissions.
- `Needs owner`: product choice, security/privacy decision, unavailable credentials/access, unavailable live proof, destructive or irreversible choice, missing publishing permission, or a decision Mark must make.
- `Ignored by owner`: only an explicitly named item Mark says must not affect current work or release gating.

Do not treat draft, stale, difficult, platform-specific, failing, or annoying items as ignored.

## Worker Prompts

Every worker assignment must include:

- exact repo path and exact task;
- no-subdelegation and no-thread-lifecycle rules;
- granted permissions and explicit publish/destructive/release gates;
- relevant live-proof assumptions;
- expected final report fields: branch/head, files changed, proof commands, live evidence or waiver need, CI/mergeability if known, worktree status, and exact next permission.

Omit model selection so workers inherit the platform default. Rename a worker only when assigning or materially changing work. Use titles like `<Project>: <short current task>`.

## Decision-Ready Rule

Never ask Mark to decide from an unprepared issue, rough contributor branch, stale PR, red CI, bare URL, or status label.

- Existing PR: inspect discussion/diff, reproduce or root-cause when appropriate, repair or rewrite if needed, add tests/docs/changelog when relevant, run focused and broader tests, run live proof when applicable, run autoreview when warranted, and know CI/mergeability if authorized.
- Issue without PR: investigate root cause and constraints, implement the best bounded candidate locally when authorized, and drive it to the same proof state. Create/update a PR only when explicitly authorized.
- Product decision: choose a reversible default when technically safe and expose alternatives clearly.
- Access/live-proof blocker: finish all autonomous code, tests, docs, review, CI, and non-destructive live proof first where possible. Ask only for the exact remaining access step, waiver, or land/delete/close decision.

Owner decision briefs must include the full canonical URL/title, what changes and who benefits, why the decision is needed now, completed proof, material risks/tradeoffs, orchestrator recommendation, and exact choices.

## Live Proof Gate

Live proof is pre-land proof, not optional polish.

- Test the exact final candidate commit through the changed user path using the real built/installed artifact and real service, account, device, OS, provider, or external boundary when applicable.
- For `sleephub-android` and `hue-ble-android`, attempt ordinary non-destructive proof against the known SleepHub-connected setup/device before asking Mark to intervene.
- Docs, mocks, fixtures, protocol captures, route-existence checks, and CI supplement live proof; they do not replace it for runtime boundaries.
- Never infer a waiver from merge permission, release permission, prior contributor evidence, or confidence in mocks.
- Re-run live proof after any fix that changes the relevant runtime path.
- Pure docs, metadata, CI, or test-only changes with no runtime boundary may use closest built-artifact or workflow proof and state why no external boundary applies.

## Release Gate

Release only when Mark explicitly requests release execution for that repo.

Before tag/publish, compute:

```text
effective issues = open issues - explicitly ignored issues
effective PRs    = open PRs - explicitly ignored PRs
```

Release only when Mark authorized the release, effective queue is zero, every ignored item is explicitly named, required CI is green for the exact candidate, required live proof or waiver exists, checkout is clean/current, unreleased changes justify a release, and versioning follows project convention. Recheck GitHub queue and CI immediately before tagging or publishing.

## Reporting

Report meaningful changes, not routine wake-ups. Use these sections only when relevant: `Active`, `Intervened`, `Needs owner`, `Ignored`, `Released`, `Ready next`, `Skipped`.

Whenever mentioning an issue or PR in a report, decision question, worker message, or status update, print the full canonical clickable URL. Never use only `#123`.

For heartbeat responses, finish with the required heartbeat XML and choose `DONT_NOTIFY` when no user action is needed.
