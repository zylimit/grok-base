# SessionStart: Fast Mode, pending review, feedback, dirty tree
# Passive hook: always exit 0 so Grok never red-bars session start.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    $root = Get-ProjectRoot
    $flag = Get-FastModeFlagPath

    if (Test-FastModeActive) {
        $left = Get-FastModeRemainingMinutes
        if (-not $left) { $left = '?' }
        Write-Output "FAST-MODE ON: about $left minutes remaining. Skip auto review/test gates; safety guards stay on."
    } elseif (Test-Path -LiteralPath $flag -ErrorAction SilentlyContinue) {
        Write-Output 'FAST-MODE EXPIRED: normal quality workflow is active again.'
    } else {
        Write-Output 'FAST-MODE OFF: normal quality workflow is active.'
    }

    try {
        $state = Join-Path $root '.grok\.needs-review'
        if (Test-Path -LiteralPath $state) {
            $files = @(Get-Content -LiteralPath $state -ErrorAction SilentlyContinue |
                Where-Object { $_.Trim() -and $_ -ne 'clean' })
            if ($files.Count -gt 0) {
                Write-Output "REVIEW PENDING: $($files.Count) file(s). Dispatch code-reviewer; after pass write clean to .grok/.needs-review."
            }
        }
    } catch { }

    try {
        if (Test-Path -LiteralPath (Join-Path $root '.grok\.feedback-signal')) {
            Write-Output 'FEEDBACK SIGNAL: after handling the user request, dispatch feedback-observer.'
        }
    } catch { }

    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            & git -C $root rev-parse --is-inside-work-tree 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $n = @(& git -C $root status --porcelain 2>$null | Where-Object { $_ }).Count
                if ($n -gt 0) {
                    Write-Output "Dirty worktree: $n change(s). Prefer /recap: progress.md + Product-Spec.md + Product-Spec-CHANGELOG.md."
                }
            }
        }
    } catch { }

    try {
        $index = Join-Path $root '.grok\feedback\FEEDBACK-INDEX.md'
        if (Test-Path -LiteralPath $index) {
            $pending = @(Get-Content -LiteralPath $index -ErrorAction SilentlyContinue |
                Where-Object { $_ -match '^\- \[' }).Count
            if ($pending -gt 0) {
                Write-Output 'Feedback index has pending entries. Consider dispatching evolution-runner.'
            }
        }
    } catch { }
} catch { }
exit 0
