# Troubleshooting

The most common things that go wrong, and how to diagnose them. Issues
are grouped by symptom.

## Install issues

### The installer fails on Windows with a script-execution-policy error

PowerShell blocks unsigned scripts by default. Run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Then re-run `./install/install.ps1`. The `CurrentUser` scope means you
only change your account's policy, not the whole machine.

### The installer says "claude: command not found"

Claude Code isn't on your PATH (or isn't installed). On Path A and
Path C you need it pre-installed — see
https://docs.claude.com/en/docs/claude-code/quickstart. On Path B the
script should install it for you; if it didn't, run the install
manually and re-run `install.ps1`.

### The installer hangs on "Installing plugin X"

Plugin installs clone the marketplace's Git repo. If your network
blocks GitHub or you're behind a corporate proxy, the install will
stall. Set `HTTPS_PROXY` and `HTTP_PROXY` and rerun, or manually run
`git clone` of the marketplace repo first to confirm connectivity.

### The installer says my CLAUDE.md was backed up — where is it?

In `~/.claude/`, named `CLAUDE.md.backup-<timestamp>`. Same for
`settings.json.backup-<timestamp>`. To restore:

```bash
mv ~/.claude/CLAUDE.md.backup-<timestamp> ~/.claude/CLAUDE.md
```

## Plugin issues

### `/plugin list` is empty or missing a plugin

Three things to check, in order:

1. **Is the marketplace registered?** Run `claude marketplace list`.
   If a marketplace from [`../plugins.md`](../plugins.md) is missing,
   add it with `claude marketplace add <repo-url>` and restart Claude
   Code.
2. **Is the plugin in `enabledPlugins`?** Open
   `~/.claude/settings.json` and confirm
   `"<name>@<marketplace>"` is in the array.
3. **Did the install actually succeed?** Run
   `/plugin install <name>@<marketplace>` interactively. The output
   will tell you why it failed (network, missing dependency, etc.).

After fixing any of these, close all Claude Code sessions and open a
new one. Plugin lists are computed at session start.

### A plugin's skills aren't activating

Two common causes:

- **The skill's keywords don't match what you said.** Check the skill's
  `description:` field — that's what Claude matches against. Try
  rephrasing the request to include words from the description.
- **The plugin's `enabled` flag is off.** Run `/plugin list` and look
  for the plugin's status. If it shows `disabled`, run
  `/plugin enable <name>@<marketplace>`.

## MCP issues

### `/mcp` shows a server as "connecting" forever

Check the server's logs:

```bash
claude mcp logs <server-name>
```

Common causes:
- Missing required environment variable (e.g.
  `GITHUB_PERSONAL_ACCESS_TOKEN`). Set it and restart Claude Code.
- The MCP server's CLI is not installed. For `npx`-based servers, run
  the install command manually once (`npx -y <pkg>`) to make sure it
  succeeds and the binary is cached.
- Network blocked. If the server is HTTP-based (like `context7`),
  confirm `curl <url>` works.

### A `npx`-based MCP server keeps re-downloading on every session

That means npm's cache is being cleared between sessions, or you're
running on a system where `npx` defaults to `--ignore-existing`. Run
the package once with a pinned version (e.g.
`npx -y @modelcontextprotocol/server-github@latest`) so npm caches the
specific version.

### I added an MCP server but `/mcp` doesn't show it

Confirm the entry made it into `~/.claude/.mcp.json` (or wherever your
Claude Code version stores MCP config — check
`claude mcp list --json`). If the entry is there but `/mcp` is blank,
restart Claude Code.

## Memory issues

### Memory keeps growing — `MEMORY.md` is hundreds of lines

Two things help:

- Ask Claude to compress memory: invoke the `/dream` skill or say
  "consolidate my memory files and dedupe."
- Trim by hand. `MEMORY.md` is plain markdown. Delete entries that no
  longer reflect reality. The typed memory files in the same directory
  can be deleted or shortened too.

Stale memory is worse than missing memory. When in doubt, delete it.

### Claude is acting on a memory I never wanted saved

Find and delete it:

```bash
grep -ril '<phrase>' ~/.claude/projects/*/memory/
rm <matching-file>
```

Then ask Claude to confirm: "what do you remember about X?" If the
answer is still wrong, there may be additional matches — re-run the
grep.

## Behavioural issues

### Claude is being too verbose / chatty

Make sure your global `~/.claude/CLAUDE.md` actually loaded. Open a new
session and ask:
> what's in your global CLAUDE.md?

If Claude lists rules that don't match the template, the file may not
have been written or may have been overridden by a project-level
CLAUDE.md. Check both.

### Claude is committing without being asked

This is a settings-file issue, not a CLAUDE.md issue. Open
`~/.claude/settings.json` and check that `git commit` is not in any
auto-allow list. The default kit ships with no commits in
auto-allowed.

### Claude is asking too many questions

The opposite problem. If the global CLAUDE.md's "stop and ask" rule is
firing on tasks that should be trivial, soften it in your global
CLAUDE.md. The default template tries to balance asking on real
ambiguity vs. asking on every trivial change, but reasonable people
calibrate this differently.

## Last resort: reset to defaults

From the cloned starter-kit repo:

```bash
bash install/install.sh --force
```

This re-runs the installer non-interactively. Your previous files are
backed up to `*.backup-<timestamp>` so nothing is lost.

If even that fails, the most aggressive reset is:

```bash
mv ~/.claude ~/.claude.broken
```

then re-install Claude Code from scratch and re-run the starter-kit
installer. You can always copy memory files back from `~/.claude.broken/`
once things are working.
