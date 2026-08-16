# SubagentStop (project agents): require the unified result envelope. ASCII only.
# Blocks the stop ONCE if reply lacks "Status:"; never loops (stopHookActive check).
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    Read-HookStdin
    $active = $false
    $msg = ''
    try {
        if ($null -ne $script:HookData) {
            if ($script:HookData.PSObject.Properties.Name -contains 'stopHookActive') {
                $active = [bool]$script:HookData.stopHookActive
            }
            if ($script:HookData.PSObject.Properties.Name -contains 'lastAssistantMessage') {
                $msg = [string]$script:HookData.lastAssistantMessage
            }
        }
    } catch { }

    if ($active) { exit 0 }
    if (-not $msg) { exit 0 }
    if ($msg -match 'Status[:\uFF1A]') { exit 0 }

    $reason = 'Missing result envelope. End with: Status(DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED; tester: PASS|FAIL) / Changed / Verified / Not verified / Needs review by / Evidence.'
    @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress | Write-Output
    exit 0
} catch {
    exit 0
}
