.DEFAULT_GOAL := install
SRCDIR := $(shell pwd)

copyfiles:
		@echo "copying files"
		
		@ln -s $(SRCDIR)/vimrc $(HOME)/.vimrc
		@ln -s $(SRCDIR)/tmux.conf $(HOME)/.tmux.conf
		@ln -s $(SRCDIR)/zshrc $(HOME)/.zshrc
		@ln -s $(SRCDIR)/config/nvim $(HOME)/.config/nvim
python:
		@sudo apt install -y python3-pip
		@pip3 install --user pipenv
		@sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev
		@curl https://pyenv.run | bash
