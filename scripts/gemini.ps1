# gemini.ps1 — 一键启动 Chrome 调试模式并打开 Gemini
$chromePath = "C:\Users\Administrator\AppData\Local\Google\Chrome\Application\chrome.exe"
$userData = "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data"

Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Remove-Item "$userData\SingletonLock" -Force -ErrorAction SilentlyContinue
Remove-Item "$userData\SingletonSocket" -Force -ErrorAction SilentlyContinue

Start-Process -FilePath $chromePath -ArgumentList @(
    "--remote-debugging-port=9222",
    "--user-data-dir=$userData",
    "https://gemini.google.com/app"
) -WindowStyle Maximized

Start-Sleep -Seconds 6
try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json/version" -TimeoutSec 5
    Write-Host "Chrome ready with debug port 9222"
} catch {
    Write-Host "Wait a moment, Chrome starting..."
}
