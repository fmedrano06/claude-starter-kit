# Customization

The starter kit is designed to be edited, not framework-locked. This
page explains where each piece lives and how to change it.

## The two layers of CLAUDE.md

Claude Code reads CLAUDE.md files from two places, and they compose:

| File | Scope | When to edit |
|---|---|---|
| `~/.claude/CLAUDE.md` | Global. Loads at the start of every session, in every directory. | Universal rules: how you want Claude to think, communicate, and behave. |
| `<project-root>/CLAUDE.md` | Project. Loads only when CWD is at or under that project root. | Project-specific facts: tech stack, conventions, invariants. |

The kit installs a global CLAUDE.md from `templates/CLAUDE.md.template`.
There is no project-level CLAUDE.md installed by default — that's for
you to add per project (the kit ships
`templates/project-CLAUDE.md.template` as a starting point if you want
one).

### Rule of thumb

A rule lives at the **broadest scope where it is still true**. If a
rule is true for everything you do, put it in the global. If it's only
true for one project, put it in that project's CLAUDE.md. Never
duplicate the same rule across scopes — duplicates rot independently.

### Editing the global CLAUDE.md

```bash
# macOS / Linux
$EDITOR ~/.claude/CLAUDE.md

# Windows
notepad $env:USERPROFILE\.claude\CLAUDE.md
```

You don't need to restart Claude Code — CLAUDE.md is re-read on every
new session. (For an already-open session, start a new one to pick up
changes.)

### Adding a project-level CLAUDE.md

From your project root:

```bash
cp <path-to-starter-kit>/templates/project-CLAUDE.md.template ./CLAUDE.md
$EDITOR ./CLAUDE.md
```

The template is intentionally small. Add only project-specific facts —
tech stack, deployment target, invariants Claude needs to respect.
Resist the urge to copy the global file's content here.

## Adding or removing plugins

Plugins are controlled by two arrays in `~/.claude/settings.json`:

```json
{
  "enabledPlugins": [
    "superpowers@claude-plugins-official",
    "cli-anything@cli-anything"
  ],
  "extraKnownMarketplaces": [
    "https://github.com/anthropics/claude-plugins-public",
    "https://github.com/HKUDS/CLI-Anything"
  ]
}
```

### To remove a plugin you don't want

1. Delete its entry from `enabledPlugins`.
2. Optionally run `/plugin uninstall <name>@<marketplace>` to remove
   the cached source from `~/.claude/plugins/`.

### To add a new plugin

1. Add the marketplace URL to `extraKnownMarketplaces` if not already
   present.
2. Add `"<name>@<marketplace>"` to `enabledPlugins`.
3. Restart Claude Code.

Alternatively, from inside a Claude Code session:

```text
/plugin install <name>@<marketplace>
```

This interactive command will offer to add the marketplace and update
your settings.

## Adding or removing skills

Skills bundled with the kit live in `~/.claude/skills/`. Each skill is
a directory containing at minimum a `SKILL.md` file with YAML
frontmatter that includes a `description`. Claude auto-discovers skills
in that directory.

### To remove a skill

```bash
rm -rf ~/.claude/skills/<skill-name>
```

### To add a skill

Either:
- Drop the skill's directory into `~/.claude/skills/`, or
- Install a plugin that ships skills (see [`plugins.md`](../plugins.md)).

A new skill becomes available immediately — no restart needed for
skills loaded from the user skill directory.

## Editing the memory layout

The auto-memory system is configured to write to:

```
~/.claude/projects/<cwd-slug>/memory/
```

Inside, you'll find:
- `MEMORY.md` — an index that loads at session start.
- Typed memory files: `user_*.md`, `feedback_*.md`, `project_*.md`,
  `reference_*.md`.

You can edit these files directly. Two practical tips:

1. **Keep `MEMORY.md` short** — only the first ~200 lines are loaded
   into context. Use it as a table of contents pointing at the typed
   files.
2. **Delete stale memories.** Wrong memories are worse than missing
   ones. If you spot one, delete it; Claude will write a new one when
   the topic next comes up.

## Editing hooks

Hooks live in `templates/hooks/` (copied into `~/.claude/hooks/` by the
installer). The default kit ships a statusline hook only — minimal by
design. To add your own, drop a script into the hooks directory and
reference it from `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "/path/to/script.sh" }] }
    ]
  }
}
```

See the official hooks reference at
https://docs.claude.com/en/docs/claude-code/hooks for the full event
list.

## Resetting to defaults

If you mess something up:

```bash
# from the cloned starter-kit repo
bash install/install.sh --force
```

The `--force` flag re-runs the installer without prompting, overwriting
your existing config with the kit's defaults. Your previous files are
backed up to `~/.claude/CLAUDE.md.backup-<timestamp>` etc.
