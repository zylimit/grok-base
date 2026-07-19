#!/usr/bin/env pwsh
# SessionStart: Fast Mode, pending review, feedback, dirty tree
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')
$root = Get-ProjectRoot
$flag = Get-FastModeFlagPath

if (Test-FastModeActive) {
    $left = Get-FastModeRemainingMinutes
    Write-Output "FAST-MODE ON: about $left minutes remaining. Skip auto review/test gates; safety guards stay on."
} elseif (Test-Path -LiteralPath $flag) {
    Write-Output 'FAST-MODE EXPIRED: normal quality workflow is active again.'
} else {
    Write-Output 'FAST-MODE OFF: normal quality workflow is active.'
}

$state = Join-Path $root '.grok\.needs-review'
if (Test-Path -LiteralPath $state) {
    $files = @(Get-Content -LiteralPath $state | Where-Object { $_.Trim() -and $_ -ne 'clean' })
    if ($files.Count -gt 0) {
        Write-Output "REVIEW PENDING: $($files.Count) file(s). Dispatch code-reviewer; after pass write clean to .grok/.needs-review."
    }
}

if (Test-Path -LiteralPath (Join-Path $root '.grok\.feedback-signal')) {
    Write-Output 'FEEDBACK SIGNAL: after handling the user request, dispatch feedback-observer.'
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    git -C $root rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $n = @(git -C $root status --porcelain 2>$null | Where-Object { $_ }).Count
        if ($n -gt 0) {
            Write-Output "Dirty worktree: $n change(s). Prefer /recap: progress.md + Product-Spec.md + Product-Spec-CHANGELOG.md."
        }
    }
}

$index = Join-Path $root '.grok\feedback\FEEDBACK-INDEX.md'
if (Test-Path -LiteralPath $index) {
    $pending = @(Get-Content -LiteralPath $index | Where-Object { $_ -match '^\- \[' }).Count
    if ($pending -gt 0) {
        Write-Output "Feedback index has pending entries. Consider dispatching evolution-runner."
    }
}
exit 0
