#requires -Version 5.1
<#
.SYNOPSIS
    Claude Starter Kit installer (Windows / PowerShell).

.DESCRIPTION
    Reads install/lib/wizard-questions.json, prompts the user for each
    question, backs up ~/.claude/, renders templates, copies selected
    skills, and merges settings.json. Idempotent: detects the
    claude-starter-kit marker comment and offers to re-install.

.PARAMETER DryRun
    Print every planned filesystem action without writing anything.

.PARAMETER Force
    Skip the re-install confirmation prompt when the marker is detected.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Resolve repo paths relative to this script
# ---------------------------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$WizardJsonPath = Join-Path $ScriptDir 'lib\wizard-questions.json'

if (-not (Test-Path -LiteralPath $WizardJsonPath)) {
    throw "Cannot find wizard questions at $WizardJsonPath"
}

$ClaudeHome = Join-Path $env:USERPROFILE '.claude'
$Marker     = '<!-- claude-starter-kit v0.1.0 -->'

Write-Host ''
Write-Host '== Claude Starter Kit installer ==' -ForegroundColor Cyan
Write-Host "Repo:        $RepoRoot"
Write-Host "Claude home: $ClaudeHome"
if ($DryRun) { Write-Host 'Mode:        DRY RUN (no files will be written)' -ForegroundColor Yellow }
Write-Host ''

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Action {
    param([string]$Verb, [string]$Path)
    $color = if ($DryRun) { 'Yellow' } else { 'Green' }
    Write-Host ('  {0,-8} {1}' -f $Verb, $Path) -ForegroundColor $color
}

function Invoke-FsAction {
    param([scriptblock]$Action)
    if (-not $DryRun) { & $Action }
}

function Read-DefaultedLine {
    param([string]$Prompt, [string]$Default)
    $suffix = if ([string]::IsNullOrEmpty($Default)) { '' } else { " [$Default]" }
    $answer = Read-Host -Prompt ($Prompt + $suffix)
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer
}

function Read-Boolean {
    param([string]$Prompt, [bool]$Default)
    $defLabel = if ($Default) { 'Y/n' } else { 'y/N' }
    $answer = Read-Host -Prompt "$Prompt [$defLabel]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return ($answer -match '^(y|yes|true|1)$')
}

function Read-MultiSelect {
    param([string]$Prompt, [array]$Options)
    Write-Host $Prompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $opt = $Options[$i]
        Write-Host ('  {0}. {1} — {2}' -f ($i + 1), $opt.label, $opt.description)
    }
    $answer = Read-Host -Prompt 'Enter comma-separated numbers (or blank for none)'
    if ([string]::IsNullOrWhiteSpace($answer)) { return @() }
    $selected = @()
    foreach ($token in $answer -split ',') {
        $n = 0
        if ([int]::TryParse($token.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
            $selected += $Options[$n - 1].id
        }
    }
    return $selected
}

function Get-CwdSlug {
    $cwd = (Get-Location).Path
    $slug = $cwd -replace '^[A-Za-z]:', ''
    $slug = $slug -replace '[\\/ ]+', '-'
    return $slug.Trim('-').ToLowerInvariant()
}

function Render-Template {
    param([string]$Content, [hashtable]$Vars)
    foreach ($k in $Vars.Keys) {
        $Content = $Content.Replace('{{' + $k + '}}', [string]$Vars[$k])
    }
    return $Content
}

function Merge-Settings {
    param([hashtable]$Existing, [hashtable]$Template, [array]$EnabledMcps)
    foreach ($k in $Template.Keys) {
        if (-not $Existing.ContainsKey($k)) {
            $Existing[$k] = $Template[$k]
        }
    }
    if ($Template.ContainsKey('mcpServers')) {
        if (-not $Existing.ContainsKey('mcpServers')) { $Existing['mcpServers'] = @{} }
        foreach ($name in $Template['mcpServers'].Keys) {
            if ($EnabledMcps -contains $name) {
                $Existing['mcpServers'][$name] = $Template['mcpServers'][$name]
            }
        }
    }
    return $Existing
}

