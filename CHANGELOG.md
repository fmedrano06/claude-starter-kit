# Changelog

All notable changes to this project are documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.1] — 2026-05-13

### Fixed
- **Installer**: `{{TODAY}}` and `{{MEMORY_DIR}}` placeholders in
  `templates/CLAUDE.md.template` were left literal in the installed
  `~/.claude/CLAUDE.md`. The installer now passes both values to
  `Render-Template` (PowerShell) and `render_template` (bash).
- **Installer**: the wizard's `mcps_to_enable` question silently dropped
  user selections because `templates/settings.json.template` had no
  `mcpServers` block. Added the three servers from the wizard (context7,
  sequential-thinking, github) with the correct stdio/HTTP transport
  shape from `mcps.md`. Users who select MCPs now get them written.
- **Installer**: the Stop hook command was hard-coded to `powershell.exe`
  in `settings.json.template`, breaking Mac/Linux users. The template now
  uses a `{{STOP_HOOK_COMMAND}}` placeholder rewritten per OS by each
  installer (`powershell.exe ... .ps1` on Windows; `bash ... .sh` on Unix).
  When the user opts out, the whole `hooks.Stop` block is dropped.
- **`Merge-Settings`**: `foreach` over `$Template['mcpServers'].Keys`
  could throw `Collection was modified` when the existing settings had
  no `mcpServers` yet, because the first-pass copy shared the underlying
  hashtable. Now snapshots the key list and skips `mcpServers` in the
  generic loop.
- **Version drift**: `v0.1.0` marker still appeared in 6 places after
  the v0.2.0 ship (templates, install scripts, SETUP.md, README claim,
  guide footer). Bumped all to v0.2.1.

### Added
- `templates/hooks/notify-stop.sh.example` — Stop hook for macOS and
  Linux. Single script that detects OS at runtime (`osascript` on macOS,
  `notify-send` on Linux, quiet fallback elsewhere).
- `_session-handoffs/audit-v0.2.0/test_installer.ps1` — local validation
  gate that exercises every installer step against an isolated
  `$env:TEMP\.claude`. Mandatory pre-tag gate from v0.2.1 onwards.

### Changed
- `guide/index.html` cap iii (workflow): replaced the three accent-italic
  numbered cards (`.step` / `.step-roman`) with `.situation` entries —
  small mono romans in the margin, italic display titles, hairlines
  between entries. Aligns with the editorial visual language invariant
  (accent reserved for italic moments and active states).
- `guide/index.html` cap v (Errata): added editorial body paragraph
  before the troubleshooting list.
- `SETUP.md` step 9: rewrote to document the cross-platform Stop hook
  flow (was Windows-only).

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

[0.2.1]: https://github.com/fmedrano06/claude-starter-kit/releases/tag/v0.2.1
[0.2.0]: https://github.com/fmedrano06/claude-starter-kit/releases/tag/v0.2.0
[0.1.0]: https://github.com/fmedrano06/claude-starter-kit/releases/tag/v0.1.0
