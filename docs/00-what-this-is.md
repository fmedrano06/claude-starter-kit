# What this is

The Claude Code Starter Kit is an opinionated, batteries-included
starting point for using [Claude Code](https://docs.claude.com/en/docs/claude-code/quickstart)
as a serious engineering tool. It is aimed at people who:

- have just installed Claude Code (or are about to), and
- want the kind of configuration that takes a working engineer several
  months to build up by trial and error, in five minutes instead.

It is **not** a framework. There is nothing to import, nothing to
depend on, no runtime. The kit's only output is a handful of plain text
files in your home directory and (optionally) a project directory.

## What problem this solves

Out of the box, Claude Code is a blank slate. To get to a productive
setup you typically end up doing all of the following yourself,
spreading the work across many sessions:

- Writing a `CLAUDE.md` that captures how you actually want Claude to
  work — when to stop and ask, what "done" means, when to refactor and
  when not to.
- Discovering plugins and registering their marketplaces.
- Finding MCP servers that solve real problems (docs lookup, browser
  automation, GitHub access) and configuring them.
- Setting up some form of persistent memory so Claude doesn't reset
  every session.
- Settling on a hook config that gives you a useful statusline and any
  automation you want.

The starter kit ships all of that as defaults, with each piece
documented and easy to remove if you disagree.

## What ships in the box

### 1. A global `CLAUDE.md`

Encodes engineering principles that translate directly to better code:
think before coding, simplicity first, surgical changes, goal-driven
execution. Adapted from widely shared community guidance (see the
`andrej-karpathy-skills` plugin for the original inspiration).

### 2. A `settings.json`

Pre-configured with:

- `enabledPlugins` — the nine plugins from [`plugins.md`](../plugins.md).
- `extraKnownMarketplaces` — the six marketplaces those plugins live
  in, so the install commands resolve out of the box.
- A statusline hook pointing at `templates/statusline-command.sh`.
- Conservative permissions: nothing surprising is auto-allowed.

### 3. A persistent memory layout

The kit configures Claude Code's auto-memory feature to write per-CWD
memory files under `~/.claude/projects/<cwd-slug>/memory/`. Each project
gets its own:

- `MEMORY.md` — an index that loads at the start of every session in
  that directory.
- Typed memory files: user profile, feedback, project context,
  external references.

This is configured but starts empty. You build it up by working — the
auto-memory system writes durable observations on its own, and you can
ask Claude to remember specific facts.

### 4. Five bundled skills

Copied into `skills/` so they travel with the kit:

| Skill | What it does |
|---|---|
| `impeccable` | Generates distinctive, production-grade frontend interfaces. |
| `ui-ux-pro-max` | Broad UI/UX intelligence: styles, palettes, font pairings, stacks. |
| `gh-issues` | Triage GitHub issues, spawn fixes, monitor PR reviews. |
| `graphify` | Turn any input into a navigable knowledge graph. |
| `project-prime` | Ten-phase framework for kicking off a new project the right way. |

### 5. A curated plugin catalog

[`plugins.md`](../plugins.md) lists nine plugins, each with a one-line
purpose sourced directly from the upstream marketplace's manifest.
Coverage areas: TDD/debugging methodology, CLI automation, behavioral
guidelines, full SDLC skills, persistent memory, UI playground
generation, code simplification, full-feature workflows, and plugin
development itself.

### 6. A curated MCP catalog

[`mcps.md`](../mcps.md) lists recommended MCP servers in three tiers:
free / no key, needs an API key, and niche SaaS connectors. Every URL
in the catalog was verified at the time of release.

### 7. An interactive tour

`guide/index.html` is a self-contained HTML file that walks new users
through the kit visually. Open it in any browser — there's no build
step and nothing to install.

### 8. Three installation paths

- **Path A**: Claude itself reads `SETUP.md` and installs.
- **Path B**: `install/install.ps1` for Windows.
- **Path C**: `install/install.sh` for macOS/Linux.

All three end up at the same place. They differ only in who is driving
the wizard.

## What this kit is NOT

- **Not a framework.** No runtime, no dependencies, no SDK.
- **Not a replacement** for the Claude Code CLI. It configures Claude
  Code; it does not wrap it.
- **Not a fork** of anyone's plugins. All plugins install from their
  upstream marketplaces — this repo never vendors third-party code.
- **Not a managed product.** There is no server, no telemetry, no
  account.

## Who maintains it

The kit is maintained by its contributors under the MIT license. PRs
are welcome; the only firm rule is: **do not vendor third-party plugin
or MCP source code**. Catalog entries reference upstream repos and copy
nothing but descriptions.

## Where to go next

- New user? Start with [`01-installation.md`](./01-installation.md).
- Want to bend the kit to your shape? See
  [`02-customization.md`](./02-customization.md).
- Already installed? Read
  [`03-daily-workflow.md`](./03-daily-workflow.md).
- Something broken? Try
  [`04-troubleshooting.md`](./04-troubleshooting.md).
