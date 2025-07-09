#!/bin/bash
set -euo pipefail

SRCDIR=$(pwd)
CHECK_OS=$(uname)

create_symlinks(){
	echo "creating symlinks"
	ln -sf "$SRCDIR/vimrc" "$HOME/.vimrc"
	ln -sf "$SRCDIR/tmux.conf" "$HOME/.tmux.conf"
	ln -sf "$SRCDIR/zshrc" "$HOME/.zshrc"
	# Remove existing nvim symlink to prevent recursive linking
	[ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim"
	ln -sf "$SRCDIR/config/nvim" "$HOME/.config/nvim"
	# Claude configuration
	mkdir -p "$HOME/.claude"
	# Remove existing symlinks only if they exist
	[ -e "$HOME/.claude/CLAUDE.md" ] && rm -f "$HOME/.claude/CLAUDE.md"
	[ -e "$HOME/.claude/commands" ] && rm -rf "$HOME/.claude/commands"
	[ -e "$HOME/.claude/hooks" ] && rm -rf "$HOME/.claude/hooks"
	[ -e "$HOME/.claude/settings.json" ] && rm -f "$HOME/.claude/settings.json"
	# Create symlinks for all Claude files
	ln -sf "$SRCDIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
	ln -sf "$SRCDIR/claude/commands" "$HOME/.claude/commands"
	ln -sf "$SRCDIR/claude/hooks" "$HOME/.claude/hooks"
	ln -sf "$SRCDIR/claude/settings.json" "$HOME/.claude/settings.json"
}

set_zsh(){
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew install zsh
		brew install fzf ripgrep bat gh neovim
	else
		# Linux installation
		sudo apt update
		sudo apt install -y zsh build-essential curl neovim
		
		# Install GitHub CLI on Linux
		type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
		curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
		&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
		&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
		&& sudo apt update \
		&& sudo apt install gh -y
		
		# Install Homebrew on Linux
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		brew install fzf ripgrep bat
	fi
	
	# Common installations for both platforms
	chsh -s $(which zsh)
	/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
	/bin/sh -c "$(curl -fsSL https://astral.sh/uv/install.sh)"
	gh extension install github/gh-copilot
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
}

set_mac(){
	brew install --cask rectangle
	brew install terminal-notifier
}

set_cloud(){
	if [[ "$CHECK_OS" = "Darwin" ]]; then
		# macOS installation
		brew install awscli opentofu
	else
		# Linux installation
		# AWS CLI
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip awscliv2.zip
		sudo ./aws/install
		rm -rf aws awscliv2.zip
		# OpenTofu 
		curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
		chmod +x install-opentofu.sh
		./install-opentofu.sh --install-method deb
		rm install-opentofu.sh
	fi
}

container(){
	if [[ "$(uname)" = "Darwin" ]]; then
		# macOS installation
		brew install podman podman-compose
		podman machine init
		podman machine start
	else
		# Linux installation
		sudo apt-get update
		sudo apt-get install -y podman
		# Enable podman socket for Docker compatibility
		systemctl --user enable --now podman.socket
		# Install podman-compose via pip on Linux
		pip3 install --user podman-compose
	fi
}

if [ $# = 0 ]; then
	create_symlinks
	set_zsh
	if [[ "$CHECK_OS" = "Darwin"* ]]; then
		set_mac
	fi
else
	$1
fi

