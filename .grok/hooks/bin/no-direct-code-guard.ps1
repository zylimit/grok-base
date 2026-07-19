# PreToolUse on edit tools: main agent should not write business source directly
$ErrorActionPreference = 'Continue'
try { $global:PSNativeCommandUseErrorActionPreference = $false } catch { }
try {
    . (Join-Path $PSScriptRoot 'lib.ps1')
    if (Test-FastModeActive) { Write-GrokAllow; exit 0 }
    Read-HookStdin
    $ti = Get-HookToolInput
    $filePath = $null
    if ($ti) {
        foreach ($k in @('file_path', 'path', 'target_file')) {
            if ($ti.PSObject.Properties.Name -contains $k -and $ti.$k) {
                $filePath = [string]$ti.$k
                break
            }
        }
    }
    if (-not $filePath) { Write-GrokAllow; exit 0 }

    $fp = $filePath -replace '\\', '/'
    # Framework / docs pass
    if ($fp -match '(\.grok/|AGENTS\.md|Product-Spec|DEV-PLAN|progress\.md|CHANGELOG|/feedback/|/agents/|/skills/|/hooks/|/roles/|/personas/|\.md$|\.json$|\.toml$|\.cmd$|\.ps1$|\.sh$)') {
        Write-GrokAllow
        exit 0
    }
    # Business source paths
    if ($fp -match '(^|/)(src|app|lib|components|pages|api|server|client|utils|models|services|conflation)/') {
        Write-GrokDeny "Main agent should not write business source directly: $filePath. Dispatch implementer Sub-Agent."
        exit 2
    }
    Write-GrokAllow
    exit 0
} catch {
    Write-GrokAllow
    exit 0
}
