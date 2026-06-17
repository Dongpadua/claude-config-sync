# 每天检查并自启关键服务
$workDir = "d:\ai work"

# 1. model-gateway (端口8787)
$gw = netstat -ano 2>$null | Select-String "127.0.0.1:8787"
if (-not $gw) {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') Gateway not running, starting..."
    # 读 keys（从同目录 gateway-keys.json）
    $keysFile = "$env:USERPROFILE\.claude\scripts\gateway-keys.json"
    if (Test-Path $keysFile) {
        $keys = Get-Content $keysFile -Raw | ConvertFrom-Json
        $env:GW_DEEPSEEK_KEY = $keys.DEEPSEEK_KEY
        $env:GW_GEMINI_KEY = $keys.GEMINI_KEY
    }
    Start-Process node -ArgumentList "$env:USERPROFILE\.claude\scripts\model-gateway.js" -WindowStyle Hidden
} else {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') Gateway OK"
}

# 2. cc-connect
$cc = Get-Process cc-connect -ErrorAction SilentlyContinue
if (-not $cc) {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') cc-connect NOT running, restarting..."
    & "$workDir\restart_cc.ps1"
} else {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') cc-connect OK (PID: $($cc.Id))"
}
