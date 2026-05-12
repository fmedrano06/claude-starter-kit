# Plugins catalog

This is the curated list of plugins the starter kit recommends.

## What is a plugin?

A **plugin** in Claude Code is a bundle of capabilities that you can
install into your environment with a single command. A plugin can ship
any combination of:

- **Skills** — reusable instructions that activate by keyword or context.
- **Commands** — slash commands you can run (e.g. `/review`, `/schedule`).
- **Agents** — specialized subagents Claude can delegate work to.
- **Hooks** — automation that fires on events (pre/post tool use, etc).
- **MCP servers** — external tools (see [mcps.md](./mcps.md) for the
  distinction).

Plugins are distributed through **marketplaces**, which are public Git
repositories that publish a `marketplace.json` manifest listing the
plugins they offer.

## Plugins included in this starter kit

The starter kit's `settings.json.template` already declares all of the
plugins below in `enabledPlugins`, and registers their marketplaces via
`extraKnownMarketplaces`. **They activate automatically** the first time
you launch Claude Code after running the installer. The `/plugin install`
commands in the table below are only useful if you want to install a
plugin individually outside of the template.

| Plugin | Purpose | Install command |
|---|---|---|
| `superpowers` | Core skills library: TDD, debugging, collaboration patterns, and proven techniques.[^1] | `/plugin install superpowers@claude-plugins-official` |
| `cli-anything` | Build powerful, stateful CLI interfaces for any GUI application using the cli-anything harness methodology.[^2] | `/plugin install cli-anything@cli-anything` |
| `andrej-karpathy-skills` | Behavioral guidelines to reduce common LLM coding mistakes: Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution.[^3] | `/plugin install andrej-karpathy-skills@karpathy-skills` |
| `agent-skills` | Production-grade engineering skills covering every phase of software development: spec, plan, build, verify, review, and ship.[^4] | `/plugin install agent-skills@addy-agent-skills` |
| `claude-mem` | Persistent memory system for Claude Code — context compression across sessions.[^5] | `/plugin install claude-mem@thedotmack` |
| `playground` | Creates interactive HTML playgrounds — self-contained single-file explorers with visual controls, live preview, and prompt output with copy button.[^6] | `/plugin install playground@claude-plugins-official` |
| `code-simplifier` | Agent that simplifies and refines code for clarity, consistency, and maintainability while preserving functionality. Focuses on recently modified code.[^7] | `/plugin install code-simplifier@claude-plugins-official` |
| `feature-dev` | Comprehensive feature development workflow with specialized agents for codebase exploration, architecture design, and quality review.[^8] | `/plugin install feature-dev@claude-plugins-official` |
| `plugin-dev` | Comprehensive toolkit for developing Claude Code plugins. Includes expert skills covering hooks, MCP integration, commands, agents, and best practices.[^9] | `/plugin install plugin-dev@claude-plugins-official` |

> Note: the install command syntax is `/plugin install <name>@<marketplace>`.
> The command is interactive — Claude Code will ask whether you want to
> install for your user (global) or just for the current project.

## Marketplaces referenced

The plugins above live in six marketplaces, all public GitHub repos:

| Marketplace name | GitHub repo |
|---|---|
| `claude-plugins-official` | https://github.com/anthropics/claude-plugins-public |
| `cli-anything` | https://github.com/HKUDS/CLI-Anything |
| `karpathy-skills` | https://github.com/forrestchang/andrej-karpathy-skills |
| `addy-agent-skills` | https://github.com/addyosmani/agent-skills |
| `thedotmack` | https://github.com/thedotmack/claude-mem |
| `superpowers-marketplace` | https://github.com/obra/superpowers-marketplace |

The starter kit's `settings.json.template` adds these to
`extraKnownMarketplaces` so the install commands resolve without any
manual `claude marketplace add` step.

## Verify installation

After the installer finishes (or after you run the install commands
yourself), open Claude Code and run:

```text
/plugin list
```

You should see all nine plugins in the output. If any are missing:

1. Confirm the marketplace is registered with `claude marketplace list`.
2. Re-run `/plugin install <name>@<marketplace>` for the missing one.
3. Restart Claude Code — newly registered marketplaces sometimes require
   a fresh session to be picked up by `/plugin install`.

## Skipping a plugin

If you want to opt out of any plugin, remove its entry from the
`enabledPlugins` array in your `settings.json` after the install
completes. The plugin's marketplace can stay registered; it just won't
auto-load.

---

[^1]: Source: `superpowers-marketplace` marketplace manifest at
  https://github.com/obra/superpowers-marketplace, plugin entry for
  `superpowers`, field `description`.
[^2]: Source: `cli-anything` marketplace manifest at
  https://github.com/HKUDS/CLI-Anything, plugin entry for
  `cli-anything`, field `description`.
[^3]: Source: `karpathy-skills` marketplace manifest at
  https://github.com/forrestchang/andrej-karpathy-skills, plugin entry
  for `andrej-karpathy-skills`, field `description`.
[^4]: Source: `addy-agent-skills` marketplace manifest at
  https://github.com/addyosmani/agent-skills, plugin entry for
  `agent-skills`, field `description`.
[^5]: Source: `thedotmack` marketplace manifest at
  https://github.com/thedotmack/claude-mem, plugin entry for
  `claude-mem`, field `description`.
[^6]: Source: `claude-plugins-official` marketplace manifest at
  https://github.com/anthropics/claude-plugins-public, plugin entry for
  `playground`, field `description`.
[^7]: Source: `claude-plugins-official` marketplace manifest at
  https://github.com/anthropics/claude-plugins-public, plugin entry for
  `code-simplifier`, field `description`.
[^8]: Source: `claude-plugins-official` marketplace manifest at
  https://github.com/anthropics/claude-plugins-public, plugin entry for
  `feature-dev`, field `description`.
[^9]: Source: `claude-plugins-official` marketplace manifest at
  https://github.com/anthropics/claude-plugins-public, plugin entry for
  `plugin-dev`, field `description`.
