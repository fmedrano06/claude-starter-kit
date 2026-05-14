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
$Marker     = '<!-- claude-starter-kit v0.4.0 -->'

Write-Host ''
Write-Host '== Claude Starter Kit installer ==' -ForegroundColor Cyan
Write-Host "Repo:        $RepoRoot"
Write-Host "Claude home: $ClaudeHome"
if ($DryRun) { Write-Host 'Mode:        DRY RUN (no files will be written)' -ForegroundColor Yellow }
Write-Host ''

# ---------------------------------------------------------------------------
# Step 0: choose language for the wizard prompts
# ---------------------------------------------------------------------------
$langInput = Read-Host -Prompt 'Language / Idioma [EN/es]'
$Lang = if ($langInput -match '^(es|ES|spanish|español|espanol)$') { 'es' } else { 'en' }
Write-Host ''
$T = if ($Lang -eq 'es') {
    @{
        wizard_header   = '-- Asistente --'
        unknown_qtype   = 'Tipo de pregunta desconocido'
        reinstall_q     = 'El starter kit ya está instalado. ¿Reinstalar?'
        aborted         = 'Cancelado, no se cambió nada.'
        install_done    = '== Instalación completa =='
        skills_label    = '  Skills:     '
        mcps_label      = '  MCPs:       '
        hook_label      = '  Stop hook:  '
        backup_label    = '  Backup:     '
        guide_label     = '  Guide:      '
        open_browser_q  = '¿Abrir la guía en tu navegador?'
        ready_banner    = '  ¿Listo para tu primera sesión guiada?'
        ready_step1     = '  1. Instala Obsidian (gratis) desde https://obsidian.md'
        ready_step2     = '  2. Elige una carpeta para tu vault de conocimiento. Ábrela en Obsidian.'
        ready_step3     = '  3. Desde una terminal, corre:'
        ready_step3a    = '       cd <tu-carpeta-vault>'
        ready_step3b    = '       claude'
        ready_step4     = '  4. Pega esto como tu primer mensaje a Claude:'
        ready_step4a    = '       read ~/.claude/onboarding/first-session-prompt.md and walk me through it'
        ready_read_self = '  O léelo tú mismo en:'
        failed_prefix   = 'FALLÓ: '
        restoring       = 'Restaurando backup...'
        multi_blank     = 'Ingresa números separados por coma (o vacío para ninguno)'
    }
} else {
    @{
        wizard_header   = '-- Wizard --'
        unknown_qtype   = 'Unknown question type'
        reinstall_q     = 'Starter kit is already installed. Re-install?'
        aborted         = 'Aborted, nothing changed.'
        install_done    = '== Install complete =='
        skills_label    = '  Skills:      '
        mcps_label      = '  MCPs:        '
        hook_label      = '  Stop hook:   '
        backup_label    = '  Backup:      '
        guide_label     = '  Guide:       '
        open_browser_q  = 'Open the guide in your default browser?'
        ready_banner    = '  Ready for your first guided session?'
        ready_step1     = '  1. Install Obsidian (free) from https://obsidian.md'
        ready_step2     = '  2. Pick a folder to be your knowledge vault. Open it in Obsidian.'
        ready_step3     = '  3. From a terminal, run:'
        ready_step3a    = '       cd <your-vault-folder>'
        ready_step3b    = '       claude'
        ready_step4     = '  4. Paste this as your first message to Claude:'
        ready_step4a    = '       read ~/.claude/onboarding/first-session-prompt.md and walk me through it'
        ready_read_self = '  Or read it yourself at:'
        failed_prefix   = 'FAILED: '
        restoring       = 'Restoring backup...'
        multi_blank     = 'Enter comma-separated numbers (or blank for none)'
    }
}
function Get-QPrompt {
    param($Question)
    if ($Lang -eq 'es' -and $Question.PSObject.Properties.Name -contains 'prompt_es' -and $Question.prompt_es) {
        return $Question.prompt_es
    }
    return $Question.prompt
}
function Get-OptionDescription {
    param($Option)
    if ($Lang -eq 'es' -and $Option.PSObject.Properties.Name -contains 'description_es' -and $Option.description_es) {
        return $Option.description_es
    }
    return $Option.description
}

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
    param([string]$Prompt, [array]$Options, $Default)
    Write-Host $Prompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $opt = $Options[$i]
        $desc = Get-OptionDescription -Option $opt
        $label = if ($Lang -eq 'es' -and $opt.PSObject.Properties.Name -contains 'label_es' -and $opt.label_es) { $opt.label_es } else { $opt.label }
        Write-Host ('  {0}. {1} — {2}' -f ($i + 1), $label, $desc)
    }
    $defaultLabel = ''
    if ($Default -is [System.Collections.IList] -and $Default.Count -gt 0) {
        $idxs = @()
        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($Default -contains $Options[$i].id) { $idxs += ($i + 1) }
        }
        if ($idxs.Count -gt 0) { $defaultLabel = " [default: $($idxs -join ',')]" }
    }
    $answer = Read-Host -Prompt ($T.multi_blank.TrimEnd(': ') + $defaultLabel + ': ')
    if ([string]::IsNullOrWhiteSpace($answer)) {
        if ($Default -is [System.Collections.IList]) { return @($Default) }
        return @()
    }
    $selected = @()
    foreach ($token in $answer -split ',') {
        $n = 0
        if ([int]::TryParse($token.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
            $selected += $Options[$n - 1].id
        }
    }
    return $selected
}

