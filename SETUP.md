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

### Step 2 — Load the wizard questions (schema 2.0)

Read `install/lib/wizard-questions.json`. Parse it as JSON. The file is
the single source of truth — do not invent extra questions, do not skip
any, do not reorder.

The schema has two top-level pieces:

- `level_question` — a single `single-select` question asking the user
  for their experience level (`beginner` / `intermediate` / `senior`).
- `branches` — an object keyed by level, each holding an array of
  questions specific to that branch.

### Step 3 — Ask the user the wizard questions

Step 3a: also ask first which language the wizard should run in. Default
to English unless the user clearly prefers Spanish. Use the `*_es`
fields when the user picks Spanish (`prompt_es`, `explainer_es`,
`description_es`, `label_es`).

Step 3b: ask `level_question`. Record the answer as
`answers.experience_level`. This decides which branch to iterate next.

Step 3c: iterate `branches[<level>]` in order. For each question:

- Honour the `type` field:
  - `text` — free text. If empty and a `default` is set, use the
    default.
  - `boolean` — yes / no. Default applies on blank input.
  - `single-select` — present `options` as choices, accept one.
  - `multi-select` — present `options`, accept any subset (including
    empty).
- If the question has an `explainer` (or `explainer_es`), show it
  beneath the prompt as a hint.
- If the question has a `secret: true` field (API keys, tokens), do not
  echo the value as the user types — mask it.
- If the question has a `conditional` field, only ask it when the
  prerequisite answer matches. Forms:
  - `{ "if_answer": "<other_id>", "equals": <value> }` — ask only when
    `answers[<other_id>] === <value>`.
  - `{ "if_answer": "<other_id>", "contains": "<value>" }` — ask only
    when `answers[<other_id>]` is a list containing `<value>`.

Collect everything into a flat dictionary keyed by question `id`. The
exact set of keys depends on the branch; do not assume a fixed list.

### Step 4 — Idempotency check and backup

Check whether `CLAUDE_HOME/CLAUDE.md` exists.

- If it exists and begins with the marker comment
  `<!-- claude-starter-kit v0.4.0 -->`, this kit is already installed.
  Ask the user with `AskUserQuestion` whether to re-install. If they
  decline, stop here and report no changes made.
- If it exists at all, ask the user permission to back up the current
  `~/.claude/` directory. On approval, copy `CLAUDE_HOME` to
  `CLAUDE_HOME/.backup-<ISO-timestamp>/`. Exclude these subdirectories
  to keep the backup fast and small: `projects/`, `sessions/`,
  `cache/`. Record the backup path so step 11 can restore from it on
  failure.

### Step 5 — Render and write CLAUDE.md

Read `templates/CLAUDE.md.template`. Rendering is a two-pass process:

**Pass 1: resolve conditional blocks.** The template contains blocks of
the form `{{IF_LEVEL:<spec>}}...{{END}}`. Two flavors:

- Level list: `{{IF_LEVEL:beginner}}` or `{{IF_LEVEL:intermediate|senior}}`.
  Include the body only if `answers.experience_level` is in the list.
- Answer match: `{{IF_LEVEL:setup_vault:true}}`. Include the body only
  if the named answer equals the value after the colon.

Strip the markers along with the bodies of non-matching blocks.

**Pass 2: substitute placeholders.** Replace these tokens with the
matching wizard answer (or derived value):

- `{{USER_NAME}}` ← `user_name`
- `{{USER_ROLE}}` ← `user_role` (may be blank in beginner branch)
- `{{PRIMARY_LANGUAGE}}` ← `primary_language` (use `"unsure"` if blank)
- `{{COMMUNICATION_LANGUAGE}}` ← `communication_language`
- `{{TODAY}}` ← today in `YYYY-MM-DD`
- `{{MEMORY_DIR}}` ← absolute path to the auto-memory directory
- `{{LEVEL}}` ← `experience_level`
- `{{DEFAULT_MODEL}}` ← `haiku` if budget is `none`/`under_20`,
  `sonnet` if `under_100`, `opus` if `over_100`
- `{{COST_FLAG_THRESHOLD}}` ← `5` / `10` / `25` / `100` matching the
  same budget tiers
- `{{VAULT_PATH}}` ← `vault_path` if `setup_vault=true`, else `(none)`
- `{{PRIMARY_GOAL_HUMAN}}` ← human-readable mapping of `primary_goal`
  (`learn_to_code` → "learn to code", etc.). Blank when absent.

Write the rendered content to `CLAUDE_HOME/CLAUDE.md`. The rendered
file must begin with the marker comment
`<!-- claude-starter-kit v0.4.0 -->` so step 4 of a future re-install
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

Then apply these v0.4.0 post-merge transformations based on the
wizard answers:

- Set `model` from `monthly_ai_budget` (same mapping as
  `{{DEFAULT_MODEL}}` in step 5).
- Apply `permission_profile`:
  - `cautious` → `skipAutoPermissionPrompt=false`, `skipDangerousModePermissionPrompt=false`
  - `balanced` → `skipAutoPermissionPrompt=true`, `skipDangerousModePermissionPrompt=false`
  - `expert` → both `true`
- Compose `statusLine.command` as
  `"bash ~/.claude/statusline-command.sh <preset>"` where `<preset>` is
  `status_line` (default `balanced`).
- If `context7_api_key` is non-empty and `context7` is in
  `mcps_to_enable`, set
  `mcpServers.context7.headers.CONTEXT7_API_KEY = <value>`.
- If `github_pat` is non-empty and `github` is in `mcps_to_enable`,
  set `mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = <value>`.
- If `enable_stop_hook=false`, delete `hooks.Stop` entirely.

Write the merged object back to `CLAUDE_HOME/settings.json` with
two-space indentation.

### Step 7.5 — Scaffold the knowledge vault (if requested)

If `setup_vault=true`:

1. Expand `~` in `vault_path` to the user's home.
2. Create the directories `raw/`, `wiki/`, `outputs/`, `projects/`,
   `_daily/`, `_session-handoffs/` under the vault path.
3. Write a vault-local `CLAUDE.md` explaining the Karpathy 3-folder
   layout (see the installer scripts for the exact text).
4. Create a daily-note seed at `_daily/<YYYY-MM-DD>.md` with a minimal
   structure (`Today's intent`, `Notes`, `Tomorrow`).

If `setup_vault=false`, skip this step entirely.

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
- On macOS or Linux, copy `templates/hooks/notify-stop.sh.example` to
  `CLAUDE_HOME/hooks/notify-stop.sh` and `chmod +x` it. The script
  detects the OS at runtime (`osascript` on macOS, `notify-send` on
  Linux) so no per-OS variants are needed.

The settings.json template uses a `{{STOP_HOOK_COMMAND}}` placeholder
that the installer rewrites before merge: `powershell.exe ... .ps1`
on Windows, `bash ... .sh` on Unix. If `enable_stop_hook` is false,
drop the entire `hooks.Stop` block from the merged settings.

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
