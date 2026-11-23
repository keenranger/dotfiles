# dotfiles

Personal dotfiles and shared agent configuration for local development machines.

## Layout

- `agent/global/AGENTS.md`: shared instructions for Codex, Claude Code, and similar coding agents.
- `agent/skills/`: shared workflow skills.
- `codex/pets/`: managed Codex pet packages.
- `claude/`: Claude Code-specific settings, hooks, and agents.
- `config/`: Starship, Neovim, and Karabiner configuration.
- `gnupg/`: portable GnuPG agent and common configuration.
- `bin/`: reusable launchers such as the OpenClaw MCP tailnet bridge.
- `docs/`: setup guides for optional integrations.
- `tests/`: shell tests for the installer and routing configuration.
- `install.sh`: modular setup, symlink, and managed artifact installer.

## Common Commands

```bash
# Full personal-machine bootstrap (one administrator prompt)
./install.sh

# Bootstrap and restore a separate encrypted GPG credential backup
./install.sh bootstrap --gpg-backup /path/to/gpg-secret-keys-YYYYMMDDTHHMMSSZ.tar.gz.gpg

# Company Codex machine bootstrap without personal global Git identity
./install.sh codex_machine

# Refresh symlinks and managed Codex pet copies
./install.sh create_symlinks

# Refresh only Codex shared instructions, managed skill links, and managed pet copies
./install.sh create_codex_symlinks

# Refresh only Claude Code shared instructions, skills, hooks, agents, and settings
./install.sh create_claude_symlinks

# Write an encrypted, portable GnuPG backup to a private backup directory
./install.sh set_gpg backup /path/to/private/backup/dir

# Restore the backup on any machine with GnuPG installed
./install.sh set_gpg restore /path/to/gpg-secret-keys-YYYYMMDDTHHMMSSZ.tar.gz.gpg
```

Both full-machine profiles validate administrator access once with `sudo -v`, keep that timestamp alive only while the bootstrap process runs, and use non-interactive `sudo -n` for later privileged steps. The personal profile runs in this order: shell and tooling, global Git identity, dotfile symlinks, optional GPG restore, Claude Code, Codex CLI, and macOS apps including ChatGPT, then a short list of remaining sign-in and macOS permission steps. The GPG backup passphrase remains a separate prompt. Existing individual setup commands remain available for interactive use.

If `/Applications/ChatGPT.app` already exists, the installer skips its Homebrew cask and continues installing the other apps independently.

When a dotfile destination already contains a real file, directory, or different symlink, the installer moves it into a dated directory under `~/.dotfiles-backups/` before creating the managed symlink. Re-running against an already-correct managed symlink leaves it unchanged.

`create_codex_symlinks` links managed shared skills individually into `~/.codex/skills` and copies managed pets into `~/.codex/pets` so Codex-installed runtime skills, non-managed symlinks, and non-managed pet directories remain in place.

The full install profiles install both standalone agent CLIs. Run `./install.sh set_claude` or `./install.sh set_codex` to install only Claude Code or Codex CLI.

## Agent runtime boundaries

`agent/global/AGENTS.md` and `agent/skills/` contain the portable cross-harness routing policy. `claude/settings.json` contains the intentional Claude Code baseline and is linked into `~/.claude`; Claude Code and Orca may append machine-local UI, hook, and status-line state to that linked file. Preserve those live additions when reconciling checkouts, but do not commit Orca `agent-hooks` commands, `statusLine`, or machine-specific UI state.

Codex model selection, reasoning effort, MCP servers, connectors, approvals, sessions, and plugin caches remain host-local under `~/.codex`. Shared policy refers to the configured Codex default instead of pinning a model name that the repository does not control.

## Shell prompt and navigation

`set_zsh` installs [Starship](https://starship.rs/) and [zoxide](https://github.com/ajeetdsouza/zoxide). The tracked Starship configuration is linked to `~/.config/starship.toml` during `create_symlinks`.

- `z <query>` jumps to the highest-ranked matching directory.
- `zi <query>` selects a matching directory interactively with fzf.

`set_gpg backup` exports secret keys, public keys, owner trust, and revocation certificates in portable GnuPG formats, then encrypts the archive with AES256. Interactive backups ask for the existing GPG key passphrase twice and use that same passphrase to unlock every protected source key and encrypt the archive. All secret keys must share that passphrase; the backup fails instead of creating an incomplete archive when one does not. The recovery flow does not depend on a machine-local Keychain item. `GPG_BACKUP_PASSPHRASE` remains available for non-interactive automation.

`set_gpg restore` verifies the sibling `.sha256` file when present, decrypts the archive, and imports it into the current `GNUPGHOME`. It does not restore machine-specific GnuPG configuration or absolute symlinks. Backups created with the older `gnupg-home-v1` format remain supported.

## Optional OpenClaw MCP over Tailscale

See [cross-machine MCP setup](docs/openclaw-mcp.md). The tracked launcher is reusable; client registrations, Gateway URL, credentials, and pairing stay host-local.

## Global instruction loading

`agent/global/AGENTS.md` is the single compact global instruction source, with
all active policy inline and no imports or topical reference files. Running the
relevant installer commands immediately retargets `~/.claude/CLAUDE.md` and
`~/.codex/AGENTS.md` to it. The installer no longer creates `~/.claude/AGENTS.md`;
if that path already exists it warns and leaves it intact, potentially pointing
at a different legacy source. It never silently moves that alias. On this machine
the actual HOME transition is still pending approval: retarget the two links and
move only the `~/.claude/AGENTS.md` symlink to the dated backup as one unit.
Do not run the installer on the real HOME before that approval. Start a fresh
session after transition.

`agent/AGENTS.md`, repository-local `claude/CLAUDE.md` and repository AGENTS.md
are preserved for existing local consumers. Their old canonical wording is
historical; future global policy edits belong in `agent/global/AGENTS.md`.
`tests/global-instructions.sh` records the full legacy compatibility digest so
changes in any section require reconciliation with the active policy; update
that digest deliberately after review rather than copying historical wording
into the new source. Bootstrap tests and the enhance workflow run these checks.
The enhance workflow loads and proposes global edits to the new source only.
Runtime, MCP, authentication and permissions are unchanged.

Claude Code native AGENTS.md support scans project ancestors; it does not make
`~/.claude/AGENTS.md` a documented user-global entrypoint outside HOME. Keep
`~/.claude/CLAUDE.md` pointing to the one source for user-wide coverage.
The official memory guide documents deduplication of imports/symlinks; listed
paths alone do not measure repeated context or byte/token savings.
