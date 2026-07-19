#!/usr/bin/env pwsh
# setup.ps1 - inject grok-base into a target project (Windows).
# Usage:
#   pwsh -File setup.ps1 [-Target <dir>] [-Force]
# Without -Target, installs into the current directory.
#
# Does:
#   1) Copy AGENTS.md + .grok/ (skip runtime / private feedback)
#   2) FRAMEWORK-MANIFEST upgrade safety (user edits -> .framework-new)
#   3) Write Windows project-hooks.json (bin/*.cmd + GROK_WORKSPACE_ROOT)
#   4) Reset FEEDBACK-INDEX from template
#   5) Optional doctor at the end
[CmdletBinding()]
param(
    [string]$Target = '.',
    [switch]$Force,
    [switch]$SkipDoctor
)
$ErrorActionPreference = 'Stop'

function Write-Info([string]$msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "[ok] $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }

$root = $PSScriptRoot
$srcGrok = Join-Path $root '.grok'
$srcAgents = Join-Path $root 'AGENTS.md'
if (-not (Test-Path -LiteralPath $srcGrok)) {
    throw "No .grok under setup directory (run from grok-base repo root): $srcGrok"
}
if (-not (Test-Path -LiteralPath $srcAgents)) {
    throw "No AGENTS.md under setup directory: $srcAgents"
}

if (-not (Test-Path -LiteralPath $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}
$Target = (Resolve-Path -LiteralPath $Target).Path
$targetGrok = Join-Path $Target '.grok'
$targetAgents = Join-Path $Target 'AGENTS.md'

Write-Info '=== grok-base setup (Windows) ==='
Write-Host "target: $Target"

# Advisory checks
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Ok "git: $((git --version) 2>$null)"
} else {
    Write-Warn 'git not detected'
}
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Ok "pwsh: $((pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') 2>$null)"
} else {
    Write-Warn 'pwsh not detected (hooks prefer PowerShell 7)'
}
if (Get-Command grok -ErrorAction SilentlyContinue) {
    Write-Ok 'grok CLI detected'
} else {
    Write-Warn 'grok CLI not detected (optional for install)'
}

function Test-FilesEqual([string]$a, [string]$b) {
    if (-not (Test-Path -LiteralPath $b)) { return $false }
    return (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $b -Algorithm SHA256).Hash
}

function Get-NormalizedSha([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $filtered = [byte[]]($bytes | Where-Object { $_ -ne 13 })
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($filtered)) -replace '-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Copy-WithBackup([string]$src, [string]$dest) {
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if ((Test-Path -LiteralPath $dest) -and -not (Test-FilesEqual $src $dest)) {
        Copy-Item -LiteralPath $dest -Destination "$dest.bak" -Force
        Write-Host "backup: $dest.bak"
    }
    Copy-Item -LiteralPath $src -Destination $dest -Force
}

# Load old manifest from target (for upgrade safety)
$oldManifest = @{}
$oldManifestPath = Join-Path $targetGrok 'FRAMEWORK-MANIFEST.txt'
if (Test-Path -LiteralPath $oldManifestPath) {
    foreach ($line in Get-Content -LiteralPath $oldManifestPath) {
        if ($line -match '^#' -or -not $line.Trim()) { continue }
        $parts = $line -split "`t"
        if ($parts.Count -ge 2) { $oldManifest[$parts[0]] = $parts[1] }
    }
}
$script:frameworkNewList = New-Object System.Collections.Generic.List[string]

# Skip runtime / machine / private feedback (basename or path rules)
$skipNames = @(
    'FRAMEWORK-MANIFEST.txt',
    'project-hooks.json',   # regenerated for this OS
    'settings.local.json',
    'config.local.toml',
    '.needs-review', '.needs-review.lock',
    '.fast-mode', '.stop-reminder', '.feedback-signal',
    '.subagent-reminded', '.tdd-exempt', '.red-verified', '.static-gate', '.degraded-review',
    'signals.jsonl'
)

function Test-ShouldSkip([string]$relSlash) {
    $leaf = Split-Path $relSlash -Leaf
    if ($skipNames -contains $leaf) { return $true }
    if ($relSlash -match '\.(bak|framework-new)$') { return $true }
    if ($relSlash -match '^feedback/[^/]+\.md$') { return $true }  # private feedback + INDEX (reset later)
    if ($relSlash -match '^evidence/') { return $true }
    return $false
}

