# PreCompact: print short keep-pointers. Passive; never block. Always exit 0.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    try { Read-HookStdin } catch { }
    $root = Get-ProjectRoot

    $hasProgress = if (Test-Path -LiteralPath (Join-Path $root 'progress.md')) { 'yes' } else { 'no' }
    $hasSpec = if (Test-Path -LiteralPath (Join-Path $root 'Product-Spec.md')) { 'yes' } else { 'no' }

    $adrN = 0
    $adrDir = Join-Path $root 'docs\adr'
    if (Test-Path -LiteralPath $adrDir -PathType Container) {
        $adrN = @(Get-ChildItem -LiteralPath $adrDir -Filter '*.md' -File -ErrorAction SilentlyContinue).Count
    }

    $reviewN = 0
    $state = Join-Path $root '.grok\.needs-review'
    if (Test-Path -LiteralPath $state) {
        $reviewN = @(Get-Content -LiteralPath $state -ErrorAction SilentlyContinue |
            Where-Object { $_.Trim() -and $_ -ne 'clean' }).Count
    }

    $lines = @(
        'PreCompact keep-pointers (not a block):'
        "- progress.md: $hasProgress"
        "- Product-Spec.md: $hasSpec"
        "- docs/adr: $adrN"
        "- .needs-review: $reviewN line(s)"
        'Prefer /recap (progress.md + Product-Spec.md + Product-Spec-CHANGELOG.md) after compact.'
    )
    $text = ($lines -join "`n") + "`n"
    if ($text.Length -gt 2048) { $text = $text.Substring(0, 2048) }
    Write-Output $text.TrimEnd()
} catch { }
exit 0
