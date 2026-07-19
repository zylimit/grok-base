#!/usr/bin/env pwsh
# Usage: pwsh .grok/scripts/fast-mode.ps1 on [hours] | off | status
param(
    [ValidateSet('on', 'off', 'status')]
    [string]$Action = 'status',
    [ValidateRange(1, 8760)]
    [int]$Hours = 24
)
$ErrorActionPreference = 'Stop'
$projectDir = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$flag = Join-Path $projectDir '.grok/.fast-mode'

switch ($Action) {
    'on' {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $expires = $now + ($Hours * 3600)
        @(
            "enabled_epoch=$now"
            "expires_epoch=$expires"
            "hours=$Hours"
        ) | Set-Content -LiteralPath $flag -Encoding ascii
        Write-Output "fast-mode: on (${Hours}h; quality gates bypassed, safety guards remain active)"
    }
    'off' {
        Remove-Item -LiteralPath $flag -Force -ErrorAction SilentlyContinue
        Write-Output 'fast-mode: off (normal quality workflow restored)'
    }
    'status' {
        if (Test-Path -LiteralPath $flag) {
            $line = Get-Content -LiteralPath $flag | Where-Object { $_ -match '^expires_epoch=(\d+)$' } | Select-Object -First 1
            if ($line) {
                $expiry = [int64]($line -replace '^expires_epoch=', '')
                $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                if ($expiry -gt $now) {
                    $left = [math]::Ceiling(($expiry - $now) / 60)
                    Write-Output "fast-mode: on (about $left minutes remaining)"
                    break
                }
            }
            Write-Output 'fast-mode: expired (normal quality workflow is active; run off to remove stale state)'
        }
        else {
            Write-Output 'fast-mode: off'
        }
    }
}
