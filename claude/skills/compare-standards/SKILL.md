---
name: compare-standards
description: Compare implementation against internal standards. Use when comparing thresholds, checking compliance, or says /compare-standards.
argument-hint: "[area to compare, e.g. 'sleep evaluation boundaries']"
---

Compare implementation against standards: $ARGUMENTS

Read internal standards from skill files and reference docs, then compare against current implementation in config files or code.

Process:

- Identify relevant standard definitions (skill files, CLAUDE.md, reference docs)
- Locate current implementation (config files, code)
- Compare values and flag discrepancies

Output:

- Markdown table: Parameter | Standard | Current | Status
- Discrepancies with recommended fixes
- Optionally write results to file for cross-session reference

Goal: Surface gaps between defined standards and actual implementation.
