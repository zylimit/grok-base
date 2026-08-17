# PreToolUse (Bash|run_terminal_command): block secret read/copy/exfil.
# Safety rail; Fast Mode does NOT exempt. ASCII only.
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    Read-HookStdin
    $cmd = Get-ToolCommand
    if (-not $cmd) { Write-GrokAllow; exit 0 }

    function Strip-Examples([string]$c) {
        return ($c -replace '\.env\.(example|sample|template|dist)[A-Za-z0-9_.-]*', '')
    }

    function Strip-Wrappers([string]$c) {
        $prev = ''
        $i = 0
        while (($c -ne $prev) -and ($i -lt 5)) {
            $prev = $c
            $i++
            $c = $c.TrimStart()
            $c = $c -replace '^sudo\s+', ''
            $c = $c -replace '^nohup\s+', ''
            $c = $c -replace '^nice(\s+-n\s*\d+)?\s+', ''
            $c = $c -replace '^timeout(\s+--?[A-Za-z-]+(\s+\S+)?)*\s+\d+[smhd]?\s+', ''
            $c = $c -replace '^env(\s+[A-Za-z_][A-Za-z0-9_]*=\S*)*\s+', ''
            $c = $c -replace "^(ba|z|da)?sh\s+-l?c\s+[`"']?", ''
            $c = $c -replace "[`"']$", ''
        }
        return $c
    }

    $secretCore = '(\.env(\.[A-Za-z0-9_-]+)?|id_rsa[A-Za-z0-9_.-]*|id_ed25519[A-Za-z0-9_.-]*|id_ecdsa[A-Za-z0-9_.-]*|id_dsa[A-Za-z0-9_.-]*|\S*\.(pem|p12|pfx|keystore|jks|ppk)|credentials\.json|credentials|\.netrc|\.npmrc|\.pypirc|\.aws/credentials|\.ssh/\S+|\.gnupg/\S+|\.grok/auth/\S+)([\s"'']|$)'
    $argPfx = '\s+([^|;&]*[\s/"''=@])?'
    $anchor = '(^|;|&&|\|\||`|\$\()\s*'
    $script:reason = ''

    function Test-Exfil([string]$c) {
        $c = Strip-Examples $c
        if ($c -match "${anchor}(cat|less|head|tail|strings|xxd|od)${argPfx}${secretCore}") {
            $script:reason = 'secret-exfil: read of a secret file (cat/less/head/tail/strings/xxd/od + .env/key material)'
            return $true
        }
        if ($c -match "${anchor}(cp|scp|rsync|mv)${argPfx}${secretCore}") {
            $script:reason = 'secret-exfil: copy/move of a secret file (cp/scp/rsync/mv)'
            return $true
        }
        if ($c -match "${anchor}(env|printenv)(\s|$).*\|\s*(curl|wget|nc)\b") {
            $script:reason = 'secret-exfil: env/printenv piped to curl/wget/nc'
            return $true
        }
        if ($c -match "${anchor}(curl|wget|nc)${argPfx}${secretCore}") {
            $script:reason = 'secret-exfil: network command carrying a secret file (curl/wget/nc)'
            return $true
        }
        return $false
    }

    $stripped = Strip-Wrappers $cmd
    $hit = Test-Exfil $cmd
    if (-not $hit -and ($stripped -ne $cmd)) { $hit = Test-Exfil $stripped }
    if ($hit) {
        Write-GrokDeny $script:reason
        exit 2
    }
    Write-GrokAllow
    exit 0
} catch {
    Write-GrokAllow
    exit 0
}
