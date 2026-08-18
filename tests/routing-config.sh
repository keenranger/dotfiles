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
