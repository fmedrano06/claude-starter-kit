# MCP servers catalog

This is a curated list of recommended MCP servers for Claude Code.

## What is an MCP server, and how is it different from a plugin?

**MCP** stands for **Model Context Protocol**. An MCP server is a small
external program that exposes a set of **tools** (like "search GitHub
issues" or "take a screenshot") to Claude over a standard protocol.
Claude can then call those tools the same way it calls its built-in
tools.

The simplest way to think about it:

- A **plugin** is a bundle of *instructions, commands, agents, hooks,
  and skills* that Claude Code loads into itself.
- An **MCP server** is an *external program* that Claude talks to over
  the network or via stdio to gain new tools.

A plugin can include an MCP server (the `claude-mem` plugin does this),
but most plugins do not. Most useful MCP servers are added separately
with `claude mcp add ...` and live in your Claude Code config.

This catalog excludes any MCP server that requires a personal endpoint
or a private SaaS account specific to a particular user — only public,
generally useful ones are listed here.

---

## 1. Free / no API key required

| Server | Purpose | Setup docs | Key required? |
|---|---|---|---|
| `sequential-thinking` | A tool for dynamic, reflective problem-solving — breaks a problem into ordered steps Claude can revise and branch on. | https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking | No |
| `claude-mem` | Persistent cross-session memory. Ships **as part of** the `claude-mem` plugin (see [plugins.md](./plugins.md)); the MCP server is installed automatically when the plugin is enabled. | https://github.com/thedotmack/claude-mem | No |

### Add `sequential-thinking`

The reference implementation runs over stdio via `npx`:

```bash
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
```

---

## 2. Needs an API key or account

These are excellent but require you to bring credentials.

| Server | Purpose | Setup docs | Key required? |
|---|---|---|---|
| `context7` | Fetches up-to-date documentation for any library, framework, SDK, or CLI tool from the source — avoids stale training data. | https://github.com/upstash/context7 | Yes (API key, free tier available) |
| `github` | Official GitHub MCP. Access repos, issues, pull requests, CI runs, and code security from inside Claude. | https://github.com/github/github-mcp-server | Yes (GitHub PAT or OAuth) |
| `playwright` | Browser automation: navigate pages, inspect the DOM, click, type, take screenshots, capture console errors. Has local and hosted modes. | https://github.com/microsoft/playwright-mcp | No key locally; cloud mode needs an account |

### Add `context7`

```bash
claude mcp add --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: <your-key>"
```

Free keys are issued via OAuth at https://context7.com.

### Add `github`

```bash
claude mcp add github -- npx -y @modelcontextprotocol/server-github
```

Then set `GITHUB_PERSONAL_ACCESS_TOKEN` in your environment. A
fine-grained PAT scoped to the repos you want Claude to touch is
recommended over a classic token with full `repo` scope.

### Add `playwright`

```bash
claude mcp add playwright -- npx -y @playwright/mcp@latest
```

The first run will prompt Playwright to install its browser binaries.

---

## 3. Niche / opt-in (SaaS connectors)

Only install these if you actually use the product. Each requires an
account and OAuth or an API token from the respective service.

| Server | One-liner | Setup docs |
|---|---|---|
| `figma` | Pull design context (frames, variables, components) from Figma Dev Mode into your prompt. | https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Dev-Mode-MCP-Server |
| `notion` | Read and write Notion pages, databases, and blocks from inside Claude. | https://github.com/makenotion/notion-mcp-server |
| `linear` | Browse and update Linear issues, projects, and cycles. | https://linear.app/docs/mcp |
| `asana` | Read and write Asana tasks and projects via OAuth at `https://mcp.asana.com/v2/mcp`. | https://developers.asana.com/docs/using-asanas-model-control-protocol-mcp-server |
| `slack` | Read channels and DMs, post messages, search history. | https://docs.slack.dev/tools/slack-mcp-server/ |

---

## Verifying an MCP server is connected

After adding a server, run:

```text
/mcp
```

in a Claude Code session. The output lists each registered server, its
connection status, and the tools it exposes. If a server is `connecting`
for more than a few seconds, check its logs:

```bash
claude mcp logs <server-name>
```

## Removing an MCP server

```bash
claude mcp remove <server-name>
```

This deletes the entry from your Claude Code config but does not
uninstall any underlying package (e.g. the `npx`-fetched binary stays in
your npm cache).
