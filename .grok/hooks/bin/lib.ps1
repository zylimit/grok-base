# Shared helpers for Grok project hooks (Windows / PowerShell).
# Env injected by Grok: GROK_WORKSPACE_ROOT, CLAUDE_PROJECT_DIR, GROK_SESSION_ID

function Get-ProjectRoot {
    if ($env:GROK_WORKSPACE_ROOT -and (Test-Path -LiteralPath $env:GROK_WORKSPACE_ROOT)) {
        return (Resolve-Path -LiteralPath $env:GROK_WORKSPACE_ROOT).Path
    }
    if ($env:CLAUDE_PROJECT_DIR -and (Test-Path -LiteralPath $env:CLAUDE_PROJECT_DIR)) {
        return (Resolve-Path -LiteralPath $env:CLAUDE_PROJECT_DIR).Path
    }
    # this file: <root>/.grok/hooks/bin/lib.ps1
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

function Read-HookStdin {
    $script:HookRaw = [Console]::In.ReadToEnd()
    if (-not $script:HookRaw) { $script:HookRaw = '' }
    try { $script:HookData = $script:HookRaw | ConvertFrom-Json } catch { $script:HookData = $null }
}

function Get-HookToolInput {
    if ($null -eq $script:HookData) { return $null }
    if ($script:HookData.PSObject.Properties.Name -contains 'toolInput') { return $script:HookData.toolInput }
    if ($script:HookData.PSObject.Properties.Name -contains 'tool_input') { return $script:HookData.tool_input }
    if ($script:HookData.PSObject.Properties.Name -contains 'input') { return $script:HookData.input }
    return $null
}

function Get-ToolCommand {
    $ti = Get-HookToolInput
    if ($null -ne $ti -and $ti.command) { return [string]$ti.command }
    return ''
}

function Write-GrokDeny([string]$Reason) {
    @{ decision = 'deny'; reason = $Reason } | ConvertTo-Json -Compress | Write-Output
}

function Write-GrokAllow {
    @{ decision = 'allow' } | ConvertTo-Json -Compress | Write-Output
}

function Get-FastModeFlagPath {
    Join-Path (Get-ProjectRoot) '.grok\.fast-mode'
}

function Test-FastModeActive {
    $flag = Get-FastModeFlagPath
    if (-not (Test-Path -LiteralPath $flag)) { return $false }
    $line = Get-Content -LiteralPath $flag -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '^expires_epoch=(\d+)$' } | Select-Object -First 1
    if (-not $line) { return $false }
    $expiry = [int64]($line -replace '^expires_epoch=', '')
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    return $expiry -gt $now
}

function Get-FastModeRemainingMinutes {
    $flag = Get-FastModeFlagPath
    $line = Get-Content -LiteralPath $flag -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '^expires_epoch=(\d+)$' } | Select-Object -First 1
    if (-not $line) { return $null }
    $expiry = [int64]($line -replace '^expires_epoch=', '')
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($expiry -le $now) { return $null }
    return [math]::Ceiling(($expiry - $now) / 60)
}
