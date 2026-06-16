---
name: web-verify
description: Analyze code changes, derive test scenarios, and verify them on a live deployment via browser automation. Use when user wants to verify changes work in the browser, test a deployment, or says /web-verify.
---

Verify code changes on a live deployment: $ARGUMENTS

## Phase 1: Analyze Changes

Run `git diff main --stat` and `git diff main` (excluding lockfiles) to understand what changed. Categorize changes into:

- **Dependency changes**: Which libraries were added/removed/upgraded? Where are they used in the codebase? (grep for imports)
- **Component changes**: Which components were modified? Which pages render them?
- **State management changes**: Which stores/atoms/contexts were affected? What data flows through them?
- **API layer changes**: Which API calls or hooks were affected?
- **Config changes**: next.config, tsconfig, env vars, etc.

## Phase 2: Derive Test Scenarios

For each change category, derive concrete user-facing test scenarios. Each scenario must include:
- **What to test**: a user action or page load
- **Why**: which change makes this test necessary
- **How to verify**: what to look for (element rendered, data loaded, no console errors, etc.)

Present the test list to the user and wait for approval before proceeding. The user may add, remove, or modify scenarios.

## Phase 3: Execute Tests

After approval, use Chrome browser automation (claude-in-chrome MCP tools) to execute each scenario:

### Setup
1. Read `credentials.json` from project root for login credentials (if it exists)
2. Read CLAUDE.md for deployment URLs (Dashboard URLs section)
3. Use the test/staging URL by default, unless the user specifies otherwise
4. Create a new tab and navigate to the deployment

### Per scenario
1. Perform the user action (navigate, click, select, etc.)
2. Take a screenshot
3. Read console messages for errors (use `read_console_messages` with pattern filter for errors/warnings)
4. Determine PASS/FAIL based on the verification criteria

### Resilience
- If chrome extension loses access (common with other extensions), ask the user to click the tab and retry
- If a scenario fails, continue with remaining scenarios (fail-forward)
- If credentials.json is missing, skip auth-dependent scenarios and inform the user

## Phase 4: Report

Summarize results:

| # | Scenario | Result | Notes |
|---|----------|--------|-------|

Include:
- Total pass/fail count
- Console errors found (if any)
- Screenshots taken for each step
- Recommendation: safe to merge or issues to fix
