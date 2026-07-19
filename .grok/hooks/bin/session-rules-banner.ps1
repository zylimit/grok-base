# SessionStart: print core rules banner (silent on compact/resume if provided)
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    if (Test-FastModeActive) {
        Write-Output '!! FAST-MODE ON: quality gates muted (.grok/.fast-mode). Run: pwsh .grok/scripts/fast-mode.ps1 off !!'
        exit 0
    }
    $raw = ''
    try { $raw = [Console]::In.ReadToEnd() } catch { }
    try {
        $src = ''
        if ($raw) { $src = (($raw | ConvertFrom-Json).source) }
        if ($src -eq 'compact' -or $src -eq 'resume') { exit 0 }
    } catch { }

    $banner = @'
========================================================
 Grok Base Core Rules
========================================================
 1. Main agent does not write business code directly
    - dispatch implementer / code-reviewer / tester / deployer
 2. Fresh subagent each task; no nested spawn (depth=1)
 3. Accept on fresh evidence (run commands now; no "should be fine")
 4. Preserve framework assets: delete/rewrite hooks/skills needs approval
 5. Three-file sync: progress.md / Product-Spec / CHANGELOG when they exist
 6. User explicit scope wins; safety guards never skip
========================================================
'@
    Write-Output $banner
} catch { }
exit 0
