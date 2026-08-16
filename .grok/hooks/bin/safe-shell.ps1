# PreToolUse (Bash): deny catastrophic/destructive command patterns. ASCII only.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    Read-HookStdin
    $cmd = Get-ToolCommand
    if (-not $cmd) { Write-GrokAllow; exit 0 }

    $rules = @(
        @{ p = '(^|[;&|\s])rm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)\s+("?/"?|/\*|"?~"?|\$HOME)(\s|$)'; r = 'rm -rf on / or home root is blocked.' },
        @{ p = '(^|[;&|\s])mkfs(\.[a-z0-9]+)?(\s|$)'; r = 'mkfs (filesystem format) is blocked.' },
        @{ p = '(^|[;&|\s])dd\s[^;&|]*of=/dev/(sd|hd|nvme|vd|mmcblk)'; r = 'dd writing to a block device is blocked.' },
        @{ p = ':\(\)\s*\{\s*:\|:'; r = 'Fork bomb pattern is blocked.' },
        @{ p = '(^|[;&|\s])chmod\s+(-[a-zA-Z]*R[a-zA-Z]*\s+)?777\s+/(\s|$)'; r = 'chmod 777 on / is blocked.' },
        @{ p = '(^|[;&|\s])git\s+push\s[^;&|]*(--force|-f)(\s[^;&|]*)?\s(origin\s+)?(main|master)(\s|$)'; r = 'Force-push to main/master is blocked. Use a feature branch or get explicit approval.' },
        @{ p = '(^|[;&|\s])(curl|wget)\s[^;&|]*\|\s*(ba|z|da)?sh(\s|$)'; r = 'Piping a remote script into a shell is blocked. Download, inspect, then run.' }
    )
    foreach ($rule in $rules) {
        if ($cmd -match $rule.p) {
            Write-GrokDeny $rule.r
            exit 2
        }
    }
    Write-GrokAllow
    exit 0
} catch {
    Write-GrokAllow
    exit 0
}
