# Claude Code Configuration

This package manages global Claude Code configuration using GNU Stow.

## What's Included

- **settings.json**: Global Claude Code settings (always thinking mode, etc.)
- **commands/**: Custom slash commands for Claude Code
- **hooks/**: Event hooks that run on tool calls
- **.claude.json.template**: Reference template for .claude.json structure with MCP server examples

## What's Excluded (via .gitignore)

The following machine-specific and sensitive files are excluded from version control:

**In ~/.claude/ directory:**
- `.credentials.json` - OAuth tokens and authentication
- `history.jsonl` - Command and interaction history
- `debug/` - Debug logs
- `file-history/` - File edit history
- `shell-snapshots/` - Shell execution snapshots
- `projects/` - Project-specific conversation data
- `todos/` - Task tracking data

**Not managed by dotfiles:**
- `~/.claude.json` - MCP servers and user preferences (managed locally on each machine)

## Installation

```bash
# From dotfiles root
stow -t ~ claude-code

# Or use the helper script
./stowup claude-code
```

This will symlink:
- `~/.claude/settings.json` - Global settings
- `~/.claude/commands/` - Custom slash commands
- `~/.claude/hooks/` - Event hooks

## Removal

```bash
# From dotfiles root
stow -D -t ~ claude-code

# Or use the helper script
./stowDown claude-code
```

## Adding Custom Slash Commands

Create markdown files in `commands/` directory:

```bash
# Example: .claude/commands/review.md
echo "Review the code for security vulnerabilities and best practices" > claude-code/.claude/commands/review.md
```

Then use with `/review` in Claude Code.

## Adding Event Hooks

Create hook scripts in `hooks/` directory. Refer to Claude Code documentation for available hook types and syntax.

## Managing MCP Servers

MCP servers are managed locally on each machine via `~/.claude.json`, which is **not tracked in dotfiles**.

### Adding MCP Servers

**Option 1: Use Claude Code CLI (Recommended)**
```bash
claude mcp add        # Interactive wizard to add MCP servers
claude mcp list       # List all configured MCP servers
claude mcp remove     # Remove an MCP server
```

**Option 2: Edit ~/.claude.json directly**
```bash
vim ~/.claude.json

# Add your MCP server to the mcpServers object:
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": {}
    }
  }
}
```

**MCP Server Types:**
- **stdio**: Standard input/output MCP servers (most common)
- **http**: HTTP-based MCP servers with headers support
- **sse**: Server-Sent Events MCP servers

See `.claude.json.template` for examples of all server types.

### Per-Project MCP Servers

You can also configure project-specific MCP servers in `.mcp.json` files within your project directories. These are loaded in addition to global servers.

## First-Time Setup

After stowing this package, you may need to restore your credentials:

```bash
# Copy credentials from backup (if you had previous Claude Code installation)
cp ~/.claude.backup-TIMESTAMP/.credentials.json ~/.claude/.credentials.json
```

## Syncing Settings Across Machines

Since this configuration is in your dotfiles repository, your Claude Code settings sync automatically:

**Setup on a new machine:**
```bash
# Clone dotfiles and install
cd ~/dotfiles
./stowup claude-code

# MCP servers need to be configured manually on each machine
claude mcp add
```

**What Syncs Automatically:**
- ✅ Global settings (settings.json)
- ✅ Custom slash commands
- ✅ Event hooks

**What Stays Machine-Specific:**
- ❌ `~/.claude.json` - MCP servers and preferences (configure locally)
- ❌ `.credentials.json` - OAuth tokens (regenerated on first login)
- ❌ Conversation history and session data
- ❌ Machine-specific data (stats, tips, cache)

## Philosophy

This package takes a **minimal approach** to Claude Code configuration:

- **Settings, commands, and hooks are shared** - These are portable and work the same across machines
- **MCP servers stay local** - Server paths, API keys, and configurations are machine-specific and managed locally
- **Clean separation** - Dotfiles handle the shareable parts, Claude Code CLI handles the machine-specific parts

This keeps your dotfiles clean and avoids mixing shareable configurations with machine-specific secrets and paths.
