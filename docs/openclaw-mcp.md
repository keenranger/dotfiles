# OpenClaw MCP over Tailscale

Each computer runs a local **stdio** bridge. It connects over tailnet-only TLS WebSocket to the existing Gateway:

`MCP client -> bin/openclaw-mcp-tailnet -> wss://host.tailnet.ts.net -> Tailscale Serve -> loopback Gateway`

This is not a remote HTTP MCP endpoint. Do not register the WSS URL as an HTTP MCP server. Install a compatible OpenClaw CLI and Tailscale on every client; join the intended tailnet. Gateway pairing and channel permissions still apply. This does not grant arbitrary Slack API access.

## Gateway host (once)

Check `tailscale serve status` and the actual Gateway port first. Reuse an existing OpenClaw-managed Serve route when available. Otherwise an administrator can configure a dedicated unused HTTPS port, for example:

```sh
tailscale serve --bg --https=18790 http://127.0.0.1:18789
```

Use the actual Gateway port, not the example blindly. Preserve existing routes; do not use `serve reset`, public Funnel, or disable Gateway authentication. Restrict tailnet access to intended devices/users using tailnet policy. Roll back only a manually created route with `tailscale serve --https=18790 off`.

## Client setup (each computer)

From this checkout:

```sh
mkdir -p "$HOME/.local/bin" "$HOME/.config/openclaw-mcp"
chmod 700 "$HOME/.config/openclaw-mcp"
ln -s "$PWD/bin/openclaw-mcp-tailnet" "$HOME/.local/bin/openclaw-mcp-tailnet"
printf '%s\n' 'wss://YOUR-HOST.YOUR-TAILNET.ts.net:18790' > "$HOME/.config/openclaw-mcp/gateway-url"
```

If the launcher already exists, inspect it before replacing it. Securely provision the Gateway token into `~/.config/openclaw-mcp/gateway.token` using a password manager or protected local input; set mode `600`. Never paste it into chat, shell arguments, dotfiles, or PRs. The token grants Gateway authority, not necessarily read-only MCP access. Use only trusted MCP clients. A new computer may also need the normal Gateway device approval flow; do not bypass pairing.

The launcher also accepts `OPENCLAW_MCP_URL` and `OPENCLAW_MCP_TOKEN_FILE`. No credentials or host-specific connection settings are synced by this repository.

### Codex

```sh
codex mcp add openclaw-tailnet -- "$HOME/.local/bin/openclaw-mcp-tailnet"
```

### Claude Code

```sh
claude mcp add --transport stdio --scope user openclaw-tailnet -- "$HOME/.local/bin/openclaw-mcp-tailnet"
```

### Cursor / other stdio clients

Merge this entry into the client's existing MCP configuration, replacing the absolute path for that machine (do not overwrite other servers):

```json
{"mcpServers":{"openclaw-tailnet":{"command":"/ABSOLUTE/HOME/.local/bin/openclaw-mcp-tailnet","args":[]}}}
```

GUI clients must be able to resolve the `openclaw` executable via PATH. Standard MCP mode disables Claude-only notifications; opt in with `--claude-channel-mode on` only for a compatible client.

## Verification and removal

1. Check Tailscale connectivity and HTTPS certificate validation. An HTTP response alone does not prove authenticated MCP works.
2. Connect the client; verify MCP initialization and `tools/list`.
3. Run `conversations_list` with a small limit. Empty results may mean missing stored conversation routes; connection success does not prove channel history access.
4. Verify from a second tailnet computer before calling cross-machine access proven. Do not send messages as a smoke test.

Remove registrations using `codex mcp remove openclaw-tailnet` / `claude mcp remove --scope user openclaw-tailnet`. Remove only the launcher symlink and this host's local connection files when no longer used. Revoke/rotate credentials separately if needed.

Official reference: https://docs.openclaw.ai/cli/mcp/serve
