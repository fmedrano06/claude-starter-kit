# Your first guided session — second brain + first project

Welcome. This is a one-time guided session that takes about **30 minutes**.
By the end of it you will have two things on your machine that you do not
have today:

1. A **second brain** — an Obsidian vault, structured the way Andrej
   Karpathy organises his own notes, that Claude knows how to read and
   write to alongside you.
2. A **first coding project** — a small, finished, tested, committed
   piece of software built inside that vault using plan mode and the
   bundled skills end-to-end.

Both pieces are designed to keep working long after this session ends.
The vault becomes the home you return to every time you open Claude Code
on this machine. The project is a template you can copy for the next
ten, fifty, or five hundred things you build.

If you are reading this as Claude: walk the user through every step in
order. Ask confirmation before each filesystem write. Adapt the project
in Section 2 to whatever the user wants to build — do not force a
particular example.

If you are reading this as the user: paste this file's path into Claude
as your first message (`read ~/.claude/onboarding/first-session-prompt.md
and walk me through it`) and let Claude drive. You answer the questions
it asks. It writes the files.

---

## Section 1 — Set up your second brain (Obsidian)

A "second brain" is a folder of plain-text Markdown files that you and
Claude both edit, every day, forever. It is not a database, not a SaaS,
not a wiki engine. It is just a folder. That is the whole point: it
outlives any tool that opens it, and any tool that can read Markdown
can read it.

Obsidian is the recommended viewer because it is free for personal use,
renders `[[wiki-links]]` between notes natively, and stores everything
on disk in plain text. You can switch to another editor any day without
exporting or migrating.

### Step 1 — Install Obsidian

Go to **https://obsidian.md** and download the installer for your
operating system. Run it. The installer is small and the app is free
for personal use.

When Obsidian opens for the first time it will ask whether to create a
new vault or open an existing folder. Do not pick anything yet — close
that dialog. You will come back to it after the next step.

### Step 2 — Choose a folder on disk to be your vault

Pick a location on your machine where this vault will live. Suggested
names:

- `brain/` — short, neutral, what most people end up calling it.
- `vault/` — matches Obsidian's terminology if you prefer.

Suggested locations:

- `~/brain/` on macOS or Linux.
- `C:\Users\<you>\brain\` on Windows.
- Inside a cloud-synced folder (Dropbox, iCloud, OneDrive) if you want
  the same vault on multiple machines. Obsidian works fine inside any
  of these.

Avoid placing it inside an existing git repo unless you intend that
repo to *be* the vault. The vault will accumulate many small Markdown
files and you generally want it to be its own thing.

Create the folder now if it does not exist. Tell Claude the absolute
path. From here on we refer to it as `<vault-path>`.

### Step 3 — Open the folder as a vault in Obsidian

Switch to Obsidian. Click **"Open folder as vault"** and select the
folder you just chose. Obsidian will index it (instant for an empty
folder) and show you an empty workspace.

That is enough Obsidian setup for now. Leave it open in the background
— you will see notes appearing in its sidebar as Claude writes them.

### Step 4 — Open Claude Code in the vault

Open a new terminal window. Run:

```bash
cd <vault-path>
claude
```

Replace `<vault-path>` with the absolute path you picked in Step 2.
Claude Code starts in interactive mode. From this point forward every
piece of work you do with Claude in this folder will be logged into the
vault's structure.

### Step 5 — Create a project-level CLAUDE.md at the vault root

A `CLAUDE.md` file at the root of a folder is automatically loaded into
context every time Claude Code starts in that folder. We use this to
teach Claude the vault's three-folder structure and how to participate
in it.

Ask Claude to create `<vault-path>/CLAUDE.md` with the following
content. Confirm before writing.

```markdown
# Vault — second brain

This folder is a Karpathy-style "second brain". Three top-level
folders, used in a specific way:

- `raw/` — dumping ground. Drafts, screenshots, scratch, fragments,
  half-formed thoughts. Nothing here has to be finished, polished, or
  consistent. The only rule: one idea per file, kebab-case filenames.
- `wiki/` — codified articles. When a topic in `raw/` crystallises into
  something durable, promote it to `wiki/` with a clean title and
  proper structure. These notes are the long-term knowledge base.
- `outputs/` — finished deliverables. Decks, reports, scripts, posts,
  releases. Things that have a definite "done" state and a definite
  audience outside this vault.

