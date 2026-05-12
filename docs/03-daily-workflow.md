# Daily workflow

This page is the "how do I actually use this every day" guide. It
assumes the kit is installed and Claude Code is working.

## Starting a session

Open a terminal in the directory you want to work in and run:

```bash
claude
```

A few things happen automatically:

1. The global `~/.claude/CLAUDE.md` loads.
2. If a `CLAUDE.md` exists at the project root, it loads too.
3. The auto-memory system loads `MEMORY.md` for that directory if it
   exists.
4. The plugins from `enabledPlugins` activate and their skills become
   available.

You don't need to do anything special for these to happen — they're
configured in `settings.json` and just work.

## A typical task

A productive interaction looks like this:

1. **State the goal.** One sentence, plain English.
   > Add a debounced search input to the user list page.

2. **Let Claude push back.** If the request is ambiguous, the global
   CLAUDE.md tells Claude to ask before coding. Answer the question.

3. **Approve the plan if Claude offers one.** For any task touching
   more than ~2 files, Claude will sketch the change first. Skim it,
   approve or redirect.

4. **Watch the work happen.** Edits stream in. Claude tells you when
   it's done.

5. **Verify.** Run the code, look at the diff, test the feature. The
   CLAUDE.md sets the bar at "runs and works in practice," not
   "compiles cleanly."

6. **Commit (or ask Claude to).** Claude will not commit unless you
   ask. When you do ask, it will follow your repo's commit style.

## Useful slash commands you'll reach for

All of these come from the bundled plugins.

| Command | What it does | Plugin |
|---|---|---|
| `/plan` | Break a task into ordered, verifiable steps. | `agent-skills` |
| `/review` | Multi-axis code review of pending changes. | `agent-skills` |
| `/test` | Run TDD: failing test → impl → verify. | `agent-skills` |
| `/ship` | Pre-launch checklist for production deploys. | `agent-skills` |
| `/spec` | Start spec-driven development before coding. | `agent-skills` |
| `/init` | Generate an initial CLAUDE.md for a new project. | `claude-plugins-official` |
| `/security-review` | Security review of pending changes. | `claude-plugins-official` |
| `/loop` | Run a prompt on a recurring interval. | `claude-plugins-official` |
| `/schedule` | Schedule a remote agent to run on cron. | `claude-plugins-official` |

Run `/help` in a session to see every command available from the
plugins you have installed.

## When to use a skill vs. a slash command

- **Skills** activate automatically when their keywords appear in the
  conversation. You don't usually invoke them by name — you just talk
  about what you want and the right skill engages.
- **Slash commands** are deliberate. Use them when you want a specific,
  named workflow to run from a known starting point.

If a skill exists for what you want, prefer letting the conversation
trigger it. Reserve slash commands for repeatable rituals (review,
ship, plan).

## Working with memory

The auto-memory system writes durable observations on its own. You
don't need to manage it actively, but a few patterns help:

- **Ask Claude to remember.** "Remember that this project uses pnpm
  workspaces, not yarn." → Claude saves a `project_*.md` memory.
- **Ask Claude to forget.** "Forget what you remembered about the
  search field — we removed it." → Claude updates or deletes the
  relevant file.
- **Browse memories.** They're plain markdown files in
  `~/.claude/projects/<cwd>/memory/`. Edit them by hand if you want.

The first ~200 lines of `MEMORY.md` are loaded at every session start.
If that file gets long, ask Claude to clean it up — or invoke the
`/dream` skill from the bundled skills set, which is designed for
exactly that.

## Session handoffs

For non-trivial work, end the session by asking:

> write a handoff for this session

Claude will produce a short markdown document summarizing what was
done, what's still open, and any context the next session will need.
By convention, save it to `_session-handoffs/YYYY-MM-DD-HHMM-<slug>.md`
in your project root. The next session can be primed by saying "read
the latest session handoff and pick up from there."

## Things to avoid

- **Don't paste secrets** (API keys, tokens) into the chat unless you
  intend Claude to use them right then. They get embedded in the
  session transcript and may surface in future memory writes.
- **Don't ask Claude to refactor "everything"** as a single task. Big
  refactors should be planned, broken down, and shipped incrementally.
  Use `/plan` first.
- **Don't ignore Claude's questions.** The global CLAUDE.md tells
  Claude to ask before coding when assumptions are unclear. If you
  brush past a question, you'll get code that solves the wrong
  problem.
