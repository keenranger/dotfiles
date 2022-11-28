.DEFAULT_GOAL := install
SRCDIR := $(shell pwd)


shell:
		@/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
		@git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
		@/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		@brew install fzf
copyfiles:
		@echo "copying files"
		@ln -sf $(SRCDIR)/vimrc $(HOME)/.vimrc
		@ln -sf $(SRCDIR)/tmux.conf $(HOME)/.tmux.conf
		@ln -sf $(SRCDIR)/zshrc $(HOME)/.zshrc
		@ln -sf $(SRCDIR)/config/nvim $(HOME)/.config/nvim
font:
		@curl -L https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip -o D2Coding.zip
		@unzip D2Coding.zip