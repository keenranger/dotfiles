# dotfiles

Personal dotfiles and shared agent configuration for local development machines.

## Layout

- `agent/AGENTS.md`: shared instructions for Codex, Claude Code, and similar coding agents.
- `agent/skills/`: shared workflow skills.
- `claude/`: Claude Code-specific settings, hooks, and agents.
- `install.sh`: modular setup and symlink installer.

## Common Commands

```bash
# Full personal-machine setup
./install.sh

# Refresh all symlinks
./install.sh create_symlinks

# Refresh only Codex shared instructions and managed skill links
./install.sh create_codex_symlinks

# Refresh only Claude Code shared instructions, skills, hooks, agents, and settings
./install.sh create_claude_symlinks
```

`create_codex_symlinks` links managed shared skills individually into `~/.codex/skills` so Codex-installed runtime skills and non-managed symlinks remain in place.
