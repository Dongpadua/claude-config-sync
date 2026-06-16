# sync-down.ps1 — Pull latest config changes into .claude (preserves local keys)
# Usage: cd ~/.claude-config-sync; git pull; .\sync-down.ps1
$ErrorActionPreference = "Stop"
$RepoDir = "$env:USERPROFILE\.claude-config-sync"
$ClaudeDir = "$env:USERPROFILE\.claude"

Write-Host "=== Claude Config Sync — PULL ===" -ForegroundColor Cyan

# 1. Pull latest from remote
Push-Location $RepoDir
Write-Host "[1/6] Pulling latest from GitHub..." -ForegroundColor Yellow
git pull origin main
Write-Host ""

# 2. Update CLAUDE.md + config (safe, no keys)
Write-Host "[2/6] Updating CLAUDE.md + config..." -ForegroundColor Yellow
Copy-Item "$RepoDir\CLAUDE.md" "$ClaudeDir\" -Force
if (Test-Path "$RepoDir\config.json") { Copy-Item "$RepoDir\config.json" "$ClaudeDir\" -Force }

# 3. Update settings — merge template with local keys
Write-Host "[3/6] Merging settings (preserving local keys)..." -ForegroundColor Yellow
$repoTemplate = Get-Content "$RepoDir\settings.template.json" -Raw | ConvertFrom-Json
$localSettings = Get-Content "$ClaudeDir\settings.json" -Raw | ConvertFrom-Json

# Keep local API keys, take everything else from template
$repoTemplate.env.ANTHROPIC_AUTH_TOKEN = $localSettings.env.ANTHROPIC_AUTH_TOKEN
$repoTemplate.env.GEMINI_KEY = $localSettings.env.GEMINI_KEY
$repoTemplate.env.KIMI_KEY = $localSettings.env.KIMI_KEY

$repoTemplate | ConvertTo-Json -Depth 10 | Set-Content "$ClaudeDir\settings.json" -Encoding UTF8

# 4. Update skills
Write-Host "[4/6] Updating skills..." -ForegroundColor Yellow
Robocopy "$RepoDir\skills" "$ClaudeDir\skills" /E /XO /XF "*.symlink" /XD ".git" /NJH /NJS /NP | Out-Null

# Handle symlinks (only create if missing)
Get-ChildItem "$RepoDir\skills\*.symlink" -ErrorAction SilentlyContinue | ForEach-Object {
    $meta = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $skillName = $_.BaseName
    $targetPath = $meta.target -replace "~", $env:USERPROFILE
    $skillDir = "$ClaudeDir\skills\$skillName"

    if (-not (Test-Path $skillDir) -and (Test-Path $targetPath)) {
        New-Item -ItemType SymbolicLink -Path $skillDir -Target $targetPath -Force | Out-Null
        Write-Host "  Symlink created: $skillName" -ForegroundColor Gray
    }
}

# 5. Update memory
Write-Host "[5/6] Updating memory..." -ForegroundColor Yellow
Get-ChildItem "$RepoDir\memory" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $projectName = $_.Name
    $projectMemoryDir = "$ClaudeDir\projects\$projectName\memory"
    New-Item -ItemType Directory -Force -Path $projectMemoryDir | Out-Null
    Robocopy $_.FullName $projectMemoryDir /E /XO /NJH /NJS /NP | Out-Null
}

# 6. Update plugins/connect/scripts
Write-Host "[6/6] Updating plugins/connect/scripts..." -ForegroundColor Yellow
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

Pop-Location
Write-Host "`nPull complete. Restart Claude Code if it was running." -ForegroundColor Green
Write-Host "=== Done ===" -ForegroundColor Cyan
