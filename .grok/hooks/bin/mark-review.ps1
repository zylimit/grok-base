#!/usr/bin/env pwsh
# PostToolUse: register edited business files for review
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')
$root = Get-ProjectRoot
if (Test-FastModeActive) { exit 0 }
Read-HookStdin
$ti = Get-HookToolInput
$paths = @()
if ($ti) {
    foreach ($k in @('file_path', 'path', 'target_file')) {
        if ($ti.PSObject.Properties.Name -contains $k -and $ti.$k) { $paths += [string]$ti.$k }
    }
}
if ($paths.Count -eq 0) { exit 0 }

$state = Join-Path $root '.grok\.needs-review'
$existing = @()
if (Test-Path -LiteralPath $state) {
    $existing = @(Get-Content -LiteralPath $state | Where-Object { $_ -and $_ -ne 'clean' })
}
$rootFull = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
foreach ($path in ($paths | Select-Object -Unique)) {
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $root $path }
    try { $full = [IO.Path]::GetFullPath($path) } catch { continue }
    if (-not $full.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) { continue }
    $rel = $full.Substring($rootFull.Length).TrimStart('\', '/') -replace '\\', '/'
    if ($rel -match '^(\.grok|docs|tools)/') { continue }
    if ($rel -match '\.(md|txt|json|ya?ml|toml|lock|log|gitignore)$') { continue }
    if ($existing -notcontains $rel) { $existing += $rel }
}
if ($existing.Count -gt 0) {
    Set-Content -LiteralPath $state -Value $existing -Encoding utf8
}
exit 0
