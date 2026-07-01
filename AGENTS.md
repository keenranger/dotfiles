# AGENTS.md

This file provides guidance to coding agents when working in this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository for managing development environment configuration across macOS and Linux systems. Configurations are stored in the repository and deployed to home-directory locations with symlinks or managed copies where the consuming tool requires real files.

## Shared Agent Configuration

Shared agent rules and reusable workflow skills live under `agent/`:

- `agent/AGENTS.md`: canonical shared instructions for Codex, Claude Code, and similar coding agents.
- `agent/skills/`: shared skills that may be exposed to both `~/.codex/skills` and `~/.claude/skills`.
- `agent/hooks/`: shared hook scripts used by both Codex and Claude Code.

Tool-specific configuration stays under the tool directory:

- `claude/settings.json`, `claude/hooks/`, and `claude/agents/` are Claude Code-specific.
- `codex/hooks.json` is Codex-specific hook configuration installed to `~/.codex/hooks.json`.
- `codex/pets/` contains managed Codex pet packages that are safe to restore on new machines.
- Codex auth, sessions, caches, logs, memories, generated images, connector state, and runtime-installed skills are not dotfiles material and must not be copied into this repository.

## Installation Commands

```bash
# Full personal-machine installation
./install.sh

# Only update symlinks and managed Codex pet/hook copies
./install.sh create_symlinks

# Only update Claude Code symlinks
./install.sh create_claude_symlinks

# Only update Codex symlinks and managed pet/hook copies
./install.sh create_codex_symlinks

# Install shell/tooling support
./install.sh set_zsh

# macOS-specific tools
./install.sh set_mac

# Cloud tooling
./install.sh set_cloud

# Podman container runtime
./install.sh container
```

## Install Strategy

Claude and Codex share the same canonical instruction file:

```text
~/.claude/CLAUDE.md -> dotfiles/agent/AGENTS.md
~/.claude/AGENTS.md -> dotfiles/agent/AGENTS.md
~/.codex/AGENTS.md -> dotfiles/agent/AGENTS.md
```

Claude Code can use the shared skill directory directly:

```text
~/.claude/skills -> dotfiles/agent/skills
```

Codex keeps its own `~/.codex/skills` directory because Codex may install runtime or connector skills there. The installer links each managed shared skill individually and skips existing non-managed symlink or non-symlink skills unless their contents already match the repository copy.

Managed Codex pets are copied individually because Codex expects real pet package directories:

```text
~/.codex/pets/<pet-id>/pet.json
~/.codex/pets/<pet-id>/spritesheet.webp
```

The installer marks copied pets under `~/.codex/.dotfiles-managed-pets/` so later runs can update managed copies and remove stale managed copies after repository renames. Existing non-managed pet directories are skipped.

Generated pet run folders such as `~/.codex/pet-runs/` remain local artifacts and are not copied into this repository.

Shared hook scripts are copied into tool-owned directories rather than symlinked:

```text
~/.claude/agent-hooks/git-freshness.py
~/.codex/agent-hooks/git-freshness.py
~/.codex/hooks.json
```

The installer uses marker files under each tool directory so managed hook copies can be updated later without overwriting non-managed local hooks. Codex requires new or changed non-managed hooks to be reviewed and trusted with `/hooks` before they run.

## Development Guidelines

- Keep shared agent rules and shared skills in `agent/`.
- Keep Claude-only settings, hooks, and agents in `claude/`.
- Add reusable skills as `agent/skills/<name>/SKILL.md` with YAML front matter containing non-empty `name` and `description` fields.
- Do not add secrets, private keys, local auth files, Codex sqlite databases, logs, sessions, or generated runtime caches.
- When modifying `install.sh`, keep functions modular so individual setup steps remain callable.
