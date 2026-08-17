# PostToolUse: register edited business files for review
# Passive: always exit 0
# .needs-review lines: relpath<TAB>fingerprint  (old: relpath only = no fingerprint)
# A lone "clean" line still means reviewed-clear.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    $root = Get-ProjectRoot
    if (Test-FastModeActive) { exit 0 }
    Read-HookStdin
    $ti = Get-HookToolInput
    $paths = @()
    if ($ti) {
        foreach ($k in @('file_path', 'path', 'target_file')) {
            try {
                if ($ti.PSObject.Properties.Name -contains $k -and $ti.$k) {
                    $paths += [string]$ti.$k
                }
            } catch { }
        }
    }
    if ($paths.Count -eq 0) { exit 0 }

    $state = Join-Path $root '.grok\.needs-review'
    $byPath = [ordered]@{}
    if (Test-Path -LiteralPath $state) {
        foreach ($line in @(Get-Content -LiteralPath $state -ErrorAction SilentlyContinue)) {
            if (-not $line) { continue }
            $trim = $line.Trim()
            if (-not $trim -or $trim -eq 'clean') { continue }
            $tab = $line.IndexOf([char]9)
            if ($tab -lt 0) {
                $byPath[$trim] = ''
            } else {
                $p = $line.Substring(0, $tab)
                $h = $line.Substring($tab + 1)
                if ($p) { $byPath[$p] = $h }
            }
        }
    }
    $rootFull = [IO.Path]::GetFullPath($root).TrimEnd('\', '/')
    foreach ($path in ($paths | Select-Object -Unique)) {
        try {
            if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $root $path }
            $full = [IO.Path]::GetFullPath($path)
            if (-not $full.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) { continue }
            $rel = $full.Substring($rootFull.Length).TrimStart('\', '/') -replace '\\', '/'
            if ($rel -match '^(\.grok|docs|tools)/') { continue }
            if ($rel -match '\.(md|txt|json|ya?ml|toml|lock|log|gitignore)$') { continue }
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            $fp = Get-ReviewFingerprint $root $full
            if (-not $fp) {
                Write-Error "mark-review: cannot fingerprint $rel"
                continue
            }
            $byPath[$rel] = $fp
        } catch { }
    }
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($p in $byPath.Keys) {
        if ($byPath[$p]) {
            [void]$out.Add("$p`t$($byPath[$p])")
        } else {
            [void]$out.Add($p)
        }
    }
    if ($out.Count -gt 0) {
        Set-Content -LiteralPath $state -Value $out.ToArray() -Encoding ascii -ErrorAction SilentlyContinue
    }
} catch { }
exit 0
