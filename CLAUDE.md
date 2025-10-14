# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing development environment configurations across macOS and Linux systems. The repository uses symlinks to deploy configurations from this central location to their appropriate locations in the home directory.

## Installation and Setup Commands

```bash
# Full installation (symlinks + all tools)
./install.sh

# Individual installation functions
./install.sh create_symlinks  # Only create/update symlinks
./install.sh set_zsh          # Install Zsh, Oh My Zsh, and core tools
./install.sh set_mac          # macOS-specific tools (Rectangle, terminal-notifier)
./install.sh set_cloud        # AWS CLI and OpenTofu
./install.sh container        # Podman container runtime
```

## Architecture and Key Components

### Configuration Deployment
- All configs are stored in this repository and symlinked to home directory locations
- The `create_symlinks()` function handles all symlink creation, removing existing links first to prevent issues
- Claude configurations are symlinked from `claude/` to `~/.claude/`

### Cross-Platform Support
- The script uses `CHECK_OS=$(uname)` to detect the platform
- Package installations are separated: Homebrew for macOS, apt for Linux
- Homebrew is installed on Linux systems for consistent tool availability

### Shell Environment (zshrc)
- Uses Oh My Zsh with Powerlevel10k theme
- Key environment variables:
  - `DOCKER_HOST` points to Podman socket for Docker compatibility
  - Multiple development paths (Go, Cargo, pnpm, Android SDK)
- Custom aliases:
  - `docker=podman` for container compatibility
  - `terraform=tofu` for OpenTofu usage
  - Claude CLI shortcuts: `cc`, `cci`, `ccp`, `ccr`

### Claude Integration
The repository includes extensive Claude AI integration:
- Custom commands in `claude/commands/` for GitHub workflows
- Hooks in `claude/hooks/` that enforce GPG signing and provide notifications
- Personal preferences in `claude/CLAUDE.md` specify GPG signing requirements and no emoji preference

### The Scaffolding Problem
Scaffolding refers to predefined paths, rules, or frameworks built around a model to guide it toward accomplishing tasks. As model intelligence increases, scaffolding becomes a constraint that prevents the model from achieving its full potential - it "hobbles" the model.

**The Issue:**
- Rigid workflows stop developers from benefiting from new model capabilities
- Detailed checklists and step-by-step processes limit the model's reasoning ability
- Heavy frameworks become liabilities that hold back increasingly intelligent models

**The Solution:**
- As model intelligence increases, reduce scaffolding
- Trust the model to determine HOW to accomplish tasks
- Provide tools and goals, let the model use its autonomy and reasoning
- Focus on WHAT to accomplish and WHY it matters, not HOW to do it

**In Practice:**
- Replace numbered workflows with decision frameworks
- Eliminate prescriptive "do this then that" instructions
- Internalize checklists as principles rather than explicit steps
- Specify desired outcomes and quality standards, not processes
- Let the model leverage its contextual understanding and reasoning

## Development Guidelines

### Adding New Configurations
1. Add the configuration file to the repository
2. Update `create_symlinks()` in `install.sh` to include the new file
3. Test on both macOS and Linux if the configuration is cross-platform

### Modifying install.sh
- Always use `set -euo pipefail` for error handling
- Check `$CHECK_OS` before using platform-specific commands
- Use Homebrew for cross-platform tools when possible
- Keep functions modular for individual execution

### Container Usage
- Podman is the only container runtime (Docker removed)
- Docker commands are aliased to Podman for compatibility
- Podman socket provides Docker API compatibility

## Important Notes from Personal Preferences

From `claude/CLAUDE.md`:
- Always sign commits with GPG (`git commit -S`)
- No emojis in commits or code
- Prefer 'Replace ~' over 'Refactor: Replace ~' in commit messages