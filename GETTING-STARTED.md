<!-- Read in: [English](GETTING-STARTED.md) · [Español](GETTING-STARTED.es.md) -->

# Getting started — from zero

This guide is for people who have **never opened a terminal**, never used
**git**, and just want to get the Claude Starter Kit working on their
machine.

If you already use a terminal, skip this and read [`README.md`](README.md).

Total time: about **10 minutes**.

---

## 0. What you'll end up with

A working Claude Code setup with curated plugins, MCP servers, an
opinionated `CLAUDE.md`, and persistent memory. You'll know what each
piece does because Claude itself walks you through it during install.

## 1. Install Claude Code (if you don't have it)

If you can already type `claude` in a terminal and get a chat, skip to
step 2.

Go to https://docs.claude.com/en/docs/claude-code/quickstart and follow
the official install instructions for your operating system. You'll
need to log in with your Anthropic account once.

When you're done, you should be able to open any terminal and type
`claude --version` and see a version number print out.

## 2. Install Git (if you don't have it)

Git is the tool that downloads code from GitHub.

- **Windows:** download and run the installer from https://git-scm.com/download/win. Accept all the defaults — just click "Next" through every screen.
- **macOS:** open the **Terminal** app (press <kbd>⌘ Space</kbd>, type "Terminal", hit enter). Paste this and press enter:
  ```bash
  xcode-select --install
  ```
  A dialog will pop up. Click "Install" and wait a few minutes.
- **Linux:** your package manager already has it. `sudo apt install git` on Ubuntu/Debian, `sudo dnf install git` on Fedora.

To verify it worked, open a terminal and type:

```bash
git --version
```

You should see something like `git version 2.45.1`. Any number is fine.

## 3. Open a terminal

You'll need a terminal window for the next steps. Don't worry about it —
you'll only type the commands this guide gives you.

- **Windows:** press the <kbd>Windows</kbd> key, type "PowerShell", and press enter. A blue or black window opens.
- **macOS:** press <kbd>⌘ Space</kbd>, type "Terminal", press enter.
- **Linux:** you already know.

## 4. Download the starter kit

In the terminal, paste this and press enter:

```bash
git clone https://github.com/fmedrano06/claude-starter-kit
```

This downloads the kit into a folder named `claude-starter-kit` inside
whatever folder you were in. You'll see a few lines about "cloning" and
"receiving objects". When the prompt comes back, it's done.

Now step into that folder:

```bash
cd claude-starter-kit
```

The prompt should change to show you're inside `claude-starter-kit`.

## 5. Run the install — the easy way

Open Claude Code inside this folder. In the same terminal, type:

```bash
claude
```

Claude Code starts. Now copy this and paste it as your **first
message**:

```
read SETUP.md and install the starter kit
```

Claude will:

1. Ask you a few questions (your name, your role, which language you
   want it to reply in, which optional features you want).
2. Make a **backup** of your current Claude Code configuration — so if
   anything goes wrong, nothing is lost.
3. Write the new configuration files.
4. Tell you what was installed and where.

The whole thing takes 1–2 minutes once you start answering.

## 6. Restart Claude Code

After the install finishes, exit the current Claude session (type
`/exit` or close the terminal) and start a new one. The new
configuration loads on the next start.

## 7. Take the tour

Open this file in your browser to see what just got installed and how
to use it:

```
claude-starter-kit/guide/index.html
```

On Windows, double-click it from File Explorer. On macOS, run `open
guide/index.html` from the terminal. On Linux, `xdg-open
guide/index.html`.

---

## Something went wrong?

The installer makes a full backup at `~/.claude/.backup-<timestamp>/`
before touching anything. To completely undo the install:

- **Windows:**
  ```powershell
  Remove-Item -Recurse "$env:USERPROFILE\.claude\CLAUDE.md","$env:USERPROFILE\.claude\skills"
  Copy-Item -Recurse "$env:USERPROFILE\.claude\.backup-*\*" "$env:USERPROFILE\.claude\"
  ```
- **macOS / Linux:**
  ```bash
  rm -rf ~/.claude/CLAUDE.md ~/.claude/skills
  cp -R ~/.claude/.backup-*/* ~/.claude/
  ```

If something else broke, open an issue at
https://github.com/fmedrano06/claude-starter-kit/issues with a copy of
the error message you saw.

## Path B: didn't want to install Claude Code yourself

If step 1 felt like too much, use the scripts the kit ships with — they
install Claude Code for you, then run the wizard.

- **Windows** (in PowerShell, from inside `claude-starter-kit`):
  ```powershell
  ./install/install.ps1
  ```
- **macOS / Linux** (in Terminal, from inside `claude-starter-kit`):
  ```bash
  bash install/install.sh
  ```

Either script asks the same questions Claude would ask in step 5, just
without going through Claude first.
