---
name: wrap
description: Pre-commit session analysis. Triages trivial vs substantive changes, checks commit scope, and for substantive sessions proposes docs/permissions/automations updates. Use when user is finishing work, about to commit, or says /wrap.
context: fork
---

Pre-commit session analysis: $ARGUMENTS

## Step 1: Triage (always)

Assess the upcoming commit. Use `git diff --staged` (or unstaged if nothing staged).

**Trivial** (skip agent fanout):
- Single file, roughly under 20 lines changed
- No new dependencies, no new exported symbols, no new commands/skills/agents
- No new patterns worth persisting (typo fix, single value tweak, comment update, dependency bump)

If trivial, output one line: `Trivial change; nothing to wrap. Retry with WRAP_OK=1 prefix.` Skip steps 2-3.

**Substantive** proceeds to step 2.

## Step 2: Scope check (always)

Verify the diff matches a single intent:
- Flag unrelated reformatting, opportunistic cleanup, or edits in files not required by the stated task
- Migration / lint / rename PRs are especially prone to scope drift (see CLAUDE.md "Scope and Context")
- If scope drift suspected, surface `Diff touches X which seems unrelated to <stated intent>. Split into a follow-up commit?` and wait for confirmation before proceeding

## Step 3: Analysis (substantive only)

Run enhance agent (CLAUDE.md updates, automation opportunities, follow-ups). Pass session context.

After enhance completes, run permission analysis via the **built-in `fewer-permission-prompts` skill** (not the custom `permission-analyzer` agent -- the built-in is automode-aware and writes to project settings automatically).

Note: session-level retrospective analysis (course-corrections, ambiguity, missed efficiency) is **not** done here. The user's CLAUDE.md captures repeat-correction patterns in-session at the moment they occur; that obviates a post-hoc retrospective pass.

### Permission scope split

`fewer-permission-prompts` only touches project settings (`.claude/settings.json`). For commands that are generally useful across projects (git, pnpm, ruff, etc.), surface them as candidates for **user settings** (`~/.claude/settings.json`) manually -- ask the user before adding.

### Auto-mode permission framing

User runs in `defaultMode: "auto"`. Most commands execute silently, so a blanket "what ran in this session" list is no longer a useful whitelist signal. Meaningful signals only:
- Commands that **still** triggered a prompt despite automode
- Commands that required `dangerouslyDisableSandbox`
- Commands the user explicitly denied, then re-ran with adjustments
- New WebFetch domains that required approval

The built-in skill already filters for these. Skip proposals for commands that simply ran in auto.

## Focus areas

- Learnings: Technical discoveries, mistakes made, new patterns
- CLAUDE.md: Preferences or patterns worth persisting
- Permissions: Commands that bypassed normal flow (see auto-mode framing)
- Automation: Repetitive patterns that could become skills/commands/agents
- Follow-ups: Incomplete work, TODO markers, next session priorities
- Retrospective: User guidance patterns that could be improved
- Scaffolding cleanup: After exploration sessions, identify experiments whose purpose has resolved -- probe UIs, debug bridges, broadcast receivers, ad-hoc forward-synthesis helpers, intermediate analysis docs. Verify the final diff contains only what serves the stated request; flag scaffolding for removal in a follow-up commit before sending to reviewers.

## Duplicate check

- Before proposing, check both project (`.claude/`) and user (`~/.claude/`) locations
- Skip proposals that duplicate existing content

## Permission placement

- Project settings (`.claude/settings.json`) for project-specific permissions
- User settings (`~/.claude/settings.json`) for personal/global tools

## Output

- Triage result (trivial / substantive)
- Scope check result (clean / split suggested)
- Summary of session activity (substantive only)
- Categorized proposals (docs, permissions, automations) (substantive only)
- Follow-up tasks for next session
- Workflow suggestions (from retrospective)
- User selection: which proposals to apply

## User selection

- Present options via AskUserQuestion
- Options: update CLAUDE.md, add permissions, create automations, skip
- Execute only selected actions

Goal: Enrich configuration before each substantive commit; do not burn cycles on trivial ones.
