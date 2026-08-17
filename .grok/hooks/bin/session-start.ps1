# SessionStart: Fast Mode, pending review, feedback, dirty tree
# Passive hook: always exit 0 so Grok never red-bars session start.
# Corrupt .needs-review / .fast-mode are quarantined, never silently rebuilt.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }

function Test-StateUnreadableOrBinary([string]$path) {
    try {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
        $fs = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        try {
            $buf = New-Object byte[] 8192
            while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) {
                for ($i = 0; $i -lt $n; $i++) {
                    if ($buf[$i] -eq [byte]0) { return $true }
                }
            }
        } finally { $fs.Dispose() }
        return $false
    } catch {
        return $true
    }
}

function Test-FastModeHasValidExpiry([string]$path) {
    try {
        $hit = Get-Content -LiteralPath $path -ErrorAction Stop |
            Where-Object { $_ -match '^expires_epoch=\d+$' } |
            Select-Object -First 1
        return [bool]$hit
    } catch {
        return $false
    }
}

function Move-CorruptState([string]$root, [string]$src) {
    $name = [IO.Path]::GetFileName($src)
    $epoch = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    $dest = Join-Path (Join-Path $root '.grok') "$name.corrupt-$epoch"
    try {
        Move-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
        Write-Output "QUARANTINED: $src -> $dest (corrupt; not rebuilt)"
    } catch {
        Write-Output "QUARANTINED: failed to move $src"
    }
}

try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    $root = Get-ProjectRoot
    $flag = Get-FastModeFlagPath
    $state = Join-Path $root '.grok\.needs-review'

    if (Test-Path -LiteralPath $state -PathType Leaf) {
        if (Test-StateUnreadableOrBinary $state) {
            Move-CorruptState $root $state
        }
    }
    if (Test-Path -LiteralPath $flag -PathType Leaf) {
        if ((Test-StateUnreadableOrBinary $flag) -or -not (Test-FastModeHasValidExpiry $flag)) {
            Move-CorruptState $root $flag
        }
    }

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
