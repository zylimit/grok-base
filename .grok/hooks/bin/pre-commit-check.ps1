#!/usr/bin/env pwsh
# PreToolUse: light compile/syntax gate when command is git commit
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')
$root = Get-ProjectRoot
Read-HookStdin
$cmd = Get-ToolCommand
if ($cmd -notmatch 'git\s+commit') { Write-GrokAllow; exit 0 }
if (Test-FastModeActive) { Write-GrokAllow; exit 0 }

$staged = @(git -C $root diff --cached --name-only --diff-filter=ACM 2>$null)
if ($staged.Count -eq 0) { Write-GrokAllow; exit 0 }
$failed = $false

if (($staged -join "`n") -match '\.(ts|tsx)$' -and (Get-Command npx -ErrorAction SilentlyContinue)) {
    $tsconfig = Get-ChildItem -LiteralPath $root -Filter tsconfig.json -Recurse -Depth 3 -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch 'node_modules|\.next' } | Select-Object -First 1
    if ($tsconfig) {
        Push-Location $tsconfig.DirectoryName
        try {
            npx --no-install tsc --noEmit
            if ($LASTEXITCODE -ne 0) { $failed = $true }
        } finally { Pop-Location }
    }
}

$pyFiles = @($staged | Where-Object { $_ -match '\.py$' } | ForEach-Object { Join-Path $root $_ })
if ($pyFiles.Count -gt 0) {
    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff check @pyFiles
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    } elseif (Get-Command py -ErrorAction SilentlyContinue) {
        foreach ($f in $pyFiles) { py -3 -m py_compile $f; if ($LASTEXITCODE -ne 0) { $failed = $true } }
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        foreach ($f in $pyFiles) { python -m py_compile $f; if ($LASTEXITCODE -ne 0) { $failed = $true } }
    }
}

if ($failed) {
    Write-GrokDeny 'Pre-commit compile/syntax gate failed.'
    exit 2
}
Write-GrokAllow
exit 0