function Expand-ClaudeHomeTokens {
    # Replace ~/.claude/ (forward-slash form used in JSON) with the resolved
    # absolute install path. Walks hashtables and lists recursively so hook
    # paths and statusLine commands are rewritten regardless of nesting.
    # Uses literal .Replace() (not -replace) to avoid regex-escaping the
    # Windows path, which contains backslashes.
    param($Node, [string]$ClaudeHomeAbs)
    if ($null -eq $Node) { return $Node }
    $abs = $ClaudeHomeAbs.TrimEnd('\','/') + '\'
    if ($Node -is [string]) {
        return $Node.Replace('~/.claude/', $abs)
    }
    if ($Node -is [hashtable]) {
        foreach ($k in @($Node.Keys)) {
            $Node[$k] = Expand-ClaudeHomeTokens -Node $Node[$k] -ClaudeHomeAbs $ClaudeHomeAbs
        }
        return $Node
    }
    if ($Node -is [System.Collections.IList]) {
        for ($i = 0; $i -lt $Node.Count; $i++) {
            $Node[$i] = Expand-ClaudeHomeTokens -Node $Node[$i] -ClaudeHomeAbs $ClaudeHomeAbs
        }
        return $Node
    }
    return $Node
}

# ---------------------------------------------------------------------------
# Step 2: load wizard
# ---------------------------------------------------------------------------
$wizard = Get-Content -LiteralPath $WizardJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

# ---------------------------------------------------------------------------
# Step 3: prompt
# ---------------------------------------------------------------------------
Write-Host '-- Wizard --' -ForegroundColor Cyan
$answers = @{}
foreach ($q in $wizard.questions) {
    switch ($q.type) {
        'text'         { $answers[$q.id] = Read-DefaultedLine -Prompt $q.prompt -Default $q.default }
        'boolean'      { $answers[$q.id] = Read-Boolean       -Prompt $q.prompt -Default ([bool]$q.default) }
        'multi-select' { $answers[$q.id] = Read-MultiSelect   -Prompt $q.prompt -Options $q.options }
        'single-select' {
            $opts = $q.options | ForEach-Object { $_.id }
            $answers[$q.id] = Read-DefaultedLine -Prompt ($q.prompt + ' (' + ($opts -join '|') + ')') -Default $q.default
        }
        default { throw "Unknown question type: $($q.type) for id $($q.id)" }
    }
}
Write-Host ''

# ---------------------------------------------------------------------------
# Step 4: idempotency check + backup
# ---------------------------------------------------------------------------
$claudeMdPath = Join-Path $ClaudeHome 'CLAUDE.md'
$BackupPath   = $null

if (Test-Path -LiteralPath $claudeMdPath) {
    $existingContent = Get-Content -LiteralPath $claudeMdPath -Raw -Encoding UTF8
    if ($existingContent.StartsWith($Marker) -and -not $Force) {
        $ok = Read-Boolean -Prompt 'Starter kit is already installed. Re-install?' -Default $false
        if (-not $ok) { Write-Host 'Aborted, nothing changed.'; exit 0 }
    }
    $stamp = (Get-Date -Format 'yyyy-MM-ddTHH-mm-ss')
    $BackupPath = Join-Path $ClaudeHome (".backup-$stamp")
    Write-Action 'BACKUP' $BackupPath
    Invoke-FsAction {
        $exclusions = @('projects', 'sessions', 'cache', '.backup-*')
        $robocopyArgs = @($ClaudeHome, $BackupPath, '/E', '/NFL', '/NDL', '/NP', '/NJH', '/NJS', '/R:1', '/W:1', '/XD') + $exclusions
        & robocopy @robocopyArgs | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy backup failed with code $LASTEXITCODE" }
    }
}

# ---------------------------------------------------------------------------
# Helper: rollback closure for steps 5+
# ---------------------------------------------------------------------------
$createdPaths = New-Object System.Collections.Generic.List[string]
function Track-Write {
    param([string]$Path)
    $createdPaths.Add($Path) | Out-Null
}

function Restore-Backup {
    if ($null -eq $BackupPath -or -not (Test-Path -LiteralPath $BackupPath)) { return }
    Write-Host 'Restoring backup...' -ForegroundColor Yellow
    foreach ($p in $createdPaths) {
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
    }
    & robocopy $BackupPath $ClaudeHome '/E' '/NFL' '/NDL' '/NP' '/NJH' '/NJS' | Out-Null
}

try {
    # -----------------------------------------------------------------------
    # Step 5: render CLAUDE.md
    # -----------------------------------------------------------------------
    $templatePath = Join-Path $RepoRoot 'templates\CLAUDE.md.template'
    if (Test-Path -LiteralPath $templatePath) {
        $tpl = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
        $rendered = Render-Template -Content $tpl -Vars @{
            USER_NAME              = $answers.user_name
            USER_ROLE              = $answers.user_role
            PRIMARY_LANGUAGE       = $answers.primary_language
            COMMUNICATION_LANGUAGE = $answers.communication_language
        }
        if (-not $rendered.StartsWith($Marker)) {
            $rendered = "$Marker`n$rendered"
        }
        Write-Action 'WRITE' $claudeMdPath
        Invoke-FsAction {
            New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null
            Set-Content -LiteralPath $claudeMdPath -Value $rendered -Encoding UTF8
        }
        Track-Write $claudeMdPath
    } else {
        Write-Host "  SKIP    CLAUDE.md (template not present yet at $templatePath)" -ForegroundColor DarkYellow
    }

    # -----------------------------------------------------------------------
    # Step 6: copy skills
    # -----------------------------------------------------------------------
    $skillsSrc = Join-Path $RepoRoot 'skills'
    $skillsDst = Join-Path $ClaudeHome 'skills'
    foreach ($skillId in @($answers.skills_to_install)) {
        $src = Join-Path $skillsSrc $skillId
        $dst = Join-Path $skillsDst $skillId
        if (-not (Test-Path -LiteralPath $src)) {
            Write-Host "  SKIP    skills/$skillId (not in repo yet)" -ForegroundColor DarkYellow
            continue
        }
        Write-Action 'COPY' $dst
        Invoke-FsAction {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            Copy-Item -LiteralPath $src -Destination $skillsDst -Recurse -Force
        }
        Track-Write $dst
    }

    # -----------------------------------------------------------------------
    # Step 7: merge settings.json
    # -----------------------------------------------------------------------
    $settingsTplPath = Join-Path $RepoRoot 'templates\settings.json.template'
    $settingsDstPath = Join-Path $ClaudeHome 'settings.json'
    if (Test-Path -LiteralPath $settingsTplPath) {
        $tplHash = Get-Content -LiteralPath $settingsTplPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        $existingHash = @{}
        if (Test-Path -LiteralPath $settingsDstPath) {
            $existingHash = Get-Content -LiteralPath $settingsDstPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        }
        $merged = Merge-Settings -Existing $existingHash -Template $tplHash -EnabledMcps @($answers.mcps_to_enable)
        $merged = Expand-ClaudeHomeTokens -Node $merged -ClaudeHomeAbs $ClaudeHome
        Write-Action 'WRITE' $settingsDstPath
        Invoke-FsAction {
            ($merged | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $settingsDstPath -Encoding UTF8
        }
        Track-Write $settingsDstPath
    } else {
        Write-Host "  SKIP    settings.json (template not present yet at $settingsTplPath)" -ForegroundColor DarkYellow
    }

    # -----------------------------------------------------------------------
    # Step 8: seed memory
    # -----------------------------------------------------------------------
    $memTplPath = Join-Path $RepoRoot 'templates\memory\MEMORY.md.template'
    if (Test-Path -LiteralPath $memTplPath) {
        $slug = Get-CwdSlug
        $memDst = Join-Path $ClaudeHome ("projects\$slug\memory\MEMORY.md")
        if (-not (Test-Path -LiteralPath $memDst)) {
            Write-Action 'WRITE' $memDst
            Invoke-FsAction {
                New-Item -ItemType Directory -Path (Split-Path -Parent $memDst) -Force | Out-Null
                Copy-Item -LiteralPath $memTplPath -Destination $memDst -Force
            }
            Track-Write $memDst
        }
    }

    # -----------------------------------------------------------------------
    # Step 9: stop hook
    # -----------------------------------------------------------------------
    if ([bool]$answers.enable_stop_hook) {
        $hookSrc = Join-Path $RepoRoot 'templates\hooks\notify-stop.ps1.example'
        $hookDst = Join-Path $ClaudeHome 'hooks\notify-stop.ps1'
        if (Test-Path -LiteralPath $hookSrc) {
            Write-Action 'COPY' $hookDst
            Invoke-FsAction {
                New-Item -ItemType Directory -Path (Split-Path -Parent $hookDst) -Force | Out-Null
                Copy-Item -LiteralPath $hookSrc -Destination $hookDst -Force
            }
            Track-Write $hookDst
        } else {
            Write-Host "  SKIP    Stop hook (template not present yet)" -ForegroundColor DarkYellow
        }
    }

    # -----------------------------------------------------------------------
    # Step 10: summary
    # -----------------------------------------------------------------------
    Write-Host ''
    Write-Host '== Install complete ==' -ForegroundColor Cyan
    Write-Host "  CLAUDE.md:   $claudeMdPath"
    Write-Host ("  Skills:      " + (@($answers.skills_to_install) -join ', '))
    Write-Host ("  MCPs:        " + (@($answers.mcps_to_enable) -join ', '))
    Write-Host ("  Stop hook:   " + ([bool]$answers.enable_stop_hook))
    if ($BackupPath) { Write-Host "  Backup:      $BackupPath" }
    $guidePath = Join-Path $RepoRoot 'guide\index.html'
    Write-Host "  Guide:       $guidePath"
    if (-not $DryRun -and (Test-Path -LiteralPath $guidePath)) {
        $open = Read-Boolean -Prompt 'Open the guide in your default browser?' -Default $true
        if ($open) { Start-Process $guidePath }
    }

    # -----------------------------------------------------------------------
    # Step 11: optional onboarding hand-off
    # -----------------------------------------------------------------------
    $showOnboarding = $false
    if ($answers.ContainsKey('show_onboarding_after_install')) {
        $showOnboarding = [bool]$answers.show_onboarding_after_install
    }
    if ($showOnboarding) {
        $onboardingSrc = Join-Path $RepoRoot 'templates\first-session-prompt.md'
        $onboardingDstDir = Join-Path $ClaudeHome 'onboarding'
        $onboardingDst = Join-Path $onboardingDstDir 'first-session-prompt.md'
        if (Test-Path -LiteralPath $onboardingSrc) {
            Write-Action 'COPY' $onboardingDst
            Invoke-FsAction {
                New-Item -ItemType Directory -Path $onboardingDstDir -Force | Out-Null
                Copy-Item -LiteralPath $onboardingSrc -Destination $onboardingDst -Force
            }
            Track-Write $onboardingDst

            Write-Host ''
            Write-Host '==============================================================' -ForegroundColor Cyan
            Write-Host '  Ready for your first guided session?' -ForegroundColor Cyan
            Write-Host '==============================================================' -ForegroundColor Cyan
            Write-Host ''
            Write-Host '  1. Install Obsidian (free) from https://obsidian.md'
            Write-Host '  2. Pick a folder to be your knowledge vault. Open it in Obsidian.'
            Write-Host '  3. From a terminal, run:'
            Write-Host '       cd <your-vault-folder>'
            Write-Host '       claude'
            Write-Host '  4. Paste this as your first message to Claude:'
            Write-Host '       read ~/.claude/onboarding/first-session-prompt.md and walk me through it'
            Write-Host ''
            Write-Host '  Or read it yourself at:'
            Write-Host "    $onboardingDst"
            Write-Host ''
        } else {
            Write-Host "  SKIP    onboarding (template not present at $onboardingSrc)" -ForegroundColor DarkYellow
        }
    }
}
catch {
    Write-Host ''
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($BackupPath -and -not $DryRun) { Restore-Backup }
    exit 1
}
