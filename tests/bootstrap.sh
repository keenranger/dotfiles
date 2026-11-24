#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin" "$test_root/home"
log_file="$test_root/commands.log"
touch "$test_root/keys.tar.gz.gpg"

cat > "$test_root/bin/sudo" <<'EOF'
#!/bin/bash
printf 'sudo'
printf ' %q' "$@"
printf '\n'
EOF
chmod +x "$test_root/bin/sudo"

cat > "$test_root/bin/sleep" <<'EOF'
#!/bin/bash
[ -z "${SLEEP_PID_FILE:-}" ] || printf '%s\n' "$$" > "$SLEEP_PID_FILE"
exec /bin/sleep 300
EOF
chmod +x "$test_root/bin/sleep"

cat > "$test_root/bin/brew" <<'EOF'
#!/bin/bash
if [ "${1:-}" = list ]; then
	exit 1
fi
{
	printf 'brew'
	printf ' %q' "$@"
	printf '\n'
} >> "$COMMAND_LOG"
[ "${3:-}" != broken-cask ]
EOF
chmod +x "$test_root/bin/brew"

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../install.sh
source "$repo_dir/install.sh"

original_exit_trap=$(trap -p EXIT)

set_zsh(){
	echo "set_zsh" >> "$log_file"
	run_privileged chsh -s /bin/zsh test-user >> "$log_file"
}

set_git(){
	echo "set_git" >> "$log_file"
}

create_symlinks(){
	echo "create_symlinks" >> "$log_file"
}

set_claude(){
	echo "set_claude" >> "$log_file"
}

set_codex(){
	echo "set_codex" >> "$log_file"
}

set_mac(){
	echo "set_mac" >> "$log_file"
}

set_gpg(){
	printf 'set_gpg %s %s\n' "$1" "$2" >> "$log_file"
}

(
	PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin \
		main bootstrap --gpg-backup "$test_root/keys.tar.gz.gpg"
	[ "$BOOTSTRAP_ACTIVE" = 0 ]
	[ -z "$SUDO_KEEPALIVE_PID" ]
) >> "$log_file"

[ "$(trap -p EXIT)" = "$original_exit_trap" ]
[ "$(grep -c '^sudo -v$' "$log_file")" -eq 1 ]
if grep '^sudo ' "$log_file" | grep -v -E '^sudo (-v|-n( |$))' >/dev/null; then
	echo "A privileged bootstrap command could prompt again" >&2
	exit 1
fi
grep -q '^sudo -n chsh -s /bin/zsh test-user$' "$log_file"

expected_order=$(cat <<EOF
set_zsh
set_git
create_symlinks
set_gpg restore $test_root/keys.tar.gz.gpg
set_claude
set_codex
set_mac
EOF
)
actual_order=$(grep -E '^(set_|create_)' "$log_file")
[ "$actual_order" = "$expected_order" ]

set_codex(){
	echo "set_codex" >> "$log_file"
	return 1
}

: > "$log_file"
(
	PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin \
		main bootstrap
) >> "$log_file" 2>&1
grep -q '^set_codex$' "$log_file"
if ! grep -q '^set_mac$' "$log_file"; then
	echo "A failed CLI install aborted the rest of the bootstrap" >&2
	exit 1
fi

set_codex(){
	echo "set_codex" >> "$log_file"
}

fail_bootstrap(){
	return 23
}

if PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin \
	with_sudo_session fail_bootstrap >/dev/null; then
	echo "A failed bootstrap callback was reported as successful" >&2
	exit 1
else
	[ "$?" -eq 23 ]
fi

sleep_pid_file="$test_root/sleep.pid"
wait_for_keepalive_sleep(){
	for _ in {1..100}; do
		[ -f "$sleep_pid_file" ] && return 0
		/bin/sleep 0.01
	done
	return 1
}

SLEEP_PID_FILE="$sleep_pid_file" PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin \
	with_sudo_session wait_for_keepalive_sleep >/dev/null
sleep_pid=$(cat "$sleep_pid_file")
if kill -0 "$sleep_pid" 2>/dev/null; then
	echo "The sudo keepalive sleep process survived cleanup" >&2
	kill "$sleep_pid" 2>/dev/null || true
	exit 1
fi

: > "$log_file"
(
	PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin main
) >> "$log_file"
if grep -q '^set_gpg ' "$log_file"; then
	echo "Bootstrap restored GPG without --gpg-backup" >&2
	exit 1
