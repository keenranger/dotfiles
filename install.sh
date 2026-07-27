#!/bin/bash
set -euo pipefail

SRCDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHECK_OS=$(uname)
DARWIN_APPLICATIONS_DIR=${DARWIN_APPLICATIONS_DIR:-/Applications}

COMMON_BREW_PACKAGES=(
	zsh
	fzf
	ripgrep
	bat
	gh
	neovim
	tmux
	gnupg
	fnm
	pnpm
)

LINUX_BASE_APT_PACKAGES=(
	build-essential
	curl
)

DARWIN_BREW_PACKAGES=(
	pinentry-mac
	lazygit
)

DARWIN_FONT_CASKS=(
	font-meslo-lg-nerd-font
	font-d2coding-nerd-font
)

DARWIN_APP_CASKS=(
	google-chrome
	chatgpt
	ghostty
	rectangle
	karabiner-elements
	tailscale
	grandperspective
	rustdesk
)

DARWIN_CODEX_MACHINE_CASKS=(
	google-chrome
	chatgpt
	ghostty
	rectangle
	grandperspective
	rustdesk
)

CLOUD_BREW_PACKAGES=(
	awscli
	opentofu
)

DARWIN_CONTAINER_BREW_PACKAGES=(
	podman
	podman-compose
)

brew_install(){
	[ "$#" -eq 0 ] && return 0
	brew install "$@"
}

brew_install_casks(){
	[ "$#" -eq 0 ] && return 0
	local cask failed=0
	for cask in "$@"; do
		if [ "$cask" = "chatgpt" ] && [ -d "$DARWIN_APPLICATIONS_DIR/ChatGPT.app" ]; then
			echo "ChatGPT already installed, skipping"
		elif brew list --cask "$cask" >/dev/null 2>&1; then
			echo "$cask already installed, skipping"
		else
			brew install --cask "$cask" || failed=1
		fi
	done
	return "$failed"
}

BOOTSTRAP_ACTIVE=0
SUDO_KEEPALIVE_PID=
DOTFILES_BACKUP_DIR=${DOTFILES_BACKUP_DIR:-}

run_privileged(){
	if [ "$BOOTSTRAP_ACTIVE" = 1 ]; then
		sudo -n "$@"
	else
		sudo "$@"
	fi
}

stop_sudo_keepalive(){
	if [ -n "$SUDO_KEEPALIVE_PID" ]; then
		kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
		wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
		SUDO_KEEPALIVE_PID=
	fi
}

start_sudo_keepalive(){
	echo "Requesting administrator access for bootstrap..."
	sudo -v

	(
		sleep_pid=
		stop_keepalive_sleep(){
			if [ -n "$sleep_pid" ]; then
				kill "$sleep_pid" 2>/dev/null || true
				wait "$sleep_pid" 2>/dev/null || true
			fi
		}
		trap 'stop_keepalive_sleep; exit' TERM INT
		while true; do
			sleep 50 &
			sleep_pid=$!
			wait "$sleep_pid" || exit
			sleep_pid=
			sudo -n -v || exit
		done
	) &
	SUDO_KEEPALIVE_PID=$!
}

with_sudo_session() (
	BOOTSTRAP_ACTIVE=1
	start_sudo_keepalive
	trap stop_sudo_keepalive EXIT
	"$@"
)

ensure_homebrew(){
	if ! command -v brew &> /dev/null; then
		echo "Installing Homebrew..."
		if [[ "$CHECK_OS" = "Darwin" ]]; then
			if [ "$BOOTSTRAP_ACTIVE" != 1 ]; then
				echo "Requesting sudo access for Homebrew install..."
				sudo -v
			fi
		fi
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ "$CHECK_OS" = "Darwin" ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
		else
			eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		fi
	fi
}

