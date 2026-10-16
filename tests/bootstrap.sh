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

# Isolate skill ownership cases from the checkout and the real user HOME.
(
	HOME="$test_root/skill-home"
	SRCDIR="$test_root/skill-source"
	DOTFILES_BACKUP_DIR=
	mkdir -p "$SRCDIR/agent/skills/shared" "$SRCDIR/agent/skills/divergent" \
		"$HOME/.agents/skills/divergent" "$HOME/.agents/skills/orchestration" \
		"$HOME/.codex/skills" "$test_root/foreign-skill"
	printf 'shared\n' > "$SRCDIR/agent/skills/shared/SKILL.md"
	printf 'canonical\n' > "$SRCDIR/agent/skills/divergent/SKILL.md"
	printf 'local\n' > "$HOME/.agents/skills/divergent/SKILL.md"
	printf 'instructions\n' > "$SRCDIR/agent/AGENTS.md"
	ln -s "$SRCDIR/agent/skills/removed" "$HOME/.agents/skills/removed"
	ln -s "$SRCDIR/agent/skills/removed" "$HOME/.codex/skills/removed"
	ln -s "$test_root/foreign-skill" "$HOME/.agents/skills/foreign"
	ln -s "$test_root/missing" "$HOME/.agents/skills/unowned-broken"
	ln -s "$SRCDIR/agent/skills/missing-other-name" "$HOME/.agents/skills/mismatched"
	ln -s "$HOME/.agents/skills/orchestration" "$SRCDIR/agent/skills/orchestration"
	# This ignored source mirrors local orchestration state and must not be pruned.
	git -C "$SRCDIR" init -q
	printf 'agent/skills/orchestration\nagent/skills/ignored-absent\n' > "$SRCDIR/.gitignore"
	ln -s "$SRCDIR/agent/skills/ignored-absent" "$HOME/.agents/skills/ignored-absent"
	create_codex_symlinks
	[ -L "$HOME/.agents/skills/ignored-absent" ]
	[ ! -L "$DOTFILES_BACKUP_DIR/.agents/skills/ignored-absent" ]
	for root in .agents .codex; do
		[ "$(readlink "$HOME/$root/skills/shared")" = "$SRCDIR/agent/skills/shared" ]
		[ ! -L "$HOME/$root/skills/removed" ]
		[ -L "$DOTFILES_BACKUP_DIR/$root/skills/removed" ]
	done
	[ ! -L "$HOME/.agents/skills/divergent" ]
	grep -q '^local$' "$HOME/.agents/skills/divergent/SKILL.md"
	[ "$(readlink "$HOME/.agents/skills/foreign")" = "$test_root/foreign-skill" ]
	[ -L "$HOME/.agents/skills/unowned-broken" ]
	[ -L "$HOME/.agents/skills/mismatched" ]
	[ -d "$HOME/.agents/skills/orchestration" ]
	[ ! -L "$HOME/.agents/skills/orchestration" ]
	# Also guard against self-links for a non-ignored canonical source.
	printf 'agent/skills/ignored-absent\n' > "$SRCDIR/.gitignore"
	link_agent_skills "$HOME/.agents/skills"
	[ ! -L "$HOME/.agents/skills/orchestration" ]
	before=$(find "$DOTFILES_BACKUP_DIR" -mindepth 1 | wc -l | tr -d ' ')
	create_codex_symlinks
	after=$(find "$DOTFILES_BACKUP_DIR" -mindepth 1 | wc -l | tr -d ' ')
	[ "$before" = "$after" ]
)

echo "Bootstrap orchestration test passed"
