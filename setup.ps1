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

# Phase 2: Set system-level env vars (so Claude Code skips login on first launch)
Write-Host "`n[1/11] Setting environment variables..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $deepseekKey, "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://api.deepseek.com/anthropic", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", "deepseek-v4-pro", "User")
Write-Host "  Set ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL, ANTHROPIC_MODEL at user level"

# Phase 2.5: Fix git proxy (prevents the "browser works, git doesn't" problem)
Write-Host "[2/11] Fixing git proxy..." -ForegroundColor Yellow
$fixProxyScript = "$RepoDir\scripts\ensure-git-proxy.ps1"
if (Test-Path $fixProxyScript) {
    & powershell -ExecutionPolicy Bypass -File $fixProxyScript
} else {
    Write-Host "  SKIP: ensure-git-proxy.ps1 not found" -ForegroundColor DarkYellow
}

# Phase 3: Write settings.json
Write-Host "[3/11] Creating settings.json..." -ForegroundColor Yellow
$template = Get-Content "$RepoDir\settings.template.json" -Raw | ConvertFrom-Json
$template.env.ANTHROPIC_AUTH_TOKEN = $deepseekKey
$template.env.GEMINI_KEY = if ($geminiKey) { $geminiKey } else { "YOUR_GEMINI_KEY_HERE" }
$template.env.KIMI_KEY = if ($kimiKey) { $kimiKey } else { "YOUR_KIMI_KEY_HERE" }

# Ensure .claude directory exists
New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
$template | ConvertTo-Json -Depth 10 | Set-Content "$ClaudeDir\settings.json" -Encoding UTF8

# Phase 3: Copy CLAUDE.md + config
Write-Host "[4/11] Copying CLAUDE.md + config..." -ForegroundColor Yellow
Copy-Item "$RepoDir\CLAUDE.md" "$ClaudeDir\" -Force
if (Test-Path "$RepoDir\config.json") { Copy-Item "$RepoDir\config.json" "$ClaudeDir\" -Force }

# Phase 5: Deploy skills
Write-Host "[5/11] Deploying skills..." -ForegroundColor Yellow
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
Write-Host "[6/11] Restoring memory files..." -ForegroundColor Yellow
Get-ChildItem "$RepoDir\memory" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $projectName = $_.Name
    $projectMemoryDir = "$ClaudeDir\projects\$projectName\memory"
    New-Item -ItemType Directory -Force -Path $projectMemoryDir | Out-Null
    Robocopy $_.FullName $projectMemoryDir /E /XO /NJH /NJS /NP | Out-Null
    Write-Host "  projects/$projectName/memory" -ForegroundColor Gray
}

# Phase 6: Copy plugins/connect/scripts
Write-Host "[7/11] Copying plugins/connect/scripts..." -ForegroundColor Yellow
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
Write-Host "[8/11] Reinstalling plugins..." -ForegroundColor Yellow
if (Get-Command "claude" -ErrorAction SilentlyContinue) {
    $plugins = Get-Content "$RepoDir\plugins\installed_plugins.json" -Raw | ConvertFrom-Json
    foreach ($plugin in $plugins) {
        Write-Host "  Installing: $plugin" -ForegroundColor Gray
        claude plugins install $plugin 2>&1 | Out-Null
    }
} else {
    Write-Host "  SKIP: 'claude' command not found. Install Claude Code first." -ForegroundColor DarkYellow
}

# Phase 8: Install essential apps (Clawd on Desk + DeepSeek Monitor)
Write-Host "[9/11] Installing essential apps..." -ForegroundColor Yellow
$installAppsScript = "$RepoDir\scripts\install-apps.ps1"
if (Test-Path $installAppsScript) {
    & powershell -ExecutionPolicy Bypass -File $installAppsScript
} else {
    Write-Host "  WARNING: install-apps.ps1 not found, skipping." -ForegroundColor DarkYellow
}

# Phase 9: Start todo server
Write-Host "[10/11] Starting todo sidebar server..." -ForegroundColor Yellow
$todoServer = "$RepoDir\scripts\todo-server.js"
if (Test-Path $todoServer) {
    Start-Process node -ArgumentList $todoServer -WindowStyle Hidden
    Write-Host "  Todo server started on http://localhost:3899" -ForegroundColor Green
    Write-Host "  In VSCode: Ctrl+Shift+P → Simple Browser: Show → http://localhost:3899" -ForegroundColor Gray
    Write-Host "  Drag the panel to the sidebar to pin it." -ForegroundColor Gray
} else {
    Write-Host "  WARNING: todo-server.js not found, skipping." -ForegroundColor DarkYellow
}

# Done
Write-Host "`n[11/11] Done!" -ForegroundColor Green
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "IMPORTANT: Restart your terminal (or log out/in) for env vars to take effect."
Write-Host "Then launch Claude Code — it will auto-login via DeepSeek.`n"
