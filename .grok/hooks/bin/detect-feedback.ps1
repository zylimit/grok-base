#!/usr/bin/env pwsh
# UserPromptSubmit: write signal file when correction phrases appear
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')
$root = Get-ProjectRoot
Read-HookStdin
$prompt = $null
if ($script:HookData) {
    foreach ($k in @('prompt', 'message', 'userPrompt')) {
        if ($script:HookData.PSObject.Properties.Name -contains $k -and $script:HookData.$k) {
            $prompt = [string]$script:HookData.$k
            break
        }
    }
}
if (-not $prompt) { exit 0 }

# Chinese correction phrases as unicode escapes (ASCII-safe for PS 5.1)
$signals = '\u4E0D\u662F\u8FD9\u6837|\u522B\u8FD9\u6837\u505A|\u4F60\u641E\u9519|\u641E\u9519\u4E86|\u4F60\u9519\u4E86|\u4E0D\u5BF9|\u4E0D\u5E94\u8BE5|\u4F60\u6F0F\u4E86|\u4F60\u5FD8\u4E86|\u6539\u4E00\u4E0B|\u4E0D\u5408\u7406|\u4F60\u7406\u89E3\u9519|\u6211\u8BF4\u7684\u4E0D\u662F|\u4E3A\u4EC0\u4E48\u6CA1|\u6CA1\u6709\u6267\u884C|\u6CA1\u6709\u751F\u6548|\u4E0D\u8981\u518D|\u522B\u518D|\u505C\u4E0B|\u5148\u4E0D\u8981|\u80FD\u4E0D\u80FD|wrong|incorrect|stop doing|do not|don''t'
if ($prompt -match $signals) {
    $stamp = [DateTimeOffset]::UtcNow.ToString('o')
    Set-Content -LiteralPath (Join-Path $root '.grok\.feedback-signal') -Value "detected_at=$stamp" -Encoding ascii
}
exit 0