backup_existing_path(){
	local path=$1
	local relative_path

	if [ -z "$DOTFILES_BACKUP_DIR" ]; then
		DOTFILES_BACKUP_DIR="$HOME/.dotfiles-backups/$(date -u +"%Y%m%dT%H%M%SZ")-$$"
	fi
	case "$path" in
		"$HOME"/*)
			relative_path=${path#"$HOME"/}
			;;
		*)
			relative_path=$(basename "$path")
			;;
	esac

	local backup_path="$DOTFILES_BACKUP_DIR/$relative_path"
	mkdir -p "$(dirname "$backup_path")"
	mv "$path" "$backup_path"
	echo "Backed up existing path: $path -> $backup_path"
}

replace_symlink(){
	local src=$1
	local dst=$2

	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		return 0
	fi
	if [ -L "$dst" ] || [ -e "$dst" ]; then
		backup_existing_path "$dst"
	fi
	mkdir -p "$(dirname "$dst")"
	ln -s "$src" "$dst"
}

replace_symlink_if_source_exists(){
	local src=$1
	local dst=$2

	if [ -e "$src" ] || [ -L "$src" ]; then
		replace_symlink "$src" "$dst"
	elif [ -L "$dst" ]; then
		case "$(readlink "$dst")" in
			"$SRCDIR"/*|"$HOME/.codex/worktrees"/*/dotfiles/*)
				rm -f "$dst"
				;;
			*)
				echo "Skipping existing non-managed symlink: $dst"
				;;
		esac
	fi
}

is_managed_skill_symlink(){
	local dst=$1
	local target
	target=$(readlink "$dst")

	case "$target" in
		"$SRCDIR/agent/skills"/*|"$SRCDIR/claude/skills"/*)
			return 0
			;;
		"$HOME/.codex/worktrees"/*/dotfiles/agent/skills/*|"$HOME/.codex/worktrees"/*/dotfiles/claude/skills/*)
			[ "$(basename "$target")" = "$(basename "$dst")" ]
			;;
		*)
			return 1
			;;
	esac
}

is_managed_codex_pet_symlink(){
	local dst=$1
	local name=${2:-}
	local target
	target=$(readlink "$dst")

	case "$target" in
		"$SRCDIR/codex/pets"/*)
			return 0
			;;
		*/codex/pets/*)
			[ -n "$name" ] && [ "$(basename "$target")" = "$name" ]
			;;
		*)
			return 1
			;;
	esac
}

managed_codex_pet_marker(){
	local name=$1
	printf "%s/.codex/.dotfiles-managed-pets/%s\n" "$HOME" "$name"
}

is_marked_managed_codex_pet(){
	local name=$1
	local marker
	marker=$(managed_codex_pet_marker "$name")

	[ -f "$marker" ] && [ "$(cat "$marker")" = "codex/pets/$name" ]
}

copy_codex_pet(){
	local src=$1
	local dst=$2
	local name
	local marker
	name=$(basename "$src")
	marker=$(managed_codex_pet_marker "$name")

	rm -rf "$dst"
	mkdir -p "$(dirname "$dst")" "$(dirname "$marker")"
	cp -R "$src" "$dst"
	printf "codex/pets/%s\n" "$name" > "$marker"
}

link_agent_skills(){
	local dst_dir=$1

	mkdir -p "$dst_dir"
	for src in "$SRCDIR"/agent/skills/*; do
		[ -e "$src" ] || [ -L "$src" ] || continue
		local name
		name=$(basename "$src")
		local rel="${src#"$SRCDIR"/}"
		if command -v git >/dev/null 2>&1 &&
			git -C "$SRCDIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
			git -C "$SRCDIR" check-ignore -q "$rel"; then
			continue
		fi
		local dst="$dst_dir/$name"

		if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
			replace_symlink "$src" "$dst"
		elif [ -L "$dst" ] && is_managed_skill_symlink "$dst"; then
			replace_symlink "$src" "$dst"
		elif [ -L "$dst" ]; then
			echo "Skipping existing non-managed skill symlink: $dst"
		elif [ -d "$dst" ] && diff -qr "$src" "$dst" >/dev/null 2>&1; then
			replace_symlink "$src" "$dst"
		else
			echo "Skipping existing non-symlink skill: $dst"
		fi
	done
}

prune_stale_codex_pets(){
	local dst_dir=$1
	local marker_dir="$HOME/.codex/.dotfiles-managed-pets"

	if [ -d "$marker_dir" ]; then
		for marker in "$marker_dir"/*; do
			[ -e "$marker" ] || continue
			local name
			name=$(basename "$marker")
			if [ ! -e "$SRCDIR/codex/pets/$name" ] && is_marked_managed_codex_pet "$name"; then
				rm -rf "$dst_dir/$name"
				rm -f "$marker"
			fi
		done
	fi

	for dst in "$dst_dir"/*; do
		[ -L "$dst" ] || continue
		local name
		name=$(basename "$dst")
		if [ ! -e "$SRCDIR/codex/pets/$name" ] && is_managed_codex_pet_symlink "$dst" "$name"; then
			rm -f "$dst"
		fi
	done
}

install_codex_pets(){
	local dst_dir=$1

	mkdir -p "$dst_dir"
	prune_stale_codex_pets "$dst_dir"
	for src in "$SRCDIR"/codex/pets/*; do
		[ -e "$src" ] || [ -L "$src" ] || continue
		local name
		name=$(basename "$src")
		local rel="${src#"$SRCDIR"/}"
		if command -v git >/dev/null 2>&1 &&
			git -C "$SRCDIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
			git -C "$SRCDIR" check-ignore -q "$rel"; then
			continue
		fi
		local dst="$dst_dir/$name"

		if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
			copy_codex_pet "$src" "$dst"
		elif [ -L "$dst" ] && is_managed_codex_pet_symlink "$dst" "$name"; then
			copy_codex_pet "$src" "$dst"
		elif [ -L "$dst" ]; then
			echo "Skipping existing non-managed Codex pet symlink: $dst"
		elif [ -d "$dst" ] && is_marked_managed_codex_pet "$name"; then
			copy_codex_pet "$src" "$dst"
		elif [ -d "$dst" ] && diff -qr "$src" "$dst" >/dev/null 2>&1; then
			copy_codex_pet "$src" "$dst"
		else
			echo "Skipping existing non-symlink Codex pet: $dst"
		fi
	done
}

create_shell_symlinks(){
	replace_symlink "$SRCDIR/vimrc" "$HOME/.vimrc"
	replace_symlink "$SRCDIR/tmux.conf" "$HOME/.tmux.conf"
	replace_symlink "$SRCDIR/zshrc" "$HOME/.zshrc"
	# Ensure .config directory exists
	mkdir -p "$HOME/.config"
	replace_symlink "$SRCDIR/config/nvim" "$HOME/.config/nvim"
	# macOS only configurations
	if [[ "$(uname)" = "Darwin" ]]; then
		mkdir -p "$HOME/.config/karabiner"
		replace_symlink "$SRCDIR/config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
		mkdir -p "$HOME/.gnupg"
		chmod 700 "$HOME/.gnupg"
		replace_symlink "$SRCDIR/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
		replace_symlink "$SRCDIR/gnupg/common.conf" "$HOME/.gnupg/common.conf"
	fi
}

create_claude_symlinks(){
	mkdir -p "$HOME/.claude"
	replace_symlink "$SRCDIR/agent/AGENTS.md" "$HOME/.claude/CLAUDE.md"
	replace_symlink "$SRCDIR/agent/AGENTS.md" "$HOME/.claude/AGENTS.md"
	replace_symlink "$SRCDIR/agent/skills" "$HOME/.claude/skills"
	replace_symlink_if_source_exists "$SRCDIR/claude/commands" "$HOME/.claude/commands"
	replace_symlink_if_source_exists "$SRCDIR/claude/hooks" "$HOME/.claude/hooks"
	replace_symlink_if_source_exists "$SRCDIR/claude/agents" "$HOME/.claude/agents"
	replace_symlink_if_source_exists "$SRCDIR/claude/settings.json" "$HOME/.claude/settings.json"
}

create_codex_symlinks(){
	mkdir -p "$HOME/.codex/skills" "$HOME/.codex/pets"
	replace_symlink "$SRCDIR/agent/AGENTS.md" "$HOME/.codex/AGENTS.md"
	link_agent_skills "$HOME/.codex/skills"
	install_codex_pets "$HOME/.codex/pets"
}

create_symlinks(){
	echo "creating symlinks"
	create_shell_symlinks
	create_claude_symlinks
	create_codex_symlinks
}

set_zsh(){
	ensure_homebrew

	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew_install "${COMMON_BREW_PACKAGES[@]}" "${DARWIN_BREW_PACKAGES[@]}"
		brew_install_casks "${DARWIN_FONT_CASKS[@]}"
	else
		# Linux installation
		run_privileged apt update
		run_privileged apt install -y "${LINUX_BASE_APT_PACKAGES[@]}"
		brew_install "${COMMON_BREW_PACKAGES[@]}"
	fi

	# Setup fnm with Node LTS
	eval "$(fnm env)"
	fnm install --lts
	fnm default lts-latest

	# Add zsh to /etc/shells if not present (fixes "non-standard shell" error)
	ZSH_PATH=$(command -v zsh)
	if ! grep -qx "$ZSH_PATH" /etc/shells; then
		echo "Adding $ZSH_PATH to /etc/shells"
		echo "$ZSH_PATH" | run_privileged tee -a /etc/shells
	fi
	if [[ "$SHELL" != "$ZSH_PATH" ]]; then
		if [ "$BOOTSTRAP_ACTIVE" = 1 ]; then
			run_privileged chsh -s "$ZSH_PATH" "$(id -un)"
		else
			chsh -s "$ZSH_PATH"
		fi
	fi

	# Install Oh My Zsh if not already installed
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		RUNZSH=no CHSH=no /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	# Install plugins/themes if not already present
	ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
	[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
	[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
	/bin/sh -c "$(curl -fsSL https://astral.sh/uv/install.sh)"
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

	# Configure brew autoupdate for daily automatic updates
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		mkdir -p "$HOME/Library/LaunchAgents"
		brew tap domt4/autoupdate
		brew trust domt4/autoupdate 2>/dev/null || true
		brew autoupdate delete >/dev/null 2>&1 || true
		brew autoupdate start 86400 --upgrade --cleanup --sudo
	fi
}

set_mac(){
	ensure_homebrew
	brew_install_casks "${DARWIN_APP_CASKS[@]}"
	brew_install terminal-notifier
	set_keyboard
}

set_codex_machine(){
	set_zsh
	create_symlinks
	set_claude
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		brew_install_casks "${DARWIN_CODEX_MACHINE_CASKS[@]}"
		brew_install terminal-notifier
	fi
}

set_keyboard(){
	# macOS only: Configure F18 as input source shortcut
	# NOTE: Adding input sources via defaults write is unreliable on modern macOS
	#       Add Korean (두벌식) manually: System Settings > Keyboard > Input Sources
	[[ "$(uname)" != "Darwin" ]] && return

	echo "Configuring keyboard shortcut..."

	# Set F18 (keycode 79) for "Select next source in Input menu" (hotkey ID 61)
	# Using PlistBuddy for correct types (defaults write creates strings instead of integers)
	# 8388608 (0x800000) is the fn key modifier required for F-keys on macOS
	local PLIST=~/Library/Preferences/com.apple.symbolichotkeys.plist
	/usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:61" "$PLIST" 2>/dev/null || true
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61 dict" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:enabled bool true" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value dict" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:type string standard" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters array" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters:0 integer 65535" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters:1 integer 79" "$PLIST"
	/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:61:value:parameters:2 integer 8388608" "$PLIST"

	# Apply changes instantly
	killall cfprefsd 2>/dev/null
	/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

	echo "F18 shortcut configured for input source switching."
}

set_cloud(){
	ensure_homebrew
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew_install "${CLOUD_BREW_PACKAGES[@]}"
	else
		# Linux installation
		# AWS CLI
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip awscliv2.zip
		run_privileged ./aws/install
		rm -rf aws awscliv2.zip
		# OpenTofu 
		curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
		chmod +x install-opentofu.sh
		./install-opentofu.sh --install-method deb
		rm install-opentofu.sh
	fi
}

set_claude(){
	if command -v claude &> /dev/null; then
		echo "Claude Code already installed, skipping"
		return 0
	fi
	echo "Installing Claude Code..."
	curl -fsSL https://claude.ai/install.sh | bash
}

set_git(){
	git config --global user.name "Hankyeol Kyung"
	git config --global user.email "kghnkl0103@gmail.com"
	echo "Git configured: Hankyeol Kyung <kghnkl0103@gmail.com>"
}

get_gpg_backup_passphrase() (
	{ set +x; } 2>/dev/null
	local mode=${1:-restore}

	if [ -n "${GPG_BACKUP_PASSPHRASE:-}" ]; then
		printf "%s" "$GPG_BACKUP_PASSPHRASE"
		return 0
	fi

	if [ -t 0 ]; then
		local passphrase confirmation
		read -r -s -p "GPG backup recovery passphrase: " passphrase
		echo >&2
		[ -n "$passphrase" ] || { echo "Empty passphrase is not allowed" >&2; return 1; }
		if [ "$mode" = "backup" ]; then
			read -r -s -p "Confirm GPG backup recovery passphrase: " confirmation
			echo >&2
			[ "$passphrase" = "$confirmation" ] || { echo "Passphrases do not match" >&2; return 1; }
		fi
		printf "%s" "$passphrase"
		return 0
	fi

	echo "No GPG backup passphrase available." >&2
	echo "Run this command interactively, or set GPG_BACKUP_PASSPHRASE for automation." >&2
	return 1
)

sha256_file(){
	if command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | awk '{print $1}'
	else
		sha256sum "$1" | awk '{print $1}'
	fi
}

verify_gpg_backup_checksum(){
	local backup_file=$1
	local checksum_file="$backup_file.sha256"

	if [ ! -f "$checksum_file" ]; then
		echo "Warning: checksum file not found: $checksum_file" >&2
		return 0
	fi

	local expected actual
	expected=$(awk 'NR == 1 {print $1}' "$checksum_file")
	actual=$(sha256_file "$backup_file")
	[ -n "$expected" ] && [ "$expected" = "$actual" ] || {
		echo "Error: GPG backup checksum mismatch: $backup_file" >&2
		return 1
	}
	echo "GPG backup checksum verified: $backup_file"
}

set_gpg_backup(){
	local dest_dir=${1:-}

	if [ -z "$dest_dir" ]; then
		echo "Usage: ./install.sh set_gpg backup DEST_DIR"
		return 1
	fi
	if [ -n "${2:-}" ]; then
		echo "set_gpg backup stores the current GnuPG key store; key selectors are not supported"
		return 1
	fi

	local key_count
	key_count=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^sec/{count++} END{print count+0}')
	[ "$key_count" -gt 0 ] || { echo "No GPG secret key found to back up"; return 1; }
	local gnupg_home
	gnupg_home=${GNUPGHOME:-$HOME/.gnupg}

	mkdir -p "$dest_dir"

	local tmpdir
	tmpdir=$(mktemp -d)
	(
		set -euo pipefail
		umask 077
		trap 'rm -rf "$tmpdir"' EXIT

		local payload_dir archive output checksum created_at host passphrase_file
		payload_dir="$tmpdir/payload"
		passphrase_file="$tmpdir/recovery-passphrase"
		mkdir -p "$payload_dir"
		get_gpg_backup_passphrase backup > "$passphrase_file"
		chmod 600 "$passphrase_file"

		gpg --batch --yes --armor --export > "$payload_dir/public-keys.asc"
		gpg --batch --yes --pinentry-mode loopback --passphrase-file "$passphrase_file" \
			--armor --export-secret-keys > "$payload_dir/secret-keys.asc"
		[ -s "$payload_dir/secret-keys.asc" ] || { echo "Failed to export GPG secret keys" >&2; exit 1; }
		gpg --export-ownertrust > "$payload_dir/ownertrust.txt"
		gpg --list-secret-keys --keyid-format=long > "$payload_dir/keys.txt"
		if [ -d "$gnupg_home/openpgp-revocs.d" ]; then
			mkdir -p "$payload_dir/openpgp-revocs.d"
			cp -a "$gnupg_home/openpgp-revocs.d/." "$payload_dir/openpgp-revocs.d/"
		fi

		created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
		host=$(hostname -s 2>/dev/null || hostname)
		{
			echo "created_at=$created_at"
			echo "host=$host"
			echo "format=gnupg-export-v2"
			echo "restore=./install.sh set_gpg restore BACKUP_FILE.gpg"
		} > "$payload_dir/metadata.txt"

		archive="$tmpdir/gpg-secret-keys.tar.gz"
		tar -czf "$archive" -C "$payload_dir" .

		output="$dest_dir/gpg-secret-keys-$(date -u +"%Y%m%dT%H%M%SZ").tar.gz.gpg"
		gpg --batch --yes --pinentry-mode loopback --passphrase-file "$passphrase_file" \
			--symmetric --cipher-algo AES256 \
			--output "$output" "$archive"

		checksum=$(sha256_file "$output")
		printf "%s  %s\n" "$checksum" "$(basename "$output")" > "$output.sha256"

		echo "Encrypted GPG backup written: $output"
		echo "Checksum written: $output.sha256"
	)
}

set_gpg_restore(){
	local backup_file=${1:-}

	if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
		echo "Usage: ./install.sh set_gpg restore BACKUP_FILE.gpg"
		return 1
	fi

	verify_gpg_backup_checksum "$backup_file"

	local tmpdir
	tmpdir=$(mktemp -d)
	(
		set -euo pipefail
		umask 077
		trap 'rm -rf "$tmpdir"' EXIT

		local archive payload_dir decrypt_home
		archive="$tmpdir/gpg-secret-keys.tar.gz"
		payload_dir="$tmpdir/payload"
		decrypt_home="$tmpdir/decrypt-gnupg"
		mkdir -p "$payload_dir"
		mkdir -p "$decrypt_home"
		chmod 700 "$decrypt_home"

		get_gpg_backup_passphrase restore | GNUPGHOME="$decrypt_home" gpg --batch --yes --pinentry-mode loopback \
			--passphrase-fd 0 --decrypt --output "$archive" "$backup_file"

		tar -xzf "$archive" -C "$payload_dir"
		if [ -s "$payload_dir/secret-keys.asc" ]; then
			local gnupg_home
			gnupg_home=${GNUPGHOME:-$HOME/.gnupg}
			mkdir -p "$gnupg_home"
			chmod 700 "$gnupg_home"
			if [ -s "$payload_dir/public-keys.asc" ]; then
				GNUPGHOME="$gnupg_home" gpg --batch --import "$payload_dir/public-keys.asc"
			fi
			GNUPGHOME="$gnupg_home" gpg --batch --import "$payload_dir/secret-keys.asc"
			if [ -s "$payload_dir/ownertrust.txt" ]; then
				GNUPGHOME="$gnupg_home" gpg --batch --import-ownertrust "$payload_dir/ownertrust.txt"
			fi
			if [ -d "$payload_dir/openpgp-revocs.d" ]; then
				mkdir -p "$gnupg_home/openpgp-revocs.d"
				cp -a "$payload_dir/openpgp-revocs.d/." "$gnupg_home/openpgp-revocs.d/"
				find "$gnupg_home/openpgp-revocs.d" -type f -exec chmod 600 {} +
			fi
			echo "Imported portable GnuPG backup into $gnupg_home"
		elif [ -d "$payload_dir/gnupg-home" ]; then
			local gnupg_home backup_existing item
			gnupg_home=${GNUPGHOME:-$HOME/.gnupg}
			backup_existing="$gnupg_home.pre-restore-$(date -u +"%Y%m%dT%H%M%SZ")"
			mkdir -p "$gnupg_home"
			chmod 700 "$gnupg_home"
			for item in "$payload_dir"/gnupg-home/*; do
				[ -e "$item" ] || continue
				if [ -e "$gnupg_home/$(basename "$item")" ] || [ -L "$gnupg_home/$(basename "$item")" ]; then
					mkdir -p "$backup_existing"
					mv "$gnupg_home/$(basename "$item")" "$backup_existing/"
				fi
				cp -aL "$item" "$gnupg_home/"
			done
			find "$gnupg_home" -type d -exec chmod 700 {} +
			find "$gnupg_home" -type f -exec chmod 600 {} +
			echo "Restored encrypted GnuPG key store backup to $gnupg_home"
			if [ -d "$backup_existing" ]; then
				echo "Previous GnuPG files moved to $backup_existing"
			fi
		else
			echo "Error: Invalid GPG backup format" >&2
			exit 1
		fi
	)

	set_gpg
}

set_gpg(){
	# Configure GPG for git commit signing (shared key approach)
	# Usage:
	#   ./install.sh set_gpg              - configure git with existing key
	#   ./install.sh set_gpg export --unsafe-plaintext
	#   ./install.sh set_gpg import FILE  - import key, trust, configure, delete file
	#   ./install.sh set_gpg backup DIR   - write encrypted key backup to DIR
	#   ./install.sh set_gpg restore FILE - restore encrypted key backup

	case "${1:-}" in
		backup)
			shift
			set_gpg_backup "$@"
			return $?
			;;
		restore)
			shift
			set_gpg_restore "$@"
			return $?
			;;
		export)
			if [ "${2:-}" != "--unsafe-plaintext" ]; then
				echo "Plaintext GPG export is disabled by default."
				echo "Use './install.sh set_gpg backup DIR' for an encrypted backup."
				echo "To force a raw private.key export, rerun with: ./install.sh set_gpg export --unsafe-plaintext"
				return 1
			fi
			KEY_ID=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk -F'/' '/^sec/{print $2}' | cut -d' ' -f1 | head -1)
			[ -z "$KEY_ID" ] && { echo "No key to export"; return 1; }
			gpg --export-secret-keys --armor "$KEY_ID" > private.key
			echo "Exported to ./private.key - transfer securely and delete"
			return 0
			;;
		import)
			[ -z "${2:-}" ] || [ ! -f "${2:-}" ] && { echo "Usage: set_gpg import FILE"; return 1; }
			gpg --import "$2"
			FINGERPRINT=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')
			echo "$FINGERPRINT:6:" | gpg --import-ownertrust
			rm -P "$2" 2>/dev/null || shred -u "$2" 2>/dev/null || rm "$2"
			echo "Key imported, trusted, file deleted"
			;;
	esac

	KEY_ID=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk -F'/' '/^sec/{print $2}' | cut -d' ' -f1 | head -1)

	if [ -z "$KEY_ID" ]; then
		echo "No GPG key found. Usage:"
		echo "  ./install.sh set_gpg import /path/to/private.key"
		return 1
	fi

	git config --global user.signingkey "$KEY_ID"
	git config --global commit.gpgsign true
	git config --global tag.gpgsign true
	git config --global gpg.program "$(command -v gpg)"

	gpgconf --kill gpg-agent

	echo "Configured signing with key: $KEY_ID"
	echo "Upload to GitHub: gpg --armor --export $KEY_ID | gh gpg-key add -"
}

container(){
	ensure_homebrew
	if [[ "$(uname)" = "Darwin" ]]; then
		# macOS installation
		brew_install "${DARWIN_CONTAINER_BREW_PACKAGES[@]}"
		podman machine init
		podman machine start
	else
		# Linux installation
		run_privileged apt-get update
		run_privileged apt-get install -y podman
		# Enable podman socket for Docker compatibility
		systemctl --user enable --now podman.socket
		# Install podman-compose via pip on Linux
		pip3 install --user podman-compose
	fi
}

usage(){
	cat <<'EOF'
Usage:
  ./install.sh                    Bootstrap a personal machine with one administrator prompt
  ./install.sh bootstrap [--gpg-backup FILE]
                                  Run the same bootstrap with an optional GPG restore
  ./install.sh codex_machine      Run the company Codex machine profile
  ./install.sh <command> [args]   Run one setup command

Commands:
  create_symlinks
  create_shell_symlinks
  create_claude_symlinks
  create_codex_symlinks
  set_zsh
  set_mac
  set_keyboard
  set_cloud
  set_claude
  set_git
  set_gpg [backup DIR|restore FILE|export --unsafe-plaintext|import FILE]
  set_codex_machine
  container
EOF
}

remaining_manual_actions(){
	cat <<'EOF'

Remaining manual actions:
  - Sign in to ChatGPT, Claude Code, GitHub, and Tailscale as needed.
  - Approve requested macOS privacy and security permissions.
  - Add Korean (두벌식) in System Settings > Keyboard > Input Sources.
EOF
}

personal_install(){
	local gpg_backup=$1

	set_zsh
	set_git
	create_symlinks
	if [ -n "$gpg_backup" ]; then
		set_gpg restore "$gpg_backup"
	fi
	set_claude
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		set_mac
	fi
	remaining_manual_actions
}

bootstrap(){
	local gpg_backup=
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--gpg-backup)
				[ "$#" -ge 2 ] || { echo "Missing file after --gpg-backup" >&2; return 1; }
				gpg_backup=$2
				shift 2
				;;
			*)
				echo "Unknown bootstrap option: $1" >&2
				return 1
				;;
		esac
	done

	if [ -n "$gpg_backup" ] && [ ! -f "$gpg_backup" ]; then
		echo "GPG backup not found: $gpg_backup" >&2
		return 1
	fi

	with_sudo_session personal_install "$gpg_backup"
}

codex_machine_install(){
	set_codex_machine
	remaining_manual_actions
}

bootstrap_codex_machine(){
	[ "$#" -eq 0 ] || { echo "codex_machine does not accept arguments" >&2; return 1; }
	with_sudo_session codex_machine_install
}

main(){
	if [ $# = 0 ]; then
		bootstrap
		return
	fi

	local command=$1
	shift
	case "$command" in
		default|install|bootstrap)
			bootstrap "$@"
			;;
		codex_machine|set_codex_machine)
			bootstrap_codex_machine "$@"
			;;
		create_symlinks|create_shell_symlinks|create_claude_symlinks|create_codex_symlinks|set_zsh|set_mac|set_keyboard|set_cloud|set_claude|set_git|set_gpg|container)
			"$command" "$@"
			;;
		help|-h|--help)
			usage
			;;
		*)
			echo "Unknown command: $command" >&2
			usage >&2
			return 1
			;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
