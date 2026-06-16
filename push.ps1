# push.ps1 — Push current Claude Code config to sync repo
# Usage: cd ~/.claude-config-sync; .\push.ps1
$ErrorActionPreference = "Stop"
$RepoDir = "$env:USERPROFILE\.claude-config-sync"
$ClaudeDir = "$env:USERPROFILE\.claude"

Write-Host "=== Claude Config Sync — PUSH ===" -ForegroundColor Cyan

# 1. Pull latest to avoid conflicts
Push-Location $RepoDir
Write-Host "[1/8] Pulling latest..." -ForegroundColor Yellow
try { git pull origin main 2>&1 | Out-Null } catch { }
if ($LASTEXITCODE -ne 0) { Write-Host "  (no remote or first push, continuing)" -ForegroundColor Gray }
# Reset exit code so it doesn't trip ErrorActionPreference
$global:LASTEXITCODE = 0

# 2. Copy config files (skip real settings.json)
Write-Host "[2/8] Copying CLAUDE.md + config.json..." -ForegroundColor Yellow
Copy-Item "$ClaudeDir\CLAUDE.md" "$RepoDir\" -Force
if (Test-Path "$ClaudeDir\config.json") { Copy-Item "$ClaudeDir\config.json" "$RepoDir\" -Force }

# 3. Strip API keys
Write-Host "[3/8] Stripping API keys from settings..." -ForegroundColor Yellow
$settings = Get-Content "$ClaudeDir\settings.json" -Raw | ConvertFrom-Json
$settings.env.ANTHROPIC_AUTH_TOKEN = "YOUR_ANTHROPIC_KEY_HERE"
$settings.env.GEMINI_KEY = "YOUR_GEMINI_KEY_HERE"
$settings.env.KIMI_KEY = "YOUR_KIMI_KEY_HERE"
$settings | ConvertTo-Json -Depth 10 | Set-Content "$RepoDir\settings.template.json" -Encoding UTF8

# 4. Sync skills (excluding .git dirs)
Write-Host "[4/8] Syncing skills..." -ForegroundColor Yellow
Robocopy "$ClaudeDir\skills" "$RepoDir\skills" /E /XO /XD ".git" /XD "__pycache__" /XD "node_modules" /NJH /NJS /NP | Out-Null

# 5. Handle symlinked skills
Get-ChildItem "$ClaudeDir\skills" -ErrorAction SilentlyContinue | Where-Object { $_.LinkType -eq "SymbolicLink" } | ForEach-Object {
    $name = $_.Name
    $target = $_.Target -replace [regex]::Escape($env:USERPROFILE), "~"
    # Remove any copied content (robocopy might follow links)
    if (Test-Path "$RepoDir\skills\$name" -PathType Container) {
        Remove-Item "$RepoDir\skills\$name" -Recurse -Force -ErrorAction SilentlyContinue
    }
    @{ type = "symlink"; target = $target } | ConvertTo-Json | Set-Content "$RepoDir\skills\$name.symlink" -Encoding UTF8
    Write-Host "  Symlink: $name -> $target" -ForegroundColor Gray
}

# 6. Sync memory files
Write-Host "[6/8] Syncing memory..." -ForegroundColor Yellow
Get-ChildItem "$ClaudeDir\projects" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $projectName = $_.Name
    $memorySrc = Join-Path $_.FullName "memory"
    if (Test-Path $memorySrc) {
        $memoryDest = "$RepoDir\memory\$projectName"
        New-Item -ItemType Directory -Force -Path $memoryDest | Out-Null
        Robocopy $memorySrc $memoryDest /E /XO /NJH /NJS /NP | Out-Null
        Write-Host "  memory/$projectName" -ForegroundColor Gray
    }
}

# 7. Copy plugins + connect + scripts
Write-Host "[7/8] Copying plugins/connect/scripts..." -ForegroundColor Yellow
if (Test-Path "$ClaudeDir\plugins\installed_plugins.json") {
    Copy-Item "$ClaudeDir\plugins\installed_plugins.json" "$RepoDir\plugins\" -Force
}
if (Test-Path "$ClaudeDir\connect") {
    Robocopy "$ClaudeDir\connect" "$RepoDir\connect" /E /XO /NJH /NJS /NP | Out-Null
}
if (Test-Path "$ClaudeDir\connect-apps") {
    Robocopy "$ClaudeDir\connect-apps" "$RepoDir\connect-apps" /E /XO /NJH /NJS /NP | Out-Null
}
if (Test-Path "$ClaudeDir\scripts") {
    Robocopy "$ClaudeDir\scripts" "$RepoDir\scripts" /E /XO /NJH /NJS /NP | Out-Null
}

# 8. Commit and push
Write-Host "[8/8] Committing and pushing..." -ForegroundColor Yellow
git add -A
$changes = git status --porcelain
if ($changes) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "sync: $ts"
    git push origin main
    Write-Host "`nPushed successfully — $ts" -ForegroundColor Green
} else {
    Write-Host "`nNo changes to push" -ForegroundColor Yellow
}

Pop-Location
Write-Host "=== Done ===" -ForegroundColor Cyan
