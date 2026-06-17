# install-apps.ps1 — 新电脑安装必备应用（先检查再下载）
# 用法: powershell -ExecutionPolicy Bypass -File install-apps.ps1

$ErrorActionPreference = "Stop"
$DownloadDir = "$env:USERPROFILE\Downloads"

# 应用清单: Name, ExePath, DownloadUrl
$apps = @(
    @{
        Name       = "Clawd on Desk"
        ExePath    = "D:\clawd on desk\Clawd on Desk.exe"
        Installer  = "$DownloadDir\Clawd-on-Desk-Setup-x64.exe"
        Url        = "https://github.com/rullerzhou-afk/clawd-on-desk/releases/latest/download/Clawd-on-Desk-Setup-x64.exe"
        PrefsPath  = "$env:APPDATA\clawd-on-desk\clawd-prefs.json"
    },
    @{
        Name       = "DeepSeek Monitor Windows"
        ExePath    = "D:\DeepSeekMonitorWindows\app.exe"
        Installer  = "$DownloadDir\DeepSeekMonitorWindows-Setup-x64.exe"
        Url        = "https://github.com/Joyi-code/DeepSeekMonitorWindows/releases/latest/download/DeepSeekMonitorWindows_x64-setup.exe"
    }
)

Write-Host "=== Install Essential Apps ===" -ForegroundColor Cyan
Write-Host ""

$installed = 0
$skipped  = 0
$failed   = 0

foreach ($app in $apps) {
    Write-Host "[$($app.Name)]" -ForegroundColor Yellow

    # 1. 检查是否已安装
    if (Test-Path $app.ExePath) {
        Write-Host "  Already installed: $($app.ExePath)" -ForegroundColor Green
        $skipped++
        Write-Host ""
        continue
    }

    # 2. 检查安装包是否已下载
    if (-not (Test-Path $app.Installer)) {
        Write-Host "  Downloading..." -ForegroundColor Gray
        try {
            Invoke-WebRequest -Uri $app.Url -OutFile $app.Installer -UseBasicParsing
            Write-Host "  Downloaded: $($app.Installer)" -ForegroundColor Gray
        } catch {
            Write-Host "  FAILED to download: $_" -ForegroundColor Red
            $failed++
            Write-Host ""
            continue
        }
    } else {
        Write-Host "  Installer found, skipping download." -ForegroundColor Gray
    }

    # 3. 静默安装
    Write-Host "  Installing..." -ForegroundColor Gray
    try {
        Start-Process -FilePath $app.Installer -ArgumentList "/S" -Wait -NoNewWindow
        Start-Sleep -Seconds 3
        if (Test-Path $app.ExePath) {
            Write-Host "  Installed successfully!" -ForegroundColor Green
            $installed++
        } else {
            Write-Host "  Installer ran but exe not found. Check manually." -ForegroundColor DarkYellow
            $failed++
        }
    } catch {
        Write-Host "  Install failed: $_" -ForegroundColor Red
        $failed++
    }
    Write-Host ""
}

Write-Host "=== Done: $installed installed, $skipped skipped, $failed failed ===" -ForegroundColor Cyan

# 配置 Clawd on Desk 自动启动
$prefsPath = "$env:APPDATA\clawd-on-desk\clawd-prefs.json"
if (Test-Path $prefsPath) {
    Write-Host "Configuring Clawd on Desk auto-start..." -ForegroundColor Yellow
    $prefs = Get-Content $prefsPath -Raw | ConvertFrom-Json
    $prefs.openAtLogin = $true
    $prefs.autoStartWithClaude = $true
    $prefs | ConvertTo-Json -Depth 10 | Set-Content $prefsPath -Encoding UTF8
    Write-Host "  Auto-start enabled." -ForegroundColor Green

    # 启动 Clawd
    $clawdExe = "D:\clawd on desk\Clawd on Desk.exe"
    if (Test-Path $clawdExe) {
        Start-Process -FilePath $clawdExe
        Write-Host "  Launched Clawd on Desk." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "If Clawd was just installed, restart your terminal for Claude Code hooks to take effect." -ForegroundColor DarkYellow
