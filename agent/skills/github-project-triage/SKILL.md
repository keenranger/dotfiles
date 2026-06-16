---
name: github-project-triage
description: "Triage GitHub issues, pull requests, CI, releases, blockers, proof state, and next actions. Use for maintainer queue mapping, URL-first issue/PR cards, autonomous-vs-owner classification, PR readiness checks, and decision-ready briefs inside the fixed /Users/mark/src repository workflow."
---

# GitHub Project Triage

Map GitHub repository work into maintainer-grade item cards: URL, what it is, why it matters, fit, risk, proof, blocker, and next action.

This skill is adapted from `references/upstream-github-project-triage.md`. Load that reference only when updating the skill or resolving ambiguity about upstream behavior.

## Local Overrides

- In `/Users/mark/src`, broad orchestration scope is fixed to `ai`, `sleephub-android`, `hue-ble-android`, `listener-ai`, `healthdrop`, `actions`, and `internal-skills` unless Mark explicitly changes it.
- Do not broaden to owner/org-wide queues when used by `maintainer-orchestrator`.
- Do not require a checkout to be on `main` or clean before read-only triage; worker worktrees may be detached or carry local prepared patches. Record branch/status instead.
- Never switch branches, stash, reset, clean, push, edit GitHub entities, rerun CI, merge, close, or release unless the root instruction explicitly authorizes that action.
- For Android live proof, follow repo instructions and the `android-cli` skill. Use `android run --device=<serial> --apks=<path>` for app launch.

## Current Repo Triage

If the user says `triage` inside a repo, triage that repo only unless they ask for broad/all/cross-repo scope. Determine the repo with `gh repo view --json nameWithOwner` or the GitHub origin remote.

Start read-only:

```bash
git status --short --branch
gh issue list --repo "$repo" --state open --limit 50 --json number,title,author,labels,createdAt,updatedAt,url
gh pr list --repo "$repo" --state open --limit 50 --json number,title,author,isDraft,reviewDecision,mergeStateStatus,createdAt,updatedAt,url
```

For small queues, inspect every open item. For larger queues, inspect the top priority slice and state what was not expanded.

```bash
gh issue view <n> --repo "$repo" --json number,title,author,body,comments,labels,createdAt,updatedAt,url
gh pr view <n> --repo "$repo" --json number,title,author,body,comments,files,commits,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,createdAt,updatedAt,url
gh pr diff <n> --repo "$repo" --patch
```

Owner/maintainer comments are authoritative routing instructions. If there is no owner comment, say the triage call is maintainer judgment.

## Cross-Repo Queue Map

When used by the orchestrator, scan only the seven fixed repos. For each repo, collect:

- open issues and PRs;
- CI/check and mergeability state;
- latest release/tag and unreleased changelog or release notes;
- local branch/status and recent commits;
- package metadata and repo-specific docs/workflows when relevant.

Keep the scan lightweight. Deep source analysis belongs in the repo worker.

## Item Card Format

Use URL-first output. Every surfaced issue or PR starts with its full canonical GitHub URL.

For each expanded item include:

- `Title`: exact title.
- `Type`: issue, PR, dependency, CI, release, docs/internal, security, or product.
- `What/why`: what changes or is requested and why it matters.
- `Trust`: factual author signal when useful; do not treat trust as proof.
- `Fit`: good, mixed, or poor with one reason.
- `Risk`: low, medium, or high with blast radius.
- `Proof`: CI, local repro, failing test, live proof, artifact proof, or missing proof.
- `Blocker`: first concrete blocker, or `none`.
- `Next`: the next authorized action or exact owner decision.

For owner-facing decisions, convert item cards into decision-ready briefs instead of dumping raw triage.

## Classification

Classify items as:

- `Autonomous candidates`: bugfixes with inspectable root cause, small safe improvements, narrow docs/tests/CI fixes, low-risk dependency maintenance, or PRs that can be repaired and verified within granted permissions.
- `Needs owner`: product direction, security/privacy judgment, unavailable credentials/access, unavailable live proof, destructive/irreversible choice, publish permission, or explicit owner decision.
- `Defer/close/supersede`: duplicate, stale, overlapping, low-quality, or likely unwanted items, but only close/edit remotely with explicit authorization.

Do not mark an item ignored unless Mark explicitly named it as ignored for current work or release gating.

## Autonomous Fit Check

Before recommending an item as autonomous, verify:

- the item fits repo/product direction or existing behavior;
- the change is bounded and reviewable;
- the code path can be reproduced or inspected enough to establish root cause;
- there is a focused test or proof path;
- live/provider/device proof is available or the exact access blocker can be stated;
- no publish-class action is required beyond current authorization.

When uncertain, classify as `Needs owner` only after preparing all autonomous evidence possible.

## PR Readiness Check

For PRs that look mergeable or important:

1. Read discussion, files, commits, and status checks.
2. Inspect the diff, not only the PR description.
3. Reproduce/root-cause risky behavior when feasible.
4. Check tests, docs, changelog, package/release metadata, and consuming code when the change crosses boundaries.
5. Know mergeability and required CI state immediately before asking for owner action.
6. If the PR moved, refresh local work before asking for push/merge/land decisions.

Do not ask to land/delete with only a URL, label, or stale status.

## Trust Signals

For non-maintainer items, include factual author context when it changes review depth:

```text
Trust: @login; repo activity known/unknown; signal: maintainer / known contributor / bot / new drive-by / unknown.
```

Use available repo history, GitHub metadata, or local contributor notes if present. Trust changes scrutiny, not correctness.

## Output Sections

For plain triage, return:

- `Autonomous candidates`
- `Needs owner`
- `Defer/close/supersede`

For orchestrator reporting, use its sections instead: `Active`, `Intervened`, `Needs owner`, `Ignored`, `Released`, `Ready next`, `Skipped`.

Keep output concise but evidence-backed. Prefer one high-signal candidate with proof over a long list of unprepared links.
