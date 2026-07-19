#!/usr/bin/env pwsh
# PreToolUse: deny pkill -f (never bypassed by Fast Mode)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')
Read-HookStdin
$cmd = Get-ToolCommand
if (-not $cmd) { Write-GrokAllow; exit 0 }
if ($cmd -match '(^|[;&|\s])pkill\s+[^;&|]*\-f(?:\s|$)') {
    Write-GrokDeny 'pkill -f is blocked. Inspect exact PIDs first, then kill by PID.'
    exit 2
}
Write-GrokAllow
exit 0
