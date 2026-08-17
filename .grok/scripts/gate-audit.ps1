#!/usr/bin/env pwsh
# Aggregate hook deny counts from gate-log.tsv. Not an auto-unblock engine.
# Usage: pwsh -File .grok/scripts/gate-audit.ps1 [-Target <root>]
[CmdletBinding()]
param([string]$Target = '.')
$ErrorActionPreference = 'Continue'

if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Write-Error "gate-audit: bad root: $Target"
    exit 2
}
Set-Location -LiteralPath $Target

$log = if (Test-Path -LiteralPath '.grok' -PathType Container) {
    '.grok\hooks\gate-log.tsv'
} else {
    'hooks\gate-log.tsv'
}

if (-not (Test-Path -LiteralPath $log -PathType Leaf)) {
    Write-Output 'gate-audit: no log yet'
    exit 0
}

$counts = @{}
$total = 0
Get-Content -LiteralPath $log -ErrorAction SilentlyContinue | ForEach-Object {
    if (-not $_) { return }
    $parts = $_.Split("`t")
    if ($parts.Count -lt 3) { return }
    if ($parts[2] -ne 'deny') { return }
    $h = $parts[1]
    if (-not $h) { $h = 'unknown' }
    if ($counts.ContainsKey($h)) { $counts[$h]++ } else { $counts[$h] = 1 }
    $total++
}

Write-Output "hook`tdenies"
foreach ($k in ($counts.Keys | Sort-Object)) {
    Write-Output ("{0}`t{1}" -f $k, $counts[$k])
}
Write-Output "total`t$total"
exit 0
