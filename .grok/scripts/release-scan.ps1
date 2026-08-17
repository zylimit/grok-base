#!/usr/bin/env pwsh
# Scan a build directory or release archive for leaked paths / secrets.
# Usage: pwsh -File .grok/scripts/release-scan.ps1 <dir|zip|tar|tar.gz|tgz>
# Missing tar/unzip for an archive -> FAIL (do not fake a scan).
[CmdletBinding()]
param([Parameter(Position = 0)][string]$Target = '')
$ErrorActionPreference = 'Continue'

if (-not $Target) {
    Write-Error 'release-scan: FAIL -- missing target (dir or .zip/.tar/.tar.gz/.tgz)'
    exit 1
}
if (-not (Test-Path -LiteralPath $Target)) {
    Write-Error "release-scan: FAIL -- target missing: $Target"
    exit 1
}

$tmp = $null
$scanRoot = $null
function Clear-ScanTemp {
    if ($tmp -and (Test-Path -LiteralPath $tmp)) {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-ArchiveName([string]$p) {
    $n = $p.ToLowerInvariant()
    return ($n -match '\.(zip|tar|tar\.gz|tgz)$')
}

try {
    $item = Get-Item -LiteralPath $Target
    if ($item.PSIsContainer) {
        $scanRoot = $item.FullName
    } elseif (Test-ArchiveName $item.FullName) {
        $src = $item.FullName
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("release-scan-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        $low = $src.ToLowerInvariant()
        if ($low.EndsWith('.zip')) {
            $unzip = Get-Command unzip -ErrorAction SilentlyContinue
            if ($unzip) {
                & unzip -qq -o $src -d $tmp
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "release-scan: FAIL -- unzip failed for $src"
                    exit 1
                }
            } elseif (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
                try {
                    Expand-Archive -LiteralPath $src -DestinationPath $tmp -Force
                } catch {
                    Write-Error "release-scan: FAIL -- Expand-Archive failed for $src"
                    exit 1
                }
            } else {
                Write-Error 'release-scan: FAIL -- unzip not in PATH; cannot scan zip (not scanned)'
                exit 1
            }
        } else {
            $tar = Get-Command tar -ErrorAction SilentlyContinue
            if (-not $tar) {
                Write-Error 'release-scan: FAIL -- tar not in PATH; cannot scan archive (not scanned)'
                exit 1
            }
            $flags = @('-xf', $src, '-C', $tmp, '--no-same-owner')
            if ($low.EndsWith('.tar.gz') -or $low.EndsWith('.tgz')) {
                $flags = @('-xzf', $src, '-C', $tmp, '--no-same-owner')
            }
            & tar @flags
            if ($LASTEXITCODE -ne 0) {
                Write-Error "release-scan: FAIL -- tar extract failed for $src"
                exit 1
            }
        }
        $scanRoot = $tmp
    } else {
        Write-Error "release-scan: FAIL -- not a directory or supported archive: $Target"
        exit 1
    }

    $fail = $false
    function Hit([string]$msg) {
        Write-Output "release-scan: FAIL $msg"
        $script:fail = $true
    }

    $nameHit = { param($n) $n -eq '.env' -or $n -eq 'id_rsa' -or $n -eq 'credentials.json' -or $n -like '*.pem' -or $n -like '*.key' -or $n -like '*.db' }
    Get-ChildItem -LiteralPath $scanRoot -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($scanRoot.Length).TrimStart('\', '/') -replace '\\', '/'
        if (& $nameHit $_.Name) { Hit "name $($_.Name) $rel" }
        if ($rel -match '/Users/|(^|/)Users/|C:\\Users\\|C:/Users/') { Hit "path $rel" }
    }

    $contentRe = '/Users/|C:\\Users\\|C:/Users/|sk-ant-|sk-proj-|BEGIN PRIVATE KEY|password\s*=\s*[''"]'
    Get-ChildItem -LiteralPath $scanRoot -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($scanRoot.Length).TrimStart('\', '/') -replace '\\', '/'
        if ($rel -match '(^|/)\.git/') { return }
        try {
            $hits = Select-String -LiteralPath $_.FullName -Pattern $contentRe -AllMatches -ErrorAction SilentlyContinue
            foreach ($h in $hits) {
                Hit ("content {0}:{1}:{2}" -f $rel, $h.LineNumber, $h.Line.Trim())
            }
        } catch { }
    }

    if ($fail) {
        Write-Error 'release-scan: FAIL'
        exit 1
    }
    Write-Output "release-scan: PASS root=$scanRoot"
    exit 0
} finally {
    Clear-ScanTemp
}
