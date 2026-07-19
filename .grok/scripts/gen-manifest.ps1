#!/usr/bin/env pwsh
# gen-manifest.ps1 - regenerate .grok/FRAMEWORK-MANIFEST.txt from source tree
# Usage: pwsh -File .grok/scripts/gen-manifest.ps1
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$src = Join-Path $root '.grok'
$out = Join-Path $src 'FRAMEWORK-MANIFEST.txt'
if (-not (Test-Path -LiteralPath $src)) { throw "missing .grok: $src" }

function Get-NormalizedSha([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $filtered = [byte[]]($bytes | Where-Object { $_ -ne 13 })
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($filtered)) -replace '-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

function Test-Skip([string]$rel) {
    $leaf = Split-Path $rel -Leaf
    $skip = @(
        'FRAMEWORK-MANIFEST.txt', 'project-hooks.json',
        'settings.local.json', 'config.local.toml',
        '.needs-review', '.needs-review.lock', '.fast-mode', '.stop-reminder', '.feedback-signal',
        'signals.jsonl'
    )
    if ($skip -contains $leaf) { return $true }
    if ($rel -match '\.(bak|framework-new)$') { return $true }
    if ($rel -match '^feedback/[^/]+\.md$') { return $true }
    if ($rel -match '^evidence/') { return $true }
    return $false
}

$srcLen = (Resolve-Path $src).Path.Length
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# grok-base FRAMEWORK-MANIFEST')
$lines.Add('# format: <path-relative-to-.grok><TAB><sha256-LF-normalized>')
$lines.Add('# regenerate: pwsh -File .grok/scripts/gen-manifest.ps1')

Get-ChildItem -Path $src -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($srcLen).TrimStart('\', '/') -replace '\\', '/'
    if (Test-Skip $rel) { return }
    $lines.Add("$rel`t$(Get-NormalizedSha $_.FullName)")
}

# Also record root AGENTS.md under special key for upgrade safety
$agents = Join-Path $root 'AGENTS.md'
if (Test-Path -LiteralPath $agents) {
    $lines.Add("../AGENTS.md`t$(Get-NormalizedSha $agents)")
}

$sorted = $lines | Where-Object { $_ -notmatch '^#' } | Sort-Object
$header = $lines | Where-Object { $_ -match '^#' }
($header + $sorted) | Set-Content -LiteralPath $out -Encoding utf8
Write-Host "wrote $out ($($sorted.Count) files)"
