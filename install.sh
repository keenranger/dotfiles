#!/bin/bash

SRCDIR=$(pwd)

create_symlinks(){
	echo "creating symlinks"
	ln -sf "$SRCDIR/vimrc" "$HOME/.vimrc"
	ln -sf "$SRCDIR/tmux.conf" "$HOME/.tmux.conf"
	ln -sf "$SRCDIR/zshrc" "$HOME/.zshrc"
	# Remove existing nvim symlink to prevent recursive linking
	[ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim"
	ln -sf "$SRCDIR/config/nvim" "$HOME/.config/nvim"
	mkdir -p "$HOME/.claude"
	ln -sf "$SRCDIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
	# Remove existing symlinks to prevent recursive linking
	[ -L "$HOME/.claude/commands" ] && rm "$HOME/.claude/commands"
	ln -sf "$SRCDIR/claude-commands" "$HOME/.claude/commands"
	
	# For hooks, remove existing and create symlink
	[ -e "$HOME/.claude/hooks" ] && rm -rf "$HOME/.claude/hooks"
	ln -sf "$SRCDIR/claude-hooks" "$HOME/.claude/hooks"
}

set_zsh(){
    sudo apt install zsh -y
    sudo apt install build-essential
    chsh -s `which zsh`
	/bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install fzf
	brew install ripgrep
	brew install bat
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
	/bin/sh -c "$(curl -fsSL https://astral.sh/uv/install.sh)"
	

    type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
    gh extension install github/gh-copilot

    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    sudo apt install neovim
}

set_mac(){
	brew install --cask rectangle
}

set_cloud(){
    # AWS Cli
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    # OpenTofu 
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb
    rm install-opentofu.sh
}

container(){
	brew install podman
	podman machine init
	podman machine start
	sudo apt-get update
	sudo apt install ca-certificates curl gnupg
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg

	# Add the repository to Apt sources:
	echo \
  		"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  		"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt update
	sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	sudo usermod -aG docker $USER
	sudo service docker restart
	# may need to be restarted
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

