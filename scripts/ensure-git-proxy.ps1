# ensure-git-proxy.ps1 — Auto-detect system proxy and configure git
# Solves the classic "browser works, git doesn't" on Windows with Clash/V2Ray
#
# Root cause triad (all 3 must be fixed, not just one):
#   1. git doesn't read Windows system proxy → must set http.proxy explicitly
#   2. schannel TLS fails through proxy    → must switch to openssl
#   3. Credential Manager interactive auth → must use GH_TOKEN or PAT in URL
#
# Usage: .\ensure-git-proxy.ps1
#        .\ensure-git-proxy.ps1 -Force  # re-configure even if already set

param([switch]$Force)

$ErrorActionPreference = "Stop"
Write-Host "=== Git Proxy Auto-Fixer ===" -ForegroundColor Cyan

# Step 1: Detect Windows system proxy
$sysProxy = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue).ProxyServer

if ($sysProxy) {
    Write-Host "[1/4] System proxy detected: $sysProxy" -ForegroundColor Green
} else {
    Write-Host "[1/4] No system proxy detected. If you use a VPN/proxy, set it manually:" -ForegroundColor Yellow
    Write-Host "       git config --global http.proxy http://127.0.0.1:PORT" -ForegroundColor Gray
    $sysProxy = $null
}

# Step 2: Configure git proxy
if ($sysProxy) {
    $currentProxy = git config --global http.proxy 2>$null
    if ($currentProxy -ne "http://$sysProxy" -or $Force) {
        git config --global http.proxy "http://$sysProxy"
        git config --global https.proxy "http://$sysProxy"
        Write-Host "[2/4] Git proxy set: http://$sysProxy" -ForegroundColor Green
    } else {
        Write-Host "[2/4] Git proxy already configured." -ForegroundColor Gray
    }
}

# Step 3: Switch to OpenSSL (schannel fails through most proxies)
$currentSSL = git config --global http.sslBackend 2>$null
if ($currentSSL -ne "openssl") {
    git config --global http.sslBackend openssl
    Write-Host "[3/4] SSL backend switched to OpenSSL (schannel incompatible with proxy)" -ForegroundColor Green
} else {
    Write-Host "[3/4] SSL backend already OpenSSL." -ForegroundColor Gray
}

# Step 4: Test connectivity
Write-Host "[4/4] Testing GitHub connectivity..." -ForegroundColor Yellow
$testResult = git ls-remote --heads https://github.com/Dongpadua/claude-config-sync.git 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  GitHub reachable through proxy!" -ForegroundColor Green
} else {
    Write-Host "  WARNING: GitHub still unreachable. Possible issues:" -ForegroundColor Red
    Write-Host "    - Proxy software (Clash/V2Ray) not running" -ForegroundColor DarkYellow
    Write-Host "    - Proxy port changed (check: reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings /v ProxyServer)" -ForegroundColor DarkYellow
    Write-Host "    - Need to set GH_TOKEN or use token-in-URL for auth" -ForegroundColor DarkYellow
    Write-Host "    - Try: git config --global --unset http.proxy  (if direct works)" -ForegroundColor DarkYellow
}

Write-Host "=== Done ===" -ForegroundColor Cyan
