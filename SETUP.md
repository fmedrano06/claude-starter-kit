<!-- claude-starter-kit installer entry point — read this top-to-bottom -->

# SETUP — install the Claude Starter Kit

Welcome. This file is the entry point for installing the Claude Starter Kit
into your local Claude Code configuration at `~/.claude/`. There are two
ways to run the install:

- **Claude path (recommended).** Open this repository in Claude Code and
  type: *"read SETUP.md and install me"*. Claude will read the section
  below titled "Claude — read this section to perform the install", ask
  you the wizard questions, back up your current config, and write the
  new files for you.
- **CLI path.** If you do not have Claude Code installed yet, run
  `install/install.ps1` on Windows or `install/install.sh` on macOS or
  Linux. Both scripts use the same wizard questions and produce the same
  result as the Claude path.

What will end up on your machine:

- A new `~/.claude/CLAUDE.md` written from
  `templates/CLAUDE.md.template`, personalised with your name, role, and
  primary languages.
- Any skills you select copied into `~/.claude/skills/`.
- A merged `~/.claude/settings.json` that adds the chosen MCP servers
  and, optionally, a Stop hook. Your existing keys are preserved.
- A starter `~/.claude/projects/<cwd-slug>/memory/MEMORY.md` so the
  auto-memory system has somewhere to write from session one.
- A timestamped backup of your previous `~/.claude/` at
  `~/.claude/.backup-<ISO-timestamp>/` so nothing is lost.

If anything in the install fails, the installer restores from that
backup and tells you which step failed. You can re-run the installer
any number of times; it is idempotent.

---

## Claude — read this section to perform the install

You are acting as the installer. Execute the steps below in order. Do
not improvise extra steps. After every write, confirm success before
moving to the next step. If any step fails, stop, restore from the
backup created in step 4, and report the failing step to the user.

### Step 1 — Detect OS and resolve the Claude home directory

- On Windows, the Claude home is `$env:USERPROFILE\.claude`.
- On macOS and Linux, the Claude home is `$HOME/.claude`.

Record this path as `CLAUDE_HOME`. Create the directory if it does not
exist.

### Step 2 — Load the wizard questions

Read `install/lib/wizard-questions.json` from this repository. Parse it
as JSON and iterate the `questions` array in order. The file is the
single source of truth for prompts; do not invent additional questions
and do not skip any.

### Step 3 — Ask the user the wizard questions

For each question object, call `AskUserQuestion` with the `prompt`
field. Honour the `type` field:

- `text` — accept free text. If empty and a `default` is set, use the
  default.
- `boolean` — accept yes / no. Default applies if the user just hits
  enter.
- `single-select` — present `options` as choices, accept one.
- `multi-select` — present `options` as choices, accept any subset
  including the empty set.

Collect the answers into a dictionary keyed by question `id`. The
expected keys are: `user_name`, `user_role`, `primary_language`,
`communication_language`, `skills_to_install`, `mcps_to_enable`,
`enable_stop_hook`.

### Step 4 — Idempotency check and backup

Check whether `CLAUDE_HOME/CLAUDE.md` exists.

- If it exists and begins with the marker comment
  `<!-- claude-starter-kit v0.1.0 -->`, this kit is already installed.
  Ask the user with `AskUserQuestion` whether to re-install. If they
  decline, stop here and report no changes made.
- If it exists at all, ask the user permission to back up the current
  `~/.claude/` directory. On approval, copy `CLAUDE_HOME` to
  `CLAUDE_HOME/.backup-<ISO-timestamp>/`. Exclude these subdirectories
  to keep the backup fast and small: `projects/`, `sessions/`,
  `cache/`. Record the backup path so step 11 can restore from it on
  failure.

### Step 5 — Render and write CLAUDE.md

Read `templates/CLAUDE.md.template`. Substitute these placeholders with
the wizard answers:

