#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/home" "$test_root/bin"

cat > "$test_root/bin/curl" <<'EOF'
#!/bin/bash
set -euo pipefail

printf '%s\n' "$*" >> "$HOME/curl-calls"
case "$*" in
	*claude.ai/install.sh*)
		printf '%s\n' 'mkdir -p "$HOME/.local/bin"' ': > "$HOME/.local/bin/claude"' 'chmod +x "$HOME/.local/bin/claude"'
		;;
	*chatgpt.com/codex/install.sh*)
		printf '%s\n' '[ "${CODEX_NON_INTERACTIVE:-}" = 1 ]' 'mkdir -p "$HOME/.local/bin"' ': > "$HOME/.local/bin/codex"' 'chmod +x "$HOME/.local/bin/codex"'
		;;
	*)
		exit 1
		;;
esac
EOF
chmod +x "$test_root/bin/curl"

HOME="$test_root/home" PATH="$test_root/bin:$PATH" "$repo_dir/install.sh" set_claude
HOME="$test_root/home" PATH="$test_root/bin:$PATH" "$repo_dir/install.sh" set_codex

[ -x "$test_root/home/.local/bin/claude" ]
[ -x "$test_root/home/.local/bin/codex" ]
[ "$(wc -l < "$test_root/home/curl-calls" | tr -d ' ')" = 2 ]

HOME="$test_root/home" PATH="$test_root/bin:$PATH" "$repo_dir/install.sh" set_claude
HOME="$test_root/home" PATH="$test_root/bin:$PATH" "$repo_dir/install.sh" set_codex

[ "$(wc -l < "$test_root/home/curl-calls" | tr -d ' ')" = 2 ]

echo "Standalone CLI installation test passed"