## How Claude should behave inside this vault

When working in any subdirectory of this vault, you (Claude) must:

1. Write **atomic notes** — one idea per file, kebab-case filenames,
   no multi-topic dumps. If a note grows past one screen, split it.
2. Connect notes with `[[wiki-links]]` — every time a note mentions a
   concept that has (or could have) its own note, link it. Obsidian
   renders these as clickable links and surfaces backlinks
   automatically.
3. Maintain **daily notes** in `raw/daily/YYYY-MM-DD.md` — one entry
   per calendar day. Append a short summary at the end of every
   working session: what you worked on, what you learned, what is
   blocked, what to do next. Link related notes with `[[wiki-links]]`.
4. **Promote raw to wiki when it crystallises** — when you notice a
   topic in `raw/` has accumulated enough scattered notes to deserve
   one canonical article, propose a promotion: draft a `wiki/<topic>.md`
   that synthesises the raw notes, and link the originals into it.
   Do not delete the raw notes; they are the audit trail.
5. **Produce finished work in `outputs/`** — when a deliverable is
   ready to leave the vault (a deck to present, a report to send, a
   script to publish), write the final artifact under `outputs/` with
   a date prefix.

Always confirm before creating new files. Always show the path you
intend to write to before writing. Always link new notes back into the
graph — an orphan note that no other note references is a leak.

## Anti-patterns

- Do not nest topics deeper than two levels. The graph (wiki-links)
  carries structure, not the filesystem.
- Do not duplicate content across files. Link instead.
- Do not invent new top-level folders without asking. `raw/`, `wiki/`,
  and `outputs/` are the only canonical roots. `projects/` is allowed
  (see below) and so is `_archive/` for retired material.
- Do not modify wiki notes destructively. They are the long-term
  layer. Edit additively; surface contradictions as new sections.

## Projects subfolder

Coding projects built inside this vault live at
`projects/<project-name>/`. Each project is its own git repo (run
`git init` inside it). The vault itself is not a git repo — the per-
project repos keep each piece of work independent.
```

After writing the file, ask Claude to confirm it can read the file back
and that the path is `<vault-path>/CLAUDE.md`. Tell Claude to remember
this file will load automatically on every future session in this
folder — that is the whole point.

### Step 6 — Create the three folders

Have Claude create:

- `<vault-path>/raw/`
- `<vault-path>/wiki/`
- `<vault-path>/outputs/`

A clean way to do it from inside Claude Code:

```bash
mkdir -p raw wiki outputs raw/daily
```

The extra `raw/daily/` is for the daily notes pattern you will use
every session. We will seed the first one in the next step.

### Step 7 — Seed your first daily note

Ask Claude to create `raw/daily/<today>.md` where `<today>` is today's
date in `YYYY-MM-DD` form. Use the following starter template (Claude
will substitute today's date):

```markdown
# <YYYY-MM-DD>

## What I worked on

- Set up my Obsidian second brain following the Karpathy three-folder
  pattern.
- Wrote `CLAUDE.md` at the vault root so future Claude sessions know
  the structure.
- Created `raw/`, `wiki/`, `outputs/`, `raw/daily/`.

## What I learned

- A second brain is just a folder of Markdown files. The tools change,
  the folder outlives them.
- `[[wiki-links]]` are how knowledge connects. Filesystem nesting is
  not where structure lives.
- See [[karpathy-second-brain]] for the deeper rationale (to be written
  later, in `wiki/`).

## Open threads

- Build first coding project under `projects/`.

## Tomorrow

