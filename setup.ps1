# setup.ps1 — Initialize Claude Code config on a NEW device
# Usage: git clone <repo> ~/.claude-config-sync; cd ~/.claude-config-sync; .\setup.ps1
param([switch]$SkipKeyPrompt)

$ErrorActionPreference = "Stop"
$RepoDir = "$env:USERPROFILE\.claude-config-sync"
$ClaudeDir = "$env:USERPROFILE\.claude"

Write-Host "`n=== Claude Config Sync — SETUP ===`n" -ForegroundColor Cyan
Write-Host "This will set up Claude Code with your synced configuration."
Write-Host "Target: $ClaudeDir`n"

# Phase 1: API Keys
$deepseekKey = ""
$geminiKey = ""
$kimiKey = ""

if (-not $SkipKeyPrompt) {
    Write-Host "--- API Keys ---" -ForegroundColor Yellow
    Write-Host "At minimum you need a DeepSeek API key. Gemini and Kimi are optional."

    $deepseekKey = Read-Host "DeepSeek/Anthropic API key"
    if ([string]::IsNullOrWhiteSpace($deepseekKey)) {
        Write-Host "ERROR: DeepSeek key is required. Exiting." -ForegroundColor Red
        exit 1
    }
    $geminiKey = Read-Host "Gemini API key (press Enter to skip)"
    $kimiKey = Read-Host "Kimi API key (press Enter to skip)"
}

# Phase 2: Write settings.json
Write-Host "`n[1/7] Creating settings.json..." -ForegroundColor Yellow
$template = Get-Content "$RepoDir\settings.template.json" -Raw | ConvertFrom-Json
$template.env.ANTHROPIC_AUTH_TOKEN = $deepseekKey
$template.env.GEMINI_KEY = if ($geminiKey) { $geminiKey } else { "YOUR_GEMINI_KEY_HERE" }
$template.env.KIMI_KEY = if ($kimiKey) { $kimiKey } else { "YOUR_KIMI_KEY_HERE" }

# Ensure .claude directory exists
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
$template | ConvertTo-Json -Depth 10 | Set-Content "$ClaudeDir\settings.json" -Encoding UTF8

# Phase 3: Copy CLAUDE.md + config
Write-Host "[2/7] Copying CLAUDE.md + config..." -ForegroundColor Yellow
Copy-Item "$RepoDir\CLAUDE.md" "$ClaudeDir\" -Force
if (Test-Path "$RepoDir\config.json") { Copy-Item "$RepoDir\config.json" "$ClaudeDir\" -Force }

# Phase 4: Deploy skills
Write-Host "[3/7] Deploying skills..." -ForegroundColor Yellow
Robocopy "$RepoDir\skills" "$ClaudeDir\skills" /E /XO /XF "*.symlink" /NJH /NJS /NP | Out-Null

# Handle symlink skills
Get-ChildItem "$RepoDir\skills\*.symlink" -ErrorAction SilentlyContinue | ForEach-Object {
    $meta = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $skillName = $_.BaseName
    $targetPath = $meta.target -replace "~", $env:USERPROFILE

    # Remove the copied content if any
    $skillDir = "$ClaudeDir\skills\$skillName"
    if (Test-Path $skillDir) { Remove-Item $skillDir -Recurse -Force -ErrorAction SilentlyContinue }

    if (Test-Path $targetPath) {
        New-Item -ItemType SymbolicLink -Path $skillDir -Target $targetPath -Force | Out-Null
        Write-Host "  Symlink: $skillName -> $targetPath" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: $skillName target not found: $targetPath" -ForegroundColor DarkYellow
        Write-Host "    Create a .missing placeholder" -ForegroundColor DarkYellow
        @{ missing = $true; target = $meta.target; hint = "Install agent-swarms to get this skill" } |
            ConvertTo-Json | Set-Content "$skillDir.missing" -Encoding UTF8
    }
}

# Phase 5: Restore memory
Write-Host "[4/7] Restoring memory files..." -ForegroundColor Yellow
Get-ChildItem "$RepoDir\memory" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $projectName = $_.Name
    $projectMemoryDir = "$ClaudeDir\projects\$projectName\memory"
    New-Item -ItemType Directory -Force -Path $projectMemoryDir | Out-Null
    Robocopy $_.FullName $projectMemoryDir /E /XO /NJH /NJS /NP | Out-Null
    Write-Host "  projects/$projectName/memory" -ForegroundColor Gray
}

# Phase 6: Copy plugins/connect/scripts
Write-Host "[5/7] Copying plugins/connect/scripts..." -ForegroundColor Yellow
if (Test-Path "$RepoDir\plugins\installed_plugins.json") {
    New-Item -ItemType Directory -Force -Path "$ClaudeDir\plugins" | Out-Null
    Copy-Item "$RepoDir\plugins\installed_plugins.json" "$ClaudeDir\plugins\" -Force
}
if (Test-Path "$RepoDir\connect") {
    Robocopy "$RepoDir\connect" "$ClaudeDir\connect" /E /XO /NJH /NJS /NP | Out-Null
}
if (Test-Path "$RepoDir\connect-apps") {
    Robocopy "$RepoDir\connect-apps" "$ClaudeDir\connect-apps" /E /XO /NJH /NJS /NP | Out-Null
}
if (Test-Path "$RepoDir\scripts") {
    Robocopy "$RepoDir\scripts" "$ClaudeDir\scripts" /E /XO /NJH /NJS /NP | Out-Null
}

# Phase 7: Reinstall plugins
Write-Host "[6/7] Reinstalling plugins..." -ForegroundColor Yellow
if (Get-Command "claude" -ErrorAction SilentlyContinue) {
    $plugins = Get-Content "$RepoDir\plugins\installed_plugins.json" -Raw | ConvertFrom-Json
    foreach ($plugin in $plugins) {
        Write-Host "  Installing: $plugin" -ForegroundColor Gray
        claude plugins install $plugin 2>&1 | Out-Null
    }
} else {
    Write-Host "  SKIP: 'claude' command not found. Install Claude Code first." -ForegroundColor DarkYellow
}

# Done
Write-Host "`n[7/7] Done!" -ForegroundColor Green
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Restart Claude Code for changes to take effect.`n"
