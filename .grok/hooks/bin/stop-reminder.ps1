# Stop is passive; write reminder only. Always exit 0.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    $root = Get-ProjectRoot
    $reminder = Join-Path $root '.grok\.stop-reminder'
    if (Test-FastModeActive) {
        Remove-Item -LiteralPath $reminder -Force -ErrorAction SilentlyContinue
        exit 0
    }
    $state = Join-Path $root '.grok\.needs-review'
    if (-not (Test-Path -LiteralPath $state)) {
        Remove-Item -LiteralPath $reminder -Force -ErrorAction SilentlyContinue
        exit 0
    }
    $files = @(Get-Content -LiteralPath $state -ErrorAction SilentlyContinue |
        Where-Object { $_.Trim() -and $_ -ne 'clean' })
    if ($files.Count -eq 0) {
        Remove-Item -LiteralPath $state -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $reminder -Force -ErrorAction SilentlyContinue
        exit 0
    }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $files) {
        $tab = $line.IndexOf([char]9)
        if ($tab -lt 0) { continue }
        $path = $line.Substring(0, $tab)
        $fp = $line.Substring($tab + 1)
        if (-not $path -or -not $fp) { continue }
        $abs = Join-Path $root ($path -replace '/', '\')
        if (-not (Test-Path -LiteralPath $abs -PathType Leaf)) { continue }
        $cur = Get-ReviewFingerprint $root $abs
        if ($cur -and $cur -ne $fp) {
            $stale = "REVIEW STALE: $path changed since it was marked; re-review."
            [void]$lines.Add($stale)
            Write-Output $stale
        }
    }
    $msg = "STOP REMINDER: $($files.Count) file(s) pending review. Dispatch code-reviewer, then write clean to .grok/.needs-review."
    [void]$lines.Add($msg)
    Set-Content -LiteralPath $reminder -Value $lines.ToArray() -Encoding ascii -ErrorAction SilentlyContinue
    Write-Output $msg
} catch { }
exit 0
