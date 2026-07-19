# PreToolUse: deny pkill -f (never bypassed by Fast Mode)
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    Read-HookStdin
    $cmd = Get-ToolCommand
    if ($cmd -and ($cmd -match '(^|[;&|\s])pkill\s+[^;&|]*\-f(?:\s|$)')) {
        Write-GrokDeny 'pkill -f is blocked. Inspect exact PIDs first, then kill by PID.'
        exit 2
    }
    Write-GrokAllow
    exit 0
} catch {
    Write-GrokAllow
    exit 0
}