# --- 1) AGENTS.md ---
if ((Test-Path -LiteralPath $targetAgents) -and -not $Force) {
    if (-not (Test-FilesEqual $srcAgents $targetAgents)) {
        $agentsShaOld = $oldManifest['../AGENTS.md']
        # AGENTS is outside .grok; treat as framework file with special key
        if ($agentsShaOld -and ((Get-NormalizedSha $targetAgents) -eq $agentsShaOld)) {
            Copy-WithBackup $srcAgents $targetAgents
            Write-Ok 'AGENTS.md upgraded (matched previous framework version)'
        } else {
            Copy-Item -LiteralPath $srcAgents -Destination "$targetAgents.framework-new" -Force
            $script:frameworkNewList.Add('AGENTS.md')
            Write-Warn 'AGENTS.md differs; wrote AGENTS.md.framework-new (not overwriting)'
        }
    } else {
        Write-Ok 'AGENTS.md already up to date'
    }
} else {
    if ((Test-Path -LiteralPath $targetAgents) -and $Force) {
        Copy-WithBackup $srcAgents $targetAgents
    } else {
        Copy-Item -LiteralPath $srcAgents -Destination $targetAgents -Force
    }
    Write-Ok 'AGENTS.md installed'
}

# --- 2) Copy .grok tree ---
if (-not (Test-Path -LiteralPath $targetGrok)) {
    New-Item -ItemType Directory -Path $targetGrok -Force | Out-Null
}
$srcRootLen = (Resolve-Path -LiteralPath $srcGrok).Path.Length
Get-ChildItem -Path $srcGrok -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($srcRootLen).TrimStart('\', '/')
    $relSlash = $rel -replace '\\', '/'
    if (Test-ShouldSkip $relSlash) { return }

    $dest = Join-Path $targetGrok $rel
    if ((Test-Path -LiteralPath $dest) -and -not (Test-FilesEqual $_.FullName $dest)) {
        $oldSha = $oldManifest[$relSlash]
        if (-not ($oldSha -and ((Get-NormalizedSha $dest) -eq $oldSha))) {
            Copy-Item -LiteralPath $_.FullName -Destination "$dest.framework-new" -Force
            $script:frameworkNewList.Add($relSlash)
            return
        }
    }
    Copy-WithBackup $_.FullName $dest
}
Write-Ok '.grok framework files copied'

# --- 3) Windows hooks JSON (cmd entrypoints) ---
$hooksDir = Join-Path $targetGrok 'hooks'
$binDir = Join-Path $hooksDir 'bin'
if (-not (Test-Path -LiteralPath $binDir)) {
    throw "hooks bin missing after copy: $binDir"
}

