#!/usr/bin/env pwsh
# Purge grok-base runtime state only. Never touches skills/rules/hooks/bin/scripts sources.
# Usage: pwsh -File .grok/scripts/prune.ps1 [-Apply] [-Target <root>]
# Default: dry-run (print path + age). -Apply actually deletes.
[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$Target = '.'
)
$ErrorActionPreference = 'Continue'

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "prune: bad root: $Target"
    exit 2
}
$root = (Resolve-Path -LiteralPath $Target).Path
$grok = if (Test-Path -LiteralPath (Join-Path $root '.grok') -PathType Container) {
    Join-Path $root '.grok'
} else {
    $root
}

$maxAge = 14 * 86400
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

function Test-Allowed([string]$path) {
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if (-not $item) { return $false }
    $base = $item.Name
    $dir = $item.DirectoryName
    $grokHooks = Join-Path $grok 'hooks'
    if ($base -like '.needs-review.corrupt-*' -or $base -like '.fast-mode.corrupt-*') {
        return ($dir -eq $grok)
    }
    if ($base -eq '.stop-reminder') { return ($dir -eq $grok) }
    if ($base -eq 'gate-log.tsv') { return ($dir -eq $grokHooks) }
    return $false
}

function Get-AgeSec([string]$path) {
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if (-not $item) { return $null }
    return [int64]($now - [DateTimeOffset]::new($item.LastWriteTimeUtc).ToUnixTimeSeconds())
}

function Invoke-Consider([string]$path, [bool]$needAge) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $true }
    if (-not (Test-Allowed $path)) { return $true }
    $age = Get-AgeSec $path
    if ($null -eq $age) { return $true }
    if ($needAge -and $age -le $maxAge) { return $true }
    $label = '{0}d' -f [int][math]::Floor($age / 86400)
    if (-not $Apply) {
        Write-Output "dry-run: $path  age=$label"
        return $true
    }
    try {
        Remove-Item -LiteralPath $path -Force -ErrorAction Stop
        Write-Output "deleted: $path  age=$label"
        return $true
    } catch {
        Write-Error "prune: FAIL delete $path"
        return $false
    }
}

$fail = $false
Get-ChildItem -LiteralPath $grok -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '.needs-review.corrupt-*' -or $_.Name -like '.fast-mode.corrupt-*' } |
    ForEach-Object { if (-not (Invoke-Consider $_.FullName $true)) { $script:fail = $true } }

if (-not (Invoke-Consider (Join-Path $grok '.stop-reminder') $false)) { $fail = $true }
if (-not (Invoke-Consider (Join-Path $grok 'hooks\gate-log.tsv') $true)) { $fail = $true }

if (-not $Apply) {
    Write-Output 'prune: dry-run (pass -Apply to delete)'
} else {
    Write-Output 'prune: apply done'
}
if ($fail) { exit 1 }
exit 0
