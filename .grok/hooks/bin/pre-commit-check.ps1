# PreToolUse: light compile/syntax gate when command is git commit
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    $root = Get-ProjectRoot
    Read-HookStdin
    $cmd = Get-ToolCommand
    if ($cmd -notmatch 'git\s+commit') { Write-GrokAllow; exit 0 }
    if (Test-FastModeActive) { Write-GrokAllow; exit 0 }

    $staged = @()
    try {
        $staged = @(git -C $root diff --cached --name-only --diff-filter=ACM 2>$null)
    } catch { $staged = @() }
    if ($staged.Count -eq 0) { Write-GrokAllow; exit 0 }

    $failed = $false
    try {
        if (($staged -join "`n") -match '\.(ts|tsx)$' -and (Get-Command npx -ErrorAction SilentlyContinue)) {
            $tsconfig = Get-ChildItem -LiteralPath $root -Filter tsconfig.json -Recurse -Depth 3 -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch 'node_modules|\.next' } | Select-Object -First 1
            if ($tsconfig) {
                Push-Location $tsconfig.DirectoryName
                try {
                    & npx --no-install tsc --noEmit 2>$null | Out-Null
                    if ($LASTEXITCODE -ne 0) { $failed = $true }
                } finally { Pop-Location }
            }
        }
    } catch { }

    try {
        $pyFiles = @($staged | Where-Object { $_ -match '\.py$' } | ForEach-Object { Join-Path $root $_ })
        if ($pyFiles.Count -gt 0) {
            if (Get-Command ruff -ErrorAction SilentlyContinue) {
                & ruff check @pyFiles 2>$null | Out-Null
                if ($LASTEXITCODE -ne 0) { $failed = $true }
            } elseif (Get-Command python -ErrorAction SilentlyContinue) {
                foreach ($f in $pyFiles) {
                    & python -m py_compile $f 2>$null | Out-Null
                    if ($LASTEXITCODE -ne 0) { $failed = $true }
                }
            }
        }
    } catch { }

    if ($failed) {
        Write-GrokDeny 'Pre-commit compile/syntax gate failed.'
        exit 2
    }
    Write-GrokAllow
    exit 0
} catch {
    Write-GrokAllow
    exit 0
}
