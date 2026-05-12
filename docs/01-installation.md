# Installation

The starter kit ships three installation paths. They all end at the
same place — a configured `~/.claude/` directory and (optionally) a
configured project. Pick the one that matches your situation.

## Prerequisites

- A POSIX shell (bash/zsh on macOS or Linux) or PowerShell 7+ on
  Windows.
- A working internet connection (the installer fetches plugins from
  their upstream marketplaces).
- For Paths A and C, **Claude Code** must already be installed. See
  https://docs.claude.com/en/docs/claude-code/quickstart for the
  official install instructions. Path B installs Claude Code for you.

## Path A — let Claude install it (recommended)

This is the smoothest path if Claude Code is already on your machine.

1. Clone or download this repo:
   ```bash
   git clone https://github.com/fmedrano/claude-starter-kit.git
   cd claude-starter-kit
   ```
2. Open Claude Code in that directory:
   ```bash
   claude
   ```
3. At the prompt, say:
   > **read SETUP.md and install the starter kit**

Claude will:
- Read `SETUP.md` (which is written specifically to be executed by an
  agent, not by a human).
- Read `install/lib/wizard-questions.json` and ask you each question in
  plain English — your name, preferred language, project directory,
  which optional MCPs you want, etc.
- Back up any existing `~/.claude/CLAUDE.md` and `~/.claude/settings.json`
  with timestamped `.backup-*` suffixes.
- Write the new files, install the plugins from their marketplaces, and
  tell you when the session can be restarted.

Why this path is preferred: Claude can ask follow-up questions, adapt
to your existing config, and explain what it's doing. The scripts in
Path B/C are non-interactive and assume defaults more aggressively.

## Path B — Windows, automated

For people setting up a fresh Windows machine. From the cloned repo:

```powershell
./install/install.ps1
```

What the script does:

1. Checks for Claude Code; if missing, runs the official installer.
2. Checks for Node.js (some MCP servers and plugin install paths need
   `npx`); installs if missing.
3. Backs up `~/.claude/CLAUDE.md` and `~/.claude/settings.json` to
   timestamped files if they exist.
4. Copies `templates/CLAUDE.md.template` to `~/.claude/CLAUDE.md`.
5. Copies `templates/settings.json.template` to
   `~/.claude/settings.json`.
6. Copies the bundled `skills/` into `~/.claude/skills/`.
7. Runs `claude marketplace add ...` for each of the six marketplaces
   referenced in [`../plugins.md`](../plugins.md).
8. Runs `/plugin install` for each of the nine plugins.

The script accepts the same answers as the wizard via flags — run
`./install/install.ps1 -Help` to see them. With no flags, it uses
sensible defaults.

## Path C — macOS or Linux, automated

From the cloned repo:

```bash
bash install/install.sh
```

Same behaviour as Path B but for `bash`/`zsh`. Run with `--help` to see
the available flags. The script is idempotent — re-running it picks up
where it left off and skips anything already done.

## Verifying the install

Once the installer finishes, restart Claude Code (close any open
sessions and open a new one). Then run:

```text
/plugin list
```

You should see all nine plugins from [`../plugins.md`](../plugins.md).
If any are missing, see [`04-troubleshooting.md`](./04-troubleshooting.md#plugin-not-listed).

To verify the configured MCP servers (only those you opted into during
the wizard will appear):

```text
/mcp
```

To verify your CLAUDE.md loaded, ask Claude a question and look for the
behavioral cues from `templates/CLAUDE.md.template` — Claude should
default to short, direct answers and surface assumptions before coding.

## Uninstalling

Everything the kit writes lives in `~/.claude/`. To revert:

1. Restore your backups:
   ```bash
   mv ~/.claude/CLAUDE.md.backup-<timestamp> ~/.claude/CLAUDE.md
   mv ~/.claude/settings.json.backup-<timestamp> ~/.claude/settings.json
   ```
2. Remove any skills you don't want:
   ```bash
   rm -rf ~/.claude/skills/<skill-name>
   ```
3. Uninstall plugins as desired:
   ```text
   /plugin uninstall <name>@<marketplace>
   ```

If you never had a pre-existing `CLAUDE.md` or `settings.json`, just
delete the ones the kit wrote.
