# gemini.ps1 — 一键启动 Chrome 调试模式并打开 Gemini
$chromePath = "C:\Users\Administrator\AppData\Local\Google\Chrome\Application\chrome.exe"
$userData = "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data"

Write-Host "Closing Chrome..." -NoNewline
Get-Process -Name "chrome","chromium" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Write-Host " done"

Remove-Item "$userData\SingletonLock" -Force -ErrorAction SilentlyContinue
Remove-Item "$userData\SingletonSocket" -Force -ErrorAction SilentlyContinue

Write-Host "Launching Chrome with debug port..." -NoNewline
Start-Process -FilePath $chromePath -ArgumentList @(
    "--remote-debugging-port=9222",
    "--remote-allow-origins=*",
    "--user-data-dir=$userData",
    "https://gemini.google.com/app"
) -WindowStyle Maximized

Start-Sleep -Seconds 8

# Verify debug port
for ($i = 0; $i -lt 5; $i++) {
    try {
        $r = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json/version" -TimeoutSec 3
        Write-Host " done"
        break
    } catch {
        if ($i -eq 4) { Write-Host "`nFAIL: Chrome debug port not responding"; exit 1 }
        Start-Sleep -Seconds 2
    }
}

# Close any http://data/ tab (caused by Chrome extensions)
try {
    $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 3
    foreach ($p in $pages) {
        if ($p.url -eq "http://data/" -or $p.url -eq "http://data") {
            Invoke-RestMethod -Uri "http://127.0.0.1:9222/json/close/$($p.id)" -Method Get | Out-Null
            Write-Host "Closed stray tab: $($p.url)"
        }
    }
} catch {}

# Activate Gemini tab
try {
    $pages = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 3
    foreach ($p in $pages) {
        if ($p.url -match "gemini") {
            Invoke-RestMethod -Uri "http://127.0.0.1:9222/json/activate/$($p.id)" -Method Get | Out-Null
        }
    }
} catch {}

Write-Host "Chrome ready: http://127.0.0.1:9222"
Write-Host "Run: agent-browser connect 9222"