fi
[ "$(grep -c '^sudo -v$' "$log_file")" -eq 1 ]

: > "$log_file"
(
	PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin main install
) >> "$log_file"
[ "$(grep -c '^sudo -v$' "$log_file")" -eq 1 ]

set_codex_machine(){
	echo "set_codex_machine" >> "$log_file"
	run_privileged chsh -s /bin/zsh test-user >> "$log_file"
}

: > "$log_file"
(
	PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin main codex_machine
) >> "$log_file"
[ "$(grep -c '^sudo -v$' "$log_file")" -eq 1 ]
grep -q '^sudo -n chsh -s /bin/zsh test-user$' "$log_file"
grep -q '^set_codex_machine$' "$log_file"

: > "$log_file"
(
	PATH="$test_root/bin:$PATH" HOME="$test_root/home" CHECK_OS=Darwin main set_codex_machine
) >> "$log_file"
[ "$(grep -c '^sudo -v$' "$log_file")" -eq 1 ]

mkdir -p "$test_root/Applications/ChatGPT.app"
: > "$log_file"
if PATH="$test_root/bin:$PATH" COMMAND_LOG="$log_file" \
	DARWIN_APPLICATIONS_DIR="$test_root/Applications" \
	brew_install_casks chatgpt broken-cask final-cask >/dev/null; then
	echo "A failed cask install was not reported" >&2
	exit 1
fi
if grep -q 'brew install --cask chatgpt' "$log_file"; then
	echo "Preinstalled ChatGPT was installed again" >&2
	exit 1
fi
grep -q 'brew install --cask broken-cask' "$log_file"
grep -q 'brew install --cask final-cask' "$log_file"

grep -q '^[[:space:]]*chatgpt$' "$repo_dir/install.sh"
if grep -q '^[[:space:]]*codex-app$' "$repo_dir/install.sh"; then
	echo "Obsolete codex-app cask is still configured" >&2
	exit 1
fi

symlink_home="$test_root/symlink-home"
mkdir -p "$symlink_home/.config/nvim"
printf 'original zsh config\n' > "$symlink_home/.zshrc"
printf 'original nvim config\n' > "$symlink_home/.config/nvim/init.lua"
DOTFILES_BACKUP_DIR=
HOME="$symlink_home" create_shell_symlinks

[ -L "$symlink_home/.zshrc" ]
[ "$(readlink "$symlink_home/.zshrc")" = "$repo_dir/zshrc" ]
[ -L "$symlink_home/.config/nvim" ]
[ "$(readlink "$symlink_home/.config/nvim")" = "$repo_dir/config/nvim" ]
grep -q '^original zsh config$' "$DOTFILES_BACKUP_DIR/.zshrc"
grep -q '^original nvim config$' "$DOTFILES_BACKUP_DIR/.config/nvim/init.lua"

mkdir -p "$symlink_home/.claude" "$test_root/user-commands"
printf 'original Claude settings\n' > "$symlink_home/.claude/settings.json"
ln -s "$test_root/user-commands" "$symlink_home/.claude/commands"
HOME="$symlink_home" create_claude_symlinks
[ "$(readlink "$symlink_home/.claude/commands")" = "$test_root/user-commands" ]
grep -q '^original Claude settings$' "$DOTFILES_BACKUP_DIR/.claude/settings.json"

rm "$symlink_home/.claude/commands"
ln -s "$symlink_home/.codex/worktrees/old/dotfiles/claude/commands" "$symlink_home/.claude/commands"
HOME="$symlink_home" create_claude_symlinks
[ ! -L "$symlink_home/.claude/commands" ]

skill_home="$symlink_home/.codex/skills"
mkdir -p "$skill_home"
ln -s "$symlink_home/.codex/worktrees/old/dotfiles/agent/skills/a2a-agents" "$skill_home/a2a-agents"
HOME="$symlink_home" link_agent_skills "$skill_home"
[ "$(readlink "$skill_home/a2a-agents")" = "$repo_dir/agent/skills/a2a-agents" ]

backup_count_before=$(find "$DOTFILES_BACKUP_DIR" -mindepth 1 | wc -l | tr -d ' ')
HOME="$symlink_home" create_shell_symlinks
HOME="$symlink_home" create_claude_symlinks
backup_count_after=$(find "$DOTFILES_BACKUP_DIR" -mindepth 1 | wc -l | tr -d ' ')
[ "$backup_count_before" = "$backup_count_after" ]

