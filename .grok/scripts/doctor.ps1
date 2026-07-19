#!/usr/bin/env pwsh
# doctor.ps1 - verify grok-base install in a project
# Usage: pwsh -File .grok/scripts/doctor.ps1 [-Target <dir>]
[CmdletBinding()]
param([string]$Target = '.')
$ErrorActionPreference = 'Continue'

function Ok([string]$m) { Write-Host "[ok] $m" -ForegroundColor Green }
function Bad([string]$m) { Write-Host "[x] $m" -ForegroundColor Red; $script:fail++ }
function Note([string]$m) { Write-Host "[!] $m" -ForegroundColor Yellow; $script:warn++ }

$script:fail = 0
$script:warn = 0

if (-not (Test-Path -LiteralPath $Target)) { Bad "target missing: $Target"; exit 2 }
$Target = (Resolve-Path -LiteralPath $Target).Path
Set-Location $Target

Write-Host "=== grok-base doctor ==="
Write-Host "target: $Target"

# AGENTS.md
if (Test-Path -LiteralPath 'AGENTS.md') { Ok 'AGENTS.md exists' } else { Bad 'AGENTS.md missing' }

# .grok tree
if (Test-Path -LiteralPath '.grok') { Ok '.grok exists' } else { Bad '.grok missing'; exit 1 }

$roles = @('implementer','code-reviewer','tester','deployer','feedback-observer','evolution-runner','progress-recorder')
foreach ($r in $roles) {
    if (Test-Path -LiteralPath ".grok\agents\$r.md") { Ok "agent $r" } else { Bad "agent $r missing" }
    if (Test-Path -LiteralPath ".grok\roles\$r.toml") { Ok "role $r" } else { Bad "role $r missing" }
    if (Test-Path -LiteralPath ".grok\personas\$r.toml") { Ok "persona $r" } else { Bad "persona $r missing" }
}

$skills = @(Get-ChildItem '.grok\skills' -Directory -ErrorAction SilentlyContinue)
if ($skills.Count -ge 10) { Ok "skills count=$($skills.Count)" } else { Bad "skills count low: $($skills.Count)" }
foreach ($s in $skills) {
    if (-not (Test-Path -LiteralPath (Join-Path $s.FullName 'SKILL.md'))) {
        Bad "skill missing SKILL.md: $($s.Name)"
    }
}

if (Test-Path -LiteralPath '.grok\hooks\project-hooks.json') {
    try {
        Get-Content -LiteralPath '.grok\hooks\project-hooks.json' -Raw | ConvertFrom-Json | Out-Null
        Ok 'project-hooks.json valid JSON'
    } catch {
        Bad 'project-hooks.json invalid JSON'
    }
} else {
    Bad 'project-hooks.json missing'
}

$isWin = $env:OS -match 'Windows' -or $IsWindows
if ($isWin) {
    $cmds = @(Get-ChildItem '.grok\hooks\bin\*.cmd' -ErrorAction SilentlyContinue)
    if ($cmds.Count -ge 6) { Ok "cmd hooks=$($cmds.Count)" } else { Bad "cmd hooks low: $($cmds.Count)" }
    foreach ($c in $cmds) {
        $ps1 = [IO.Path]::ChangeExtension($c.FullName, '.ps1')
        if (-not (Test-Path -LiteralPath $ps1)) { Bad "missing ps1 for $($c.Name)" }
    }
} else {
    $shs = @(Get-ChildItem '.grok\hooks\bin\*.sh' -ErrorAction SilentlyContinue)
    if ($shs.Count -ge 6) { Ok "sh hooks=$($shs.Count)" } else { Bad "sh hooks low: $($shs.Count)" }
}

# Spawn smoke (Windows .cmd)
if ($isWin) {
    $env:GROK_WORKSPACE_ROOT = $Target
    $hook = Join-Path $Target '.grok\hooks\bin\block-pkill.cmd'
    if (Test-Path -LiteralPath $hook) {
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $hook
            $psi.UseShellExecute = $false
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true
            $psi.WorkingDirectory = $Target
            $psi.EnvironmentVariables['GROK_WORKSPACE_ROOT'] = $Target
            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $psi
            [void]$p.Start()
            $p.StandardInput.Write('{"toolInput":{"command":"echo hi"}}')
            $p.StandardInput.Close()
            $out = $p.StandardOutput.ReadToEnd()
            $p.WaitForExit(15000)
            if ($p.ExitCode -eq 0 -and $out -match 'allow') {
                Ok "spawn smoke block-pkill.cmd exit=0"
            } else {
                Bad "spawn smoke failed exit=$($p.ExitCode) out=$out"
            }
        } catch {
            Bad "spawn smoke exception: $($_.Exception.Message)"
        }
    }
}

if (Get-Command pwsh -ErrorAction SilentlyContinue) { Ok 'pwsh available' } else { Note 'pwsh not in PATH' }
if (Get-Command git -ErrorAction SilentlyContinue) { Ok 'git available' } else { Note 'git not in PATH' }

if ($script:fail -gt 0) {
    Write-Host "doctor: FAILED ($($script:fail) error(s))" -ForegroundColor Red
    exit 1
}
if ($script:warn -gt 0) {
    Write-Host "doctor: passed with warnings ($($script:warn))" -ForegroundColor Yellow
    exit 0
}
Write-Host 'doctor: passed' -ForegroundColor Green
exit 0