- Pick a small project. Use plan mode. Ship slice 1.
```

Confirm the file path before writing. After Claude writes it, switch to
Obsidian and watch the daily note appear in the file tree. Click on it
— that is your second brain coming online.

### Step 8 — Tell Claude how to behave at session end

This is the closing instruction that makes the whole loop self-
maintaining. Tell Claude, in plain English, the following (and ask
Claude to repeat it back so you know it is internalised):

> At the end of every working session in this vault, before I close
> the terminal, you should: (a) append a short summary to today's daily
> note at `raw/daily/<today>.md` — what we worked on, what we learned,
> what is open; (b) link any concept mentioned in the summary to its
> note using `[[wiki-links]]`, creating stub notes if the linked target
> does not exist yet; (c) propose any promotions from `raw/` to
> `wiki/` that you think are worth doing, but never execute a
> promotion without my explicit approval.

That is the entire second-brain protocol. Six instructions, three
folders, one CLAUDE.md. From now on Claude will help you keep the brain
healthy without you having to remember the rules.

### Section 1 — checkpoint

Before moving to Section 2, confirm all of the following exist:

- `<vault-path>/CLAUDE.md` with the structure above.
- `<vault-path>/raw/`, `<vault-path>/wiki/`, `<vault-path>/outputs/`,
  `<vault-path>/raw/daily/`.
- `<vault-path>/raw/daily/<today>.md` with the seeded content.
- Obsidian shows the daily note in its file tree.

If anything is missing, fix it before continuing. The next section
assumes the brain is in place.

---

## Section 2 — Build your first project inside the vault

You now have a vault that knows how to grow itself. Time to put
something *built* inside it. The goal of this section is not to ship
a unicorn — it is to walk you through the full plan-mode loop one time
end-to-end, on a project small enough to finish in the remaining
session time.

### Step 1 — Create the project folder

Inside the vault, create:

```bash
mkdir -p projects
cd projects
mkdir my-first-project
cd my-first-project
```

Replace `my-first-project` with whatever you want to call it. Keep it
kebab-case. Keep it short.

You should now be at `<vault-path>/projects/<project-name>/`. This is
where Claude will work for the rest of this section.

### Step 2 — Activate plan mode

Plan mode is a Claude Code feature where the model writes a full plan
before touching any code. Nothing is executed until you explicitly
approve the plan. It is the single highest-leverage habit you can
develop with Claude.

To activate plan mode, **press Shift+Tab** in the Claude Code
terminal. You will see the prompt indicator change to show plan mode
is active. From this point until you exit plan mode, Claude will
discuss, design, and plan — but will not write code or run commands
that change the system.

Press **Shift+Tab** now.

> **What plan mode is for.** It separates *thinking* from *doing*. In
> normal mode Claude tends to start typing immediately. In plan mode
> Claude is forced to surface assumptions, name unknowns, list
> alternatives, and propose a stepwise plan before any keystroke
> changes a file. You read the plan, push back on the parts that
> look wrong, and approve only when the plan matches what you
> actually want. This costs you 60 seconds upfront and saves hours
> downstream.

### Step 3 — Tell Claude what you want to build

Tell Claude, in one sentence, what you want this first project to be.
Anything is fair game:

- A command-line utility (`a CLI that converts CSV to JSON with type
  inference`).
- A single React component (`a search input with debounce and a
  keyboard shortcut to focus it`).
- A Python script (`a script that pulls my last week of git commits
  and renders them as a Markdown changelog`).
- A static HTML page (`a single-page resume that prints cleanly to
  PDF`).
- A small data analysis (`load this CSV, plot the distribution, save a
  PNG`).

Pick something you would actually use. Pick something small. If you
say "build me an e-commerce platform", Claude will push back and
propose scope reduction — listen to it. The point of this session is
to ship something tiny, not to start something gigantic.

Tell Claude: "I want to build <one sentence>." Then let Claude lead.

### Step 4 — Spec-driven development

Claude will invoke the **`spec-driven-development`** skill. This
produces a short specification before any code is written. Expect
Claude to ask you questions like:

- What are the inputs? What are the outputs?
- What is the success criterion? How will you know it works?
- What is explicitly out of scope?
- What edge cases matter? What edge cases do not matter today?

Answer these honestly and briefly. The output of this step is a small
spec document (typically saved as `SPEC.md` or similar inside the
project folder) that defines what "done" means for slice 1.

If Claude proposes a spec that feels too big, say so. Smaller slice =
faster feedback = more confidence.

### Step 5 — Planning and task breakdown

Claude will invoke the **`planning-and-task-breakdown`** skill to
turn the spec into a short ordered list of implementable tasks. Each
task should be:

- Small enough that one slice fits in a single commit.
- Self-contained — you can verify it works without finishing later
  slices.
- Ordered so each task only depends on previous tasks.

You should see a numbered list of tasks with acceptance criteria for
each. Read it. Push back on anything that feels too vague or too
ambitious. Ask Claude to split tasks if they look too big.

### Step 6 — Exit plan mode and execute slice 1

When you are happy with the plan, exit plan mode (press **Shift+Tab**
again to cycle out, or simply tell Claude "the plan looks good — let's
build slice 1"). Claude moves into execution.

For slice 1, Claude will use the **`incremental-implementation`**
skill — small, verifiable changes — and the
**`test-driven-development`** skill where it makes sense, writing a
failing test first, then implementing just enough to make it pass.

Watch what Claude does. Read each file it writes. If a write looks
wrong, stop and ask why. Resist the urge to let it run on autopilot
for the first project — the point is to learn the loop.

### Step 7 — Run the tests (or the code) yourself

After Claude reports slice 1 is done, run the artifact yourself.

- If it is a CLI, run it with real input.
- If it is a script, run it on a real file.
- If it has tests, run them with `npm test`, `pytest`, `cargo test`,
  whatever applies.
- If it is a UI component, open it in a browser and try it.

"Compiles" is not "works". Until you have seen the output on your own
screen, the slice is not done.

### Step 8 — Code review and commit

Once the slice works, ask Claude to run the **`code-review-and-quality`**
skill on what it just wrote. This is a self-review across five axes:
correctness, readability, architecture, security, performance. Claude
will flag issues it spots. Fix the small ones. Note the big ones for
slice 2.

Then commit. Inside the project folder:

```bash
git init     # first time only
git add .
git commit -m "slice 1: <one sentence>"
```

You have now shipped your first slice using the full loop:
**spec → plan → implement → test → review → commit**. Every future
project in this vault will use the same shape. The skills are bundled;
Claude will pick the right one each time.

### Step 9 — Log the session in your daily note

Before you close the terminal, ask Claude to append a session summary
to `<vault-path>/raw/daily/<today>.md`. Something like:

```markdown
## Project: <project-name>