# Existing aliases must be warned about, preserved on rerun, and reversible.
(
	HOME="$test_root/mixed-home"
	SRCDIR="$test_root/mixed-source"
	DOTFILES_BACKUP_DIR=
	mkdir -p "$HOME/.claude" "$HOME/.codex" "$SRCDIR/agent/global" "$SRCDIR/agent/skills"
	printf 'legacy instructions\n' > "$SRCDIR/agent/AGENTS.md"
	printf 'global instructions\n' > "$SRCDIR/agent/global/AGENTS.md"
	for path in .claude/CLAUDE.md .claude/AGENTS.md .codex/AGENTS.md; do
		ln -s "$SRCDIR/agent/AGENTS.md" "$HOME/$path"
	done
	create_claude_symlinks 2> "$test_root/mixed-warnings.log"
	create_codex_symlinks 2>> "$test_root/mixed-warnings.log"
	grep -Fq "Warning: preserving $HOME/.claude/AGENTS.md" "$test_root/mixed-warnings.log"
	[ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$SRCDIR/agent/global/AGENTS.md" ]
	[ "$(readlink "$HOME/.codex/AGENTS.md")" = "$SRCDIR/agent/global/AGENTS.md" ]
	[ "$(readlink "$HOME/.claude/AGENTS.md")" = "$SRCDIR/agent/AGENTS.md" ]
	before=$(find "$DOTFILES_BACKUP_DIR" -mindepth 1 | wc -l | tr -d ' ')
	create_claude_symlinks 2>> "$test_root/mixed-warnings.log"
	create_codex_symlinks 2>> "$test_root/mixed-warnings.log"
	after=$(find "$DOTFILES_BACKUP_DIR" -mindepth 1 | wc -l | tr -d ' ')
	[ "$before" = "$after" ]
	for path in .claude/CLAUDE.md .claude/AGENTS.md .codex/AGENTS.md; do
		ln -sfn "$SRCDIR/agent/AGENTS.md" "$HOME/$path"
		[ "$(readlink "$HOME/$path")" = "$SRCDIR/agent/AGENTS.md" ]
	done
	grep -q '^legacy instructions$' "$HOME/.claude/AGENTS.md"
)

# Detect unknown legacy changes in any section without mutating the checkout.
compatibility_fixture="$test_root/global-compatibility"
mkdir -p "$compatibility_fixture"/{agent/global,claude,tests,.github/workflows}
cp "$repo_dir/agent/AGENTS.md" "$compatibility_fixture/agent/AGENTS.md"
cp "$repo_dir/agent/global/AGENTS.md" "$compatibility_fixture/agent/global/AGENTS.md"
cp "$repo_dir/tests/global-instructions.sh" "$compatibility_fixture/tests/"
cp "$repo_dir/install.sh" "$compatibility_fixture/"
cp "$repo_dir/.github/workflows/enhance.yml" "$compatibility_fixture/.github/workflows/"
ln -s ../agent/AGENTS.md "$compatibility_fixture/claude/CLAUDE.md"
bash "$compatibility_fixture/tests/global-instructions.sh"
printf '\n## Unknown specialist policy\nUnreviewed constraint\n' >> "$compatibility_fixture/agent/AGENTS.md"
if bash "$compatibility_fixture/tests/global-instructions.sh" > "$test_root/drift.log" 2>&1; then
	echo "Unknown legacy specialist drift was accepted" >&2
	exit 1
fi
grep -q 'Legacy compatibility guidance changed' "$test_root/drift.log"
cp "$repo_dir/agent/AGENTS.md" "$compatibility_fixture/agent/AGENTS.md"
sed '/^- Instructions cannot override runtime permission controls/d' \
	"$repo_dir/agent/global/AGENTS.md" > "$compatibility_fixture/agent/global/AGENTS.md"
if bash "$compatibility_fixture/tests/global-instructions.sh" > "$test_root/login-policy.log" 2>&1; then
	echo "Missing runtime-grant login protection was accepted" >&2
	exit 1
fi
grep -q 'Missing login authorization safeguard' "$test_root/login-policy.log"

bash "$repo_dir/tests/global-instructions.sh"
echo "Bootstrap orchestration test passed"
