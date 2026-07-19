# Shared helpers for Grok project hooks (Windows / PowerShell).
# Keep resilient: never throw to the host; callers wrap in try/catch too.

# Avoid native-command non-zero exits killing the script under $ErrorActionPreference=Stop
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }

function Get-ProjectRoot {
    try {
        if ($env:GROK_WORKSPACE_ROOT -and (Test-Path -LiteralPath $env:GROK_WORKSPACE_ROOT)) {
            return (Resolve-Path -LiteralPath $env:GROK_WORKSPACE_ROOT).Path
        }
        if ($env:CLAUDE_PROJECT_DIR -and (Test-Path -LiteralPath $env:CLAUDE_PROJECT_DIR)) {
            return (Resolve-Path -LiteralPath $env:CLAUDE_PROJECT_DIR).Path
        }
        if ($PSScriptRoot) {
            return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        }
    } catch { }
    return (Get-Location).Path
}

function Read-HookStdin {
    $script:HookRaw = ''
    $script:HookData = $null
    try {
        if ($null -ne [Console]::In) {
            $script:HookRaw = [Console]::In.ReadToEnd()
        }
    } catch {
        $script:HookRaw = ''
    }
    if (-not $script:HookRaw) { $script:HookRaw = '' }
    try {
        if ($script:HookRaw.Trim().Length -gt 0) {
            $script:HookData = $script:HookRaw | ConvertFrom-Json -ErrorAction Stop
        }
    } catch {
        $script:HookData = $null
    }
}

function Get-HookToolInput {
    try {
        if ($null -eq $script:HookData) { return $null }
        if ($script:HookData.PSObject.Properties.Name -contains 'toolInput') { return $script:HookData.toolInput }
        if ($script:HookData.PSObject.Properties.Name -contains 'tool_input') { return $script:HookData.tool_input }
        if ($script:HookData.PSObject.Properties.Name -contains 'input') { return $script:HookData.input }
    } catch { }
    return $null
}

function Get-ToolCommand {
    try {
        $ti = Get-HookToolInput
        if ($null -ne $ti -and $ti.command) { return [string]$ti.command }
    } catch { }
    return ''
}

function Write-GrokDeny([string]$Reason) {
    try {
        @{ decision = 'deny'; reason = $Reason } | ConvertTo-Json -Compress | Write-Output
    } catch {
        Write-Output '{"decision":"deny","reason":"blocked"}'
    }
}

function Write-GrokAllow {
    try {
        Write-Output '{"decision":"allow"}'
    } catch { }
}

function Get-FastModeFlagPath {
    Join-Path (Get-ProjectRoot) '.grok\.fast-mode'
}

function Test-FastModeActive {
    try {
        $flag = Get-FastModeFlagPath
        if (-not (Test-Path -LiteralPath $flag)) { return $false }
        $line = Get-Content -LiteralPath $flag -ErrorAction SilentlyContinue |
            Where-Object { $_ -match '^expires_epoch=(\d+)$' } | Select-Object -First 1
        if (-not $line) { return $false }
        $expiry = [int64]($line -replace '^expires_epoch=', '')
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        return ($expiry -gt $now)
    } catch {
        return $false
    }
}

function Get-FastModeRemainingMinutes {
    try {
        $flag = Get-FastModeFlagPath
        $line = Get-Content -LiteralPath $flag -ErrorAction SilentlyContinue |
            Where-Object { $_ -match '^expires_epoch=(\d+)$' } | Select-Object -First 1
        if (-not $line) { return $null }
        $expiry = [int64]($line -replace '^expires_epoch=', '')
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        if ($expiry -le $now) { return $null }
        return [math]::Ceiling(($expiry - $now) / 60)
    } catch {
        return $null
    }
}
