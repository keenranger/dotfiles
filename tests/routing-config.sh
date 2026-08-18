#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

require_text() {
	local needle=$1
	local file=$2

	if ! rg -Fq "$needle" "$file"; then
		echo "Missing routing policy in $file: $needle" >&2
		exit 1
	fi
}

require_section_text() {
	local heading=$1
	local needle=$2
	local file=$3
	local section

	section=$(awk -v heading="$heading" '
		$0 == heading { found = 1; next }
		found && /^##[#]? / { exit }
		found { print }
	' "$file")
	if ! rg -Fq "$needle" <<<"$section"; then
		echo "Missing routing policy under $heading in $file: $needle" >&2
		exit 1
	fi
}

if rg -n 'gpt-[0-9]' agent/AGENTS.md agent/skills/review claude; then
	echo "Shared configuration must not pin a Codex model name" >&2
	exit 1
fi

if rg -n 'CLAUDE_CODE_EFFORT_LEVEL|agent-hooks|statusLine' claude/settings.json; then
	echo "Claude settings contain runtime-owned state" >&2
	exit 1
fi

jq -e '
	.model == "claude-fable-5[1m]" and
	.effortLevel == "xhigh" and
	.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS == "1"
' claude/settings.json >/dev/null

rg -q 'Route substantial code reading to Claude Opus' agent/AGENTS.md
rg -q 'Route architecture, coding judgment, synthesis, and final verdicts to Claude Fable' agent/AGENTS.md
rg -q 'ORCA_WORKTREE_ID' agent/AGENTS.md
for routing_file in agent/AGENTS.md agent/skills/review/SKILL.md; do
	require_text 'claude -p --model opus' "$routing_file"
	require_text 'claude -p --model fable' "$routing_file"
	require_text 'best-effort one-shot' "$routing_file"
	require_text 'Codex runtime permits child processes' "$routing_file"
	require_text 'read-only tools' "$routing_file"
	require_text 'Non-Orca Claude one-shot' "$routing_file"
	require_text 'not a Codex-native agent or a Claude-model MCP bridge' "$routing_file"
	require_text 'claude mcp serve' "$routing_file"
done
require_text 'as the managed path:' agent/AGENTS.md
require_text 'managed cross-runtime path:' agent/skills/review/SKILL.md
require_text 'Treat any `ORCA_*` worktree or terminal context' agent/skills/review/SKILL.md
require_text '`ORCA_WORKTREE_ID` or `ORCA_TERMINAL_HANDLE`' agent/skills/review/SKILL.md
require_text 'Do not gate this decision only on `ORCA_WORKSPACE_ID`' agent/skills/review/SKILL.md
for routing_file in agent/AGENTS.md agent/skills/review/SKILL.md; do
	require_text 'orca worktree current --json' "$routing_file"
	require_text 'fallback signal' "$routing_file"
done
require_text '### Claude Code in Orca' agent/skills/review/SKILL.md
require_text '### Claude Code outside Orca' agent/skills/review/SKILL.md
require_text '### Codex in Orca' agent/skills/review/SKILL.md
require_text '### Codex outside Orca' agent/skills/review/SKILL.md
require_text 'Small LOCAL/PR: use a Fable verdict worker' agent/skills/review/SKILL.md
require_text 'Substantial LOCAL/PR: use an Opus evidence worker' agent/skills/review/SKILL.md
require_text 'then a Fable verdict worker' agent/skills/review/SKILL.md
require_text 'ISSUE: use a Fable verdict worker' agent/skills/review/SKILL.md
require_section_text '### Claude Code in Orca' 'dispatch a supervised Orca Codex worker' agent/skills/review/SKILL.md
require_section_text '### Claude Code in Orca' 'direct review only, read-only, do not load or invoke the shared review skill, and no delegation' agent/skills/review/SKILL.md
require_section_text '### Claude Code in Orca' 'Do not use codex:codex-rescue for this Orca-managed pass' agent/skills/review/SKILL.md
require_section_text '### Claude Code outside Orca' 'use codex:codex-rescue' agent/skills/review/SKILL.md
require_section_text '### Codex in Orca' 'worker-start --agent claude --model opus' agent/skills/review/SKILL.md
require_section_text '### Codex in Orca' 'worker-start --agent claude --model fable' agent/skills/review/SKILL.md
require_section_text '### Codex in Orca' 'direct review only, read-only, do not load or invoke the shared review skill, and no delegation' agent/skills/review/SKILL.md
require_section_text '### Codex in Orca' 'codex exec --ephemeral --sandbox read-only' agent/skills/review/SKILL.md
require_section_text '### Codex outside Orca' 'claude -p --model opus' agent/skills/review/SKILL.md
require_section_text '### Codex outside Orca' 'claude -p --model fable' agent/skills/review/SKILL.md
require_section_text '### Codex outside Orca' 'Codex-only; Claude cross-check unavailable' agent/skills/review/SKILL.md
rg -q 'serial-specific device lease' agent/AGENTS.md
rg -q 'Workers must not invoke `/review`' agent/skills/review/SKILL.md
require_text 'codex exec --ephemeral --sandbox read-only' agent/AGENTS.md
require_text 'codex exec --ephemeral --sandbox read-only' agent/skills/review/SKILL.md
rg -q 'recursively launches reviewers' agent/skills/review/SKILL.md

for agent_file in claude/agents/*.md; do
	sed -n '1,/^---$/p' "$agent_file" | rg -q '^model: (opus|sonnet|haiku|fable)$' || {
		echo "Claude agent is missing an explicit model: $agent_file" >&2
		exit 1
	}
done

echo "Routing configuration test passed"
