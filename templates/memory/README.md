# Auto-memory — what it is, how it works

Claude Code has a built-in memory system. Across sessions, Claude can
remember things about you, the project, and how you like to work — and
recall them in future conversations.

## How it works (in one paragraph)

Each memory is a small markdown file with YAML frontmatter, stored in this
directory. A top-level `MEMORY.md` file acts as an index: one line per
memory, pointing to the file. At the start of every session, Claude loads
`MEMORY.md` automatically. When something looks relevant, it opens the
underlying memory file. When you teach Claude something durable —
preferences, project context, gotchas — Claude writes a new memory file
and adds a line to the index.

## What gets saved

Four types of memory:

- **user** — your role, goals, knowledge, working style.
- **feedback** — corrections and confirmations. "Don't do X." "Yes, that
  approach was right." Includes *why*, so Claude can judge edge cases.
- **project** — ongoing work, decisions, deadlines, stakeholders.
- **reference** — pointers to external systems (Linear projects, Grafana
  boards, Slack channels).

## What does NOT get saved

- Code patterns, conventions, file paths — Claude reads the project to
  derive these.
- Git history, recent diffs — `git log` is authoritative.
- Debugging fixes — the fix is in the code; the commit message has why.
- Ephemeral session state (current task, current blocker).

## How to use it

You don't need to do anything. Claude builds memory as you work. To
nudge it:

- "Remember that X." — Claude writes a new memory file.
- "Forget Y." — Claude removes the relevant entry.
- "Ignore memory for this question." — Claude won't apply remembered
  facts to this turn.

## Inspecting memory

It's just markdown. Open any file. Edit it. Delete it. The next session
picks up whatever's there. If a memory is wrong, fix or delete it —
Claude trusts what it observes in the project over what memory says.

## Index size

`MEMORY.md` is loaded into Claude's context on every session. Keep it
concise — one line per memory, under ~150 chars per line, no more than
~200 lines total. Past that, lines get truncated.