function Read-SingleSelect {
    param([string]$Prompt, [array]$Options, [string]$Default)
    Write-Host $Prompt
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $opt = $Options[$i]
        $desc = Get-OptionDescription -Option $opt
        $label = if ($Lang -eq 'es' -and $opt.PSObject.Properties.Name -contains 'label_es' -and $opt.label_es) { $opt.label_es } else { $opt.label }
        $marker = if ($opt.id -eq $Default) { '*' } else { ' ' }
        Write-Host ('  {0}{1}. {2} — {3}' -f $marker, ($i + 1), $label, $desc)
    }
    $defaultIdx = ''
    for ($i = 0; $i -lt $Options.Count; $i++) {
        if ($Options[$i].id -eq $Default) { $defaultIdx = ($i + 1).ToString(); break }
    }
    $promptText = if ($defaultIdx) { "Enter number [default: $defaultIdx]" } else { 'Enter number' }
    $answer = Read-Host -Prompt $promptText
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    $n = 0
    if ([int]::TryParse($answer.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
        return $Options[$n - 1].id
    }
    return $Default
}

function Read-Secret {
    param([string]$Prompt)
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-Explainer {
    param($Question)
    if ($Lang -eq 'es' -and $Question.PSObject.Properties.Name -contains 'explainer_es' -and $Question.explainer_es) {
        return $Question.explainer_es
    }
    if ($Question.PSObject.Properties.Name -contains 'explainer' -and $Question.explainer) {
        return $Question.explainer
    }
    return $null
}

function Test-Conditional {
    param($Question, [hashtable]$Answers)
    if (-not ($Question.PSObject.Properties.Name -contains 'conditional')) { return $true }
    $cond = $Question.conditional
    if (-not $cond) { return $true }
    $key = $cond.if_answer
    if (-not $Answers.ContainsKey($key)) { return $false }
    $val = $Answers[$key]
    if ($cond.PSObject.Properties.Name -contains 'equals') {
        return ($val -eq $cond.equals)
    }
    if ($cond.PSObject.Properties.Name -contains 'contains') {
        if ($val -is [System.Collections.IList]) { return ($val -contains $cond.contains) }
        return $false
    }
    return $true
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

function Render-ConditionalBlocks {
    # Resolves {{IF_LEVEL:beginner}}...{{END}} and
    # {{IF_LEVEL:intermediate|senior}}...{{END}} against the active level.
    # Also handles {{IF_LEVEL:setup_vault:true}}...{{END}} — boolean conditional
    # against any answer key. The first segment after IF_LEVEL: is interpreted
    # as a level list when it matches known levels, otherwise as <key>:<value>.
    param([string]$Content, [string]$Level, [hashtable]$Answers)
    $pattern = '\{\{IF_LEVEL:([^}]+)\}\}([\s\S]*?)\{\{END\}\}'
    $regex = [regex]::new($pattern)
    $result = $regex.Replace($Content, {
        param($m)
        $spec = $m.Groups[1].Value
        $body = $m.Groups[2].Value
        $knownLevels = @('beginner','intermediate','senior')
        # Form A: level list, e.g. "beginner" or "intermediate|senior"
        if ($spec -notmatch ':') {
            $levels = $spec -split '\|'
            foreach ($lv in $levels) {
                if ($lv.Trim() -eq $Level) { return $body }
            }
            return ''
        }
        # Form B: answer key : value, e.g. "setup_vault:true"
        $parts = $spec -split ':', 2
        $key = $parts[0].Trim()
        $expected = $parts[1].Trim()
        if (-not $Answers.ContainsKey($key)) { return '' }
        $actual = $Answers[$key]
        if ($actual -is [bool]) { $actual = if ($actual) { 'true' } else { 'false' } }
        if ([string]$actual -eq $expected) { return $body }
        return ''
    })
    return $result
}

function Merge-Settings {
    param([hashtable]$Existing, [hashtable]$Template, [array]$EnabledMcps)
    # First pass: copy every top-level key EXCEPT mcpServers verbatim.
    # mcpServers needs selective merge (only the enabled ones).
    foreach ($k in $Template.Keys) {
        if ($k -eq 'mcpServers') { continue }
        if (-not $Existing.ContainsKey($k)) {
            $Existing[$k] = $Template[$k]
        }
    }
    if ($Template.ContainsKey('mcpServers')) {
        if (-not $Existing.ContainsKey('mcpServers')) { $Existing['mcpServers'] = @{} }
        # Snapshot the keys to iterate safely (avoid mutating during enumeration).
        $mcpKeys = @($Template['mcpServers'].Keys)
        foreach ($name in $mcpKeys) {
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
Write-Host $T.wizard_header -ForegroundColor Cyan
$answers = @{}

# Step 3a: experience level (drives the rest of the wizard)
$levelQ = $wizard.level_question
$lvlExplainer = Get-Explainer -Question $levelQ
if ($lvlExplainer) { Write-Host ('    ' + $lvlExplainer) -ForegroundColor DarkGray }
$lvlPrompt = Get-QPrompt -Question $levelQ
$answers[$levelQ.id] = Read-SingleSelect -Prompt $lvlPrompt -Options $levelQ.options -Default $levelQ.default
$Level = $answers[$levelQ.id]
Write-Host ''

# Step 3b: branch-specific questions
$branchQs = $wizard.branches.$Level
if (-not $branchQs) { throw "No questions defined for level: $Level" }
foreach ($q in $branchQs) {
    if (-not (Test-Conditional -Question $q -Answers $answers)) { continue }
    $prompt = Get-QPrompt -Question $q
    $explainer = Get-Explainer -Question $q
    if ($explainer) { Write-Host ('    ' + $explainer) -ForegroundColor DarkGray }
    $isSecret = ($q.PSObject.Properties.Name -contains 'secret' -and [bool]$q.secret)
    switch ($q.type) {
        'text' {
            if ($isSecret) {
                $val = Read-Secret -Prompt $prompt
                if ([string]::IsNullOrEmpty($val)) { $val = [string]$q.default }
                $answers[$q.id] = $val
            } else {
                $answers[$q.id] = Read-DefaultedLine -Prompt $prompt -Default ([string]$q.default)
            }
        }
        'boolean'       { $answers[$q.id] = Read-Boolean      -Prompt $prompt -Default ([bool]$q.default) }
        'multi-select'  { $answers[$q.id] = Read-MultiSelect  -Prompt $prompt -Options $q.options -Default $q.default }
        'single-select' { $answers[$q.id] = Read-SingleSelect -Prompt $prompt -Options $q.options -Default ([string]$q.default) }
        default { throw ($T.unknown_qtype + ": $($q.type) (id $($q.id))") }
    }
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Step 4: idempotency check + backup
# ---------------------------------------------------------------------------
$claudeMdPath = Join-Path $ClaudeHome 'CLAUDE.md'
$BackupPath   = $null

if (Test-Path -LiteralPath $claudeMdPath) {
    $existingContent = Get-Content -LiteralPath $claudeMdPath -Raw -Encoding UTF8
    if ($existingContent.StartsWith($Marker) -and -not $Force) {
        $ok = Read-Boolean -Prompt $T.reinstall_q -Default $false
        if (-not $ok) { Write-Host $T.aborted; exit 0 }
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
    Write-Host $T.restoring -ForegroundColor Yellow
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
        $cwdSlug = Get-CwdSlug
        $memoryDir = Join-Path $ClaudeHome ("projects\$cwdSlug\memory")

        # Derive variables that vary by branch / by answer
        $budget = if ($answers.ContainsKey('monthly_ai_budget')) { [string]$answers.monthly_ai_budget } else { 'under_100' }
        $defaultModel = switch ($budget) {
            'none'      { 'haiku' }
            'under_20'  { 'haiku' }
            'under_100' { 'sonnet' }
            'over_100'  { 'opus' }
            default     { 'sonnet' }
        }
        $costFlagThreshold = switch ($budget) {
            'none'      { '5' }
            'under_20'  { '10' }
            'under_100' { '25' }
            'over_100'  { '100' }
            default     { '25' }
        }
        $vaultPath = if ($answers.ContainsKey('vault_path') -and -not [string]::IsNullOrWhiteSpace([string]$answers.vault_path)) {
            [string]$answers.vault_path
        } else {
            '(none)'
        }
        $primaryGoal = if ($answers.ContainsKey('primary_goal')) { [string]$answers.primary_goal } else { '' }
        $primaryGoalHuman = switch ($primaryGoal) {
            'learn_to_code'     { 'learn to code' }
            'personal_projects' { 'build personal projects' }
            'work_or_business'  { 'do work or build a business' }
            default             { 'work with Claude Code' }
        }

        # Step 5a: resolve {{IF_LEVEL:...}} conditional blocks
        $resolved = Render-ConditionalBlocks -Content $tpl -Level $Level -Answers $answers

        # Step 5b: substitute placeholders
        $rendered = Render-Template -Content $resolved -Vars @{
            USER_NAME              = [string]$answers.user_name
            USER_ROLE              = if ($answers.ContainsKey('user_role'))         { [string]$answers.user_role }         else { '' }
            PRIMARY_LANGUAGE       = if ($answers.ContainsKey('primary_language'))  { [string]$answers.primary_language }  else { 'unsure' }
            COMMUNICATION_LANGUAGE = if ($answers.ContainsKey('communication_language')) { [string]$answers.communication_language } else { 'English' }
            TODAY                  = (Get-Date -Format 'yyyy-MM-dd')
            MEMORY_DIR             = $memoryDir
            LEVEL                  = $Level
            DEFAULT_MODEL          = $defaultModel
            COST_FLAG_THRESHOLD    = $costFlagThreshold
            VAULT_PATH             = $vaultPath
            PRIMARY_GOAL_HUMAN     = $primaryGoalHuman
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
        $tplRaw = Get-Content -LiteralPath $settingsTplPath -Raw -Encoding UTF8
        # Escape inner double quotes so the resulting JSON stays valid.
        $stopHookCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "~/.claude/hooks/notify-stop.ps1"'
        $stopHookCommandJson = $stopHookCommand.Replace('"', '\"')
        $tplRaw = $tplRaw.Replace('{{STOP_HOOK_COMMAND}}', $stopHookCommandJson)
        $tplHash = $tplRaw | ConvertFrom-Json -AsHashtable
        $existingHash = @{}
        if (Test-Path -LiteralPath $settingsDstPath) {
            $existingHash = Get-Content -LiteralPath $settingsDstPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        }
        $merged = Merge-Settings -Existing $existingHash -Template $tplHash -EnabledMcps @($answers.mcps_to_enable)

        # v0.4.0 — default model from budget
        $merged['model'] = $defaultModel

        # v0.4.0 — permission profile
        $permProfile = if ($answers.ContainsKey('permission_profile')) { [string]$answers.permission_profile } else { 'balanced' }
        switch ($permProfile) {
            'cautious' {
                $merged['skipAutoPermissionPrompt']      = $false
                $merged['skipDangerousModePermissionPrompt'] = $false
            }
            'balanced' {
                $merged['skipAutoPermissionPrompt']      = $true
                $merged['skipDangerousModePermissionPrompt'] = $false
            }
            'expert' {
                $merged['skipAutoPermissionPrompt']      = $true
                $merged['skipDangerousModePermissionPrompt'] = $true
            }
        }

        # v0.4.0 — status line preset
        $slPreset = if ($answers.ContainsKey('status_line')) { [string]$answers.status_line } else { 'balanced' }
        $slScript = switch ($slPreset) {
            'minimal'  { 'bash ~/.claude/statusline-command.sh minimal' }
            'balanced' { 'bash ~/.claude/statusline-command.sh balanced' }
            'verbose'  { 'bash ~/.claude/statusline-command.sh verbose' }
            default    { 'bash ~/.claude/statusline-command.sh balanced' }
        }
        if (-not $merged.ContainsKey('statusLine')) { $merged['statusLine'] = @{} }
        $merged['statusLine']['type'] = 'command'
        $merged['statusLine']['command'] = $slScript

        # v0.4.0 — wire MCP API keys into env (only when user supplied)
        if ($merged.ContainsKey('mcpServers')) {
            if ($merged['mcpServers'].ContainsKey('context7')) {
                $k = if ($answers.ContainsKey('context7_api_key')) { [string]$answers.context7_api_key } else { '' }
                if ($k) {
                    if (-not $merged['mcpServers']['context7'].ContainsKey('headers')) {
                        $merged['mcpServers']['context7']['headers'] = @{}
                    }
                    $merged['mcpServers']['context7']['headers']['CONTEXT7_API_KEY'] = $k
                }
            }
            if ($merged['mcpServers'].ContainsKey('github')) {
                $k = if ($answers.ContainsKey('github_pat')) { [string]$answers.github_pat } else { '' }
                if ($k) {
                    if (-not $merged['mcpServers']['github'].ContainsKey('env')) {
                        $merged['mcpServers']['github']['env'] = @{}
                    }
                    $merged['mcpServers']['github']['env']['GITHUB_PERSONAL_ACCESS_TOKEN'] = $k
                }
            }
        }

        # Drop Stop hook entirely if user opted out
        if (-not [bool]$answers.enable_stop_hook -and $merged.ContainsKey('hooks')) {
            if ($merged['hooks'].ContainsKey('Stop')) { $merged['hooks'].Remove('Stop') | Out-Null }
        }
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
    # Step 9.5 (v0.4.0): knowledge vault scaffold
    # -----------------------------------------------------------------------
    $vaultPathFinal = $null
    if ($answers.ContainsKey('setup_vault') -and [bool]$answers.setup_vault) {
        $vaultPathRaw = if ($answers.ContainsKey('vault_path') -and -not [string]::IsNullOrWhiteSpace([string]$answers.vault_path)) {
            [string]$answers.vault_path
        } else {
            '~/Documents/claude-vault'
        }
        # Expand ~ to $env:USERPROFILE
        $vaultPathFinal = $vaultPathRaw.Replace('~', $env:USERPROFILE).Replace('/', '\')
        Write-Action 'VAULT' $vaultPathFinal
        Invoke-FsAction {
            foreach ($sub in @('raw','wiki','outputs','projects','_daily','_session-handoffs')) {
                New-Item -ItemType Directory -Path (Join-Path $vaultPathFinal $sub) -Force | Out-Null
            }
            $vaultClaudeMd = @"
<!-- claude-starter-kit vault — generated $(Get-Date -Format 'yyyy-MM-dd') -->

# Knowledge vault — local rules

This folder is a knowledge vault. It uses the Karpathy 3-folder layout
plus a few utility folders:

- ``raw/`` — unprocessed notes, dumps, transcripts, paste-ins.
- ``wiki/`` — distilled, durable knowledge written for future-self.
- ``outputs/`` — finished artifacts produced from raw + wiki.
- ``projects/`` — one folder per active project.
- ``_daily/`` — daily notes, format ``YYYY-MM-DD.md``.
- ``_session-handoffs/`` — Claude session handoffs.

When the user asks you to "save a note" or "remember this for later"
without specifying where, default to:

- Quick capture, in-progress thinking → ``raw/YYYY-MM-DD-<slug>.md``
- A reusable lesson, pattern, or reference → ``wiki/<topic>.md``
- A finished thing → ``outputs/<project>/<slug>.<ext>``

Project-specific CLAUDE.md files in ``projects/<name>/`` override these
defaults for that project.
"@
            Set-Content -LiteralPath (Join-Path $vaultPathFinal 'CLAUDE.md') -Value $vaultClaudeMd -Encoding UTF8
            $today = Get-Date -Format 'yyyy-MM-dd'
            $dailySeed = "# $today`n`n## Today's intent`n`n## Notes`n`n## Tomorrow`n"
            $dailyPath = Join-Path $vaultPathFinal ("_daily\$today.md")
            if (-not (Test-Path -LiteralPath $dailyPath)) {
                Set-Content -LiteralPath $dailyPath -Value $dailySeed -Encoding UTF8
            }
        }
    }

    # -----------------------------------------------------------------------
    # Step 10: summary
    # -----------------------------------------------------------------------
    Write-Host ''
    Write-Host $T.install_done -ForegroundColor Cyan
    Write-Host "  CLAUDE.md:   $claudeMdPath"
    Write-Host ($T.skills_label + (@($answers.skills_to_install) -join ', '))
    Write-Host ($T.mcps_label   + (@($answers.mcps_to_enable) -join ', '))
    Write-Host ($T.hook_label   + ([bool]$answers.enable_stop_hook))
    if ($BackupPath) { Write-Host ($T.backup_label + $BackupPath) }
    $guidePath = Join-Path $RepoRoot 'guide\index.html'
    Write-Host ($T.guide_label + $guidePath)
    if (-not $DryRun -and (Test-Path -LiteralPath $guidePath)) {
        $open = Read-Boolean -Prompt $T.open_browser_q -Default $true
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
            Write-Host $T.ready_banner -ForegroundColor Cyan
            Write-Host '==============================================================' -ForegroundColor Cyan
            Write-Host ''
            Write-Host $T.ready_step1
            Write-Host $T.ready_step2
            Write-Host $T.ready_step3
            Write-Host $T.ready_step3a
            Write-Host $T.ready_step3b
            Write-Host $T.ready_step4
            Write-Host $T.ready_step4a
            Write-Host ''
            Write-Host $T.ready_read_self
            Write-Host "    $onboardingDst"
            Write-Host ''
        } else {
            Write-Host "  SKIP    onboarding (template not present at $onboardingSrc)" -ForegroundColor DarkYellow
        }
    }
}
catch {
    Write-Host ''
    Write-Host ($T.failed_prefix + $_.Exception.Message) -ForegroundColor Red
    if ($BackupPath -and -not $DryRun) { Restore-Backup }
    exit 1
}
