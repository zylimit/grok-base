#!/usr/bin/env pwsh
# Stop is passive; write reminder only
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')
$root = Get-ProjectRoot
$reminder = Join-Path $root '.grok\.stop-reminder'
if (Test-FastModeActive) {
    Remove-Item -LiteralPath $reminder -Force -ErrorAction SilentlyContinue
    exit 0
}
$state = Join-Path $root '.grok\.needs-review'
if (-not (Test-Path -LiteralPath $state)) {
    Remove-Item -LiteralPath $reminder -Force -ErrorAction SilentlyContinue
    exit 0
}
$files = @(Get-Content -LiteralPath $state | Where-Object { $_.Trim() -and $_ -ne 'clean' })
if ($files.Count -eq 0) {
    Remove-Item -LiteralPath $state -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $reminder -Force -ErrorAction SilentlyContinue
    exit 0
}
$msg = "STOP REMINDER: $($files.Count) file(s) pending review. Dispatch code-reviewer, then write clean to .grok/.needs-review."
Set-Content -LiteralPath $reminder -Value $msg -Encoding ascii
Write-Output $msg
exit 0
