# Claude Code Starter Kit

> Read in: **English** · [Español](README.es.md)
>
> 👋 **New to terminals or git?** Start with
> [`GETTING-STARTED.md`](GETTING-STARTED.md) — a 10-minute walkthrough
> that assumes nothing.

A starter kit that gets a new Claude Code user from a fresh install to a
senior-level setup in about five minutes — opinionated defaults, a
curated plugin and MCP catalog, five high-leverage skills, a persistent
memory layout, and a CLAUDE.md that encodes good engineering habits.

It is intentionally small. It is not a framework, it does not vendor
anything, and it does not lock you in. Every file it writes is plain
text you own and can edit.

## Install

There are three paths. Pick whichever matches your situation.

### Path A — already have Claude Code (recommended)

This is the path for people who already have Claude Code installed and
working. It lets Claude itself install the kit, so you can ask
clarifying questions in plain English along the way.

1. Clone this repo somewhere on your machine.
2. Open Claude Code in the cloned directory.
3. Say: **"read SETUP.md and install the starter kit"**.

Claude will walk through the **adaptive wizard** (it first asks whether
you're a beginner, intermediate, or senior user, then asks 6–14 follow-up
questions tuned to that level). The resulting `CLAUDE.md`, default model,
permission profile, status-line preset, and optional Obsidian-compatible
knowledge vault are all shaped by your answers. Restart your session
once Claude finishes to pick up the new configuration.

### Path B — Windows, no Claude Code yet

This is the path for a brand-new Windows machine. Open PowerShell in
the cloned repo and run:

```powershell
./install/install.ps1
```

The script installs Claude Code if it is missing, then runs the same
wizard Path A uses.

### Path C — macOS / Linux

Open a terminal in the cloned repo and run:

```bash
bash install/install.sh
```

Same wizard, same result.

## What's inside

- **`templates/CLAUDE.md.template`** — a global CLAUDE.md that encodes
  durable engineering standards (think before coding, simplicity first,
  surgical changes, goal-driven execution).
- **`templates/settings.json.template`** — pre-configured Claude Code
  settings, including `enabledPlugins` and `extraKnownMarketplaces` so
  the recommended plugins activate on first launch.
- **`templates/memory/`** — a per-CWD auto-memory layout (`MEMORY.md`
  index plus typed memory files) that survives across sessions.
- **`templates/hooks/`** — opinionated hooks (statusline, etc.).
- **`skills/`** — five high-leverage skills copied into the repo so they
  travel with the kit: `impeccable` (UI/UX), `ui-ux-pro-max`,
  `gh-issues`, `graphify`, `project-prime`.
- **[`plugins.md`](./plugins.md)** — curated catalog of nine recommended
  plugins, every description sourced from its marketplace manifest.
- **[`mcps.md`](./mcps.md)** — curated catalog of recommended MCP servers
  (free, key-required, niche/opt-in).
- **`guide/index.html`** — an interactive single-file in-browser tour
  of the kit.
- **`docs/`** — extended documentation:
  - [`00-what-this-is.md`](./docs/00-what-this-is.md) — the long version
    of this README.
  - [`01-installation.md`](./docs/01-installation.md) — installation
    details and what each script does.
  - [`02-customization.md`](./docs/02-customization.md) — how to edit
    CLAUDE.md, add skills, and override per project.
  - [`03-daily-workflow.md`](./docs/03-daily-workflow.md) — how to
    actually use the kit day-to-day.
  - [`04-troubleshooting.md`](./docs/04-troubleshooting.md) — common
    issues and how to diagnose them.

## Prerequisites

- **Claude Code** installed. See the official install docs at
  https://docs.claude.com/en/docs/claude-code/quickstart.
- A POSIX shell (bash or zsh) on macOS/Linux, or PowerShell 7+ on
  Windows.
- Git (only required if you want to clone this repo; you can also
  download a zip from GitHub).

## What this kit does NOT do

- It does not replace Claude Code. It configures it.
- It does not vendor any plugin source code. Plugins install from their
  upstream marketplaces.
- It does not collect telemetry or phone home.
- It does not require any paid service. Most of the kit is free; a few
  MCP servers in `mcps.md` need accounts on third-party SaaS products,
  but those are clearly marked.

## License

MIT. See [`LICENSE`](./LICENSE).

## Versioning

See [`CHANGELOG.md`](./CHANGELOG.md). The current version is **0.4.1**.