- Built slice 1: <one sentence>
- Spec at `projects/<project-name>/SPEC.md`
- Tests passing. Committed as `<commit hash>`.
- Next slice: <next thing>

Related: [[plan-mode]], [[spec-driven-development]] (to be promoted
from this entry to `wiki/` once enough sessions accumulate).
```

That closes the loop. Your daily note now contains a pointer to every
piece of work you did today, and the project itself is a self-
contained git repo inside the vault.

---

## Section 3 — How to come back

You are done. Two more things to know for next time.

### Opening the vault next session

Next time you want to work, just:

```bash
cd <vault-path>
claude
```

The `CLAUDE.md` you wrote in Section 1 loads automatically. Claude
remembers the three-folder structure, the daily-note pattern, and the
session-close protocol — because they live in that file.

For a specific project, `cd` into it instead:

```bash
cd <vault-path>/projects/<project-name>
claude
```

The vault-root `CLAUDE.md` still loads. You can also add a per-project
`CLAUDE.md` inside the project folder for project-specific rules — it
will load on top of the vault one.

### Growing the brain

Every working session, append to today's daily note in
`raw/daily/YYYY-MM-DD.md`. Let topics accumulate there. When you
notice you have written about the same topic three or four times
across different daily notes, that is the signal to promote it: draft
a clean article in `wiki/<topic>.md` that synthesises what you have
learned, and link back to the daily notes that fed into it.

Finished deliverables — a deck for a meeting, a report for a client,
a release of a project — land in `outputs/` with a date prefix:
`outputs/2026-05-12-quarterly-report.md`.

Over months this folder becomes a graph of everything you have
thought, learned, and shipped. Open Obsidian's graph view sometime to
see it visually — the `[[wiki-links]]` you have been adding become a
literal map of your knowledge.

That is the second brain. That is what you just built. Welcome to it.

---

## Appendix — quick reference card

```
<vault-path>/
├── CLAUDE.md              ← vault rules, auto-loaded every session
├── raw/                   ← drafts, scratch, fragments
│   └── daily/
│       └── YYYY-MM-DD.md  ← one per working day
├── wiki/                  ← codified articles, the long-term layer
├── outputs/               ← finished deliverables
└── projects/              ← coding projects (each its own git repo)
    └── <project-name>/
```

Plan mode toggle: **Shift+Tab** in the Claude Code terminal.

Skills used in your first project:

1. `spec-driven-development` — what does "done" mean?
2. `planning-and-task-breakdown` — break it into slices.
3. `incremental-implementation` — small verifiable steps.
4. `test-driven-development` — failing test first, code second.
5. `code-review-and-quality` — five-axis self-review before commit.

Session-close ritual: log today's daily note, link concepts with
`[[wiki-links]]`, propose promotions to `wiki/`.

That is the whole system.
