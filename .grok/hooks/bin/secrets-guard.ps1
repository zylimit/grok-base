# PreToolUse (Read/Edit/Write): deny direct access to secret material. ASCII only.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    Read-HookStdin
    $paths = Get-ToolFilePaths
    if (-not $paths -or $paths.Count -eq 0) { Write-GrokAllow; exit 0 }

    function Test-SecretPath([string]$p) {
        $norm = $p -replace '\\', '/'
        $base = Split-Path -Leaf $norm
        if ($base -in @('.env.example', '.env.sample', '.env.template', 'env.example')) { return $false }
        if ($base -eq '.env' -or $base -like '.env.*') { return $true }
        foreach ($pre in @('id_rsa', 'id_ed25519', 'id_ecdsa', 'id_dsa')) {
            if ($base -like "$pre*") { return $true }
        }
        foreach ($ext in @('*.pem', '*.p12', '*.pfx', '*.keystore', '*.jks')) {
            if ($base -like $ext) { return $true }
        }
        if ($base -in @('credentials', 'credentials.json', '.netrc', '.npmrc', '.pypirc')) { return $true }
        foreach ($dir in @('/.ssh/', '/.aws/', '/.gnupg/', '/.grok/auth/')) {
            if ($norm -like "*$dir*") { return $true }
        }
        return $false
    }

    foreach ($p in $paths) {
        if (Test-SecretPath $p) {
            Write-GrokDeny "Access to secret material is blocked: $p. Use environment variables or a documented placeholder (.env.example)."
            exit 2
        }
    }
    Write-GrokAllow
    exit 0
} catch {
    Write-GrokAllow
    exit 0
}
