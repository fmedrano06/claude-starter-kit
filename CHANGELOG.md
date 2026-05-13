# Changelog

All notable changes to this project are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] — 2026-05-12

### Added
- First-session onboarding flow (`templates/first-session-prompt.md`): walks a new user through Obsidian + Karpathy 3-folder vault setup, then their first plan-mode coding project.
- Wizard question `show_onboarding_after_install` (default true) controls whether the path is printed at the end.
- `~/.claude/onboarding/first-session-prompt.md` is copied during install.

## [0.1.0] — 2026-05-12

Initial public release.

### Added
- `SETUP.md` — installer instructions written to be read and executed
  by Claude Code itself (Path A install flow).
- `install/install.ps1` and `install/install.sh` — Windows and
  macOS/Linux installer scripts that bootstrap Claude Code if needed
  and run the wizard (Paths B and C).
- `install/lib/wizard-questions.json` — schema of questions the installer
  asks the user.
- `templates/CLAUDE.md.template` — opinionated global CLAUDE.md
  encoding senior-level engineering standards.
- `templates/settings.json.template` — pre-configured Claude Code
  settings with `enabledPlugins` and `extraKnownMarketplaces` so the
  recommended plugins auto-activate.
- `templates/hooks/` and `templates/memory/` — opinionated hooks and a
  per-CWD auto-memory layout that persists across sessions.
- `skills/` — five high-leverage skills bundled with the kit:
  `impeccable`, `ui-ux-pro-max`, `gh-issues`, `graphify`,
  `project-prime`.
- `plugins.md` — curated catalog of nine recommended plugins with
  descriptions sourced from their marketplace manifests.
- `mcps.md` — curated catalog of recommended MCP servers, grouped by
  whether they need an API key.
- `guide/index.html` — interactive in-browser tour of the kit.
- `docs/00-what-this-is.md` through `docs/04-troubleshooting.md` —
  extended documentation.
- `README.md`, `LICENSE` (MIT), `.gitignore`.

[0.2.0]: https://github.com/fmedrano06/claude-starter-kit/releases/tag/v0.2.0
[0.1.0]: https://github.com/fmedrano06/claude-starter-kit/releases/tag/v0.1.0