- `{{USER_NAME}}` ← `user_name`
- `{{USER_ROLE}}` ← `user_role`
- `{{PRIMARY_LANGUAGE}}` ← `primary_language`
- `{{COMMUNICATION_LANGUAGE}}` ← `communication_language`

Write the rendered content to `CLAUDE_HOME/CLAUDE.md`. The rendered
file must begin with the marker comment
`<!-- claude-starter-kit v0.1.0 -->` so step 4 of a future re-install
can detect it.

### Step 6 — Copy selected skills

For each entry in `skills_to_install`, copy `skills/<skill-id>/` from
this repository to `CLAUDE_HOME/skills/<skill-id>/`. Create
`CLAUDE_HOME/skills/` if it does not exist. If a skill directory
already exists at the destination, overwrite it.

### Step 7 — Merge settings.json

Read `templates/settings.json.template`. Read
`CLAUDE_HOME/settings.json` if it exists, otherwise treat it as an
empty object.

Deep-merge the template into the existing settings:

- Top-level keys present only in the existing file are preserved.
- Top-level keys present only in the template are added.
- For overlapping keys, prefer the existing value unless it is the
  default — except for `mcpServers`, where you union the two maps and
  enable only the MCPs in `mcps_to_enable`.
- If the existing file already defines a `hooks` map, do not overwrite
  it. Ask the user with `AskUserQuestion` whether to merge in any new
  hook entries from the template.

Write the merged object back to `CLAUDE_HOME/settings.json` with
two-space indentation.

### Step 8 — Seed the auto-memory directory

Compute a slug for the current working directory: lowercase, replace
path separators and spaces with `-`, drop drive letters. Render
`templates/memory/MEMORY.md.template` and write it to
`CLAUDE_HOME/projects/<cwd-slug>/memory/MEMORY.md`. Create
intermediate directories as needed. Skip if the file already exists.

### Step 9 — Install the Stop hook (optional)

If `enable_stop_hook` is true:

- On Windows, copy `templates/hooks/notify-stop.ps1.example` to
  `CLAUDE_HOME/hooks/notify-stop.ps1`.
- On macOS or Linux, adapt the equivalent shell hook (use
  `osascript` for macOS, `notify-send` for Linux). If no equivalent
  exists in the templates directory, skip this step and tell the user
  that the Stop hook is Windows-only in this release.

If `enable_stop_hook` is false, skip this step entirely.

### Step 10 — Print summary

Tell the user what was installed. List:

- The path to `CLAUDE_HOME/CLAUDE.md`.
- Each skill copied.
- Each MCP server enabled.
- Whether the Stop hook is active.
- The backup directory created in step 4.
- The local path to `guide/index.html` (offer to open it in the
  default browser).

### Step 11 — Failure handling

If any step from 5 through 9 raises an error, do the following before
reporting to the user:

- Delete any partially written files this run created in `CLAUDE_HOME`.
- Restore the backup from step 4 by copying it back over
  `CLAUDE_HOME` (excluding the backup directory itself).
- Tell the user exactly which step failed and what the error was.

### Step 12 — Optional onboarding hand-off

If `show_onboarding_after_install` is true, copy
`templates/first-session-prompt.md` to
`CLAUDE_HOME/onboarding/first-session-prompt.md` (create the
`onboarding/` directory if it does not exist) and print the same
message described in `install/install.ps1` and `install/install.sh`
under the heading "Ready for your first guided session?". The message
walks the user through installing Obsidian, picking a vault folder,
opening Claude Code inside it, and pasting `read
~/.claude/onboarding/first-session-prompt.md and walk me through it`
as their first message.

If `show_onboarding_after_install` is false, skip this step entirely.

---

## After the install

Open `guide/index.html` in a browser for a tour of what was installed
and how each piece works. The guide is also the place to look if you
want to remove the kit later — uninstall instructions live there.

If something feels off, the backup at
`~/.claude/.backup-<ISO-timestamp>/` is your safety net. Restoring is a
plain directory copy back over `~/.claude/`.