# Ensure hardened .cmd wrappers exist (generate if missing)
$hookNames = @(
    'session-start', 'session-rules-banner', 'detect-feedback',
    'block-pkill', 'pre-commit-check', 'no-direct-code-guard',
    'mark-review', 'stop-reminder'
)
# Passive hooks: always process-exit 0 (never red-bar SessionStart/Stop/etc.)
# Blocking hooks: preserve exit 2 (deny); other non-zero fail-open allow + exit 0
$passiveHooks = @('session-start', 'session-rules-banner', 'detect-feedback', 'mark-review', 'stop-reminder')
foreach ($h in $hookNames) {
    $cmdPath = Join-Path $binDir "$h.cmd"
    $ps1Path = Join-Path $binDir "$h.ps1"
    if (-not (Test-Path -LiteralPath $ps1Path)) {
        Write-Warn "missing $h.ps1 (skip cmd generate)"
        continue
    }
    $isPassive = $passiveHooks -contains $h
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]]@(
        '@echo off'
        'setlocal EnableDelayedExpansion'
        'set "HERE=%~dp0"'
        'cd /d "%~dp0" 2>nul'
        "set `"PS1=%HERE%$h.ps1`""
        'if not exist "!PS1!" ('
    ))
    if ($isPassive) {
        $lines.Add('  exit 0')
    } else {
        $lines.Add('  echo {"decision":"allow"}')
        $lines.Add('  exit 0')
    }
    $lines.AddRange([string[]]@(
        ')'
        'set "RC=0"'
        'if exist "%ProgramW6432%\PowerShell\7\pwsh.exe" ('
        '  "%ProgramW6432%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "!PS1!"'
        '  set "RC=!ERRORLEVEL!"'
        ') else if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" ('
        '  "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "!PS1!"'
        '  set "RC=!ERRORLEVEL!"'
        ') else if exist "C:\Program Files\PowerShell\7\pwsh.exe" ('
        '  "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "!PS1!"'
        '  set "RC=!ERRORLEVEL!"'
        ') else ('
        '  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!PS1!"'
        '  set "RC=!ERRORLEVEL!"'
        ')'
        'if not defined RC set "RC=0"'
        'if "!RC!"=="" set "RC=0"'
    ))
    if ($isPassive) {
        # Use process exit (not exit /b) so Grok wrapper exit code is reliable
        $lines.Add('exit 0')
    } else {
        $lines.AddRange([string[]]@(
            'if "!RC!"=="2" exit 2'
            'if not "!RC!"=="0" ('
            '  echo {"decision":"allow"}'
            '  exit 0'
            ')'
            'exit 0'
        ))
    }
    $text = ($lines -join "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText($cmdPath, $text, [System.Text.Encoding]::ASCII)
}
Write-Ok 'Windows .cmd hook wrappers written (hardened exit codes)'

# Relative to project-hooks.json (official Grok docs) — avoids ${GROK_WORKSPACE_ROOT} expansion issues on Windows
$hooksJsonText = @'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bin/session-start.cmd", "timeout": 10 },
          { "type": "command", "command": "bin/session-rules-banner.cmd", "timeout": 5 }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "bin/detect-feedback.cmd", "timeout": 5 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash|run_terminal_command",
        "hooks": [
          { "type": "command", "command": "bin/block-pkill.cmd", "timeout": 5 },
          { "type": "command", "command": "bin/pre-commit-check.cmd", "timeout": 30 }
        ]
      },
      {
        "matcher": "Edit|Write|MultiEdit|search_replace",
        "hooks": [
          { "type": "command", "command": "bin/no-direct-code-guard.cmd", "timeout": 5 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit|search_replace",
        "hooks": [
          { "type": "command", "command": "bin/mark-review.cmd", "timeout": 5 }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bin/stop-reminder.cmd", "timeout": 5 }
        ]
      }
    ]
  }
}
'@

$hooksPath = Join-Path $hooksDir 'project-hooks.json'
if ((Test-Path -LiteralPath $hooksPath) -and -not $Force) {
    Copy-Item -LiteralPath $hooksPath -Destination "$hooksPath.bak" -Force -ErrorAction SilentlyContinue
}
[System.IO.File]::WriteAllText($hooksPath, $hooksJsonText.Trim() + "`n", [System.Text.UTF8Encoding]::new($false))
Write-Ok 'project-hooks.json written (Windows .cmd entrypoints)'

# --- 4) Reset feedback index ---
$fbTpl = Join-Path $srcGrok 'feedback\templates\feedback-index-template.md'
$fbIndex = Join-Path $targetGrok 'feedback\FEEDBACK-INDEX.md'
if (Test-Path -LiteralPath $fbTpl) {
    $fbDir = Split-Path $fbIndex -Parent
    if (-not (Test-Path -LiteralPath $fbDir)) {
        New-Item -ItemType Directory -Path $fbDir -Force | Out-Null
    }
    Copy-WithBackup $fbTpl $fbIndex
    Write-Ok 'FEEDBACK-INDEX.md reset from template'
}

# --- 5) Install / refresh FRAMEWORK-MANIFEST ---
$srcManifest = Join-Path $srcGrok 'FRAMEWORK-MANIFEST.txt'
if (Test-Path -LiteralPath $srcManifest) {
    Copy-WithBackup $srcManifest (Join-Path $targetGrok 'FRAMEWORK-MANIFEST.txt')
    Write-Ok 'FRAMEWORK-MANIFEST.txt installed'
} else {
    Write-Warn 'FRAMEWORK-MANIFEST.txt missing in source (run .grok/scripts/gen-manifest.ps1)'
}

if ($script:frameworkNewList.Count -gt 0) {
    Write-Warn ("{0} user-modified file(s) were NOT overwritten; see *.framework-new:" -f $script:frameworkNewList.Count)
    foreach ($f in $script:frameworkNewList) {
        Write-Host "  - $f"
    }
}

$skillCount = @(Get-ChildItem (Join-Path $targetGrok 'skills') -Directory -ErrorAction SilentlyContinue).Count
$agentCount = @(Get-ChildItem (Join-Path $targetGrok 'agents') -File -ErrorAction SilentlyContinue).Count
$cmdCount = @(Get-ChildItem (Join-Path $targetGrok 'hooks\bin') -Filter '*.cmd' -ErrorAction SilentlyContinue).Count
Write-Ok "installed skills=$skillCount agents=$agentCount cmd_hooks=$cmdCount"

if (-not $SkipDoctor) {
    $doctor = Join-Path $targetGrok 'scripts\doctor.ps1'
    if (Test-Path -LiteralPath $doctor) {
        Write-Info '=== doctor ==='
        & pwsh -NoProfile -File $doctor -Target $Target
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "doctor reported issues (exit $LASTEXITCODE)"
        }
    } else {
        Write-Warn 'doctor.ps1 not found; skip health check'
    }
}

Write-Host ''
Write-Host 'Done. Open the target project in Grok.' -ForegroundColor Green
Write-Host '  - Trust project hooks if prompted: /hooks-trust or grok --trust'
Write-Host '  - Reload hooks after install (restart session or Hooks panel reload)'
exit 0
