# ADR enforcement wiring check. ASCII only.
# Usage: pwsh -File .grok/scripts/adr-check.ps1 [-Target .]
# No docs/adr -> "nothing to check", exit 0.
param([string]$Target = ".")

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $Target

$dir = "docs/adr"
if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
  Write-Host "adr-check: nothing to check"
  exit 0
}
$files = @(Get-ChildItem -LiteralPath $dir -Filter "*.md" -File -ErrorAction SilentlyContinue)
if ($files.Count -eq 0) {
  Write-Host "adr-check: nothing to check"
  exit 0
}

function Strip-Md([string]$s) {
  return (($s -replace '\*\*', '' -replace '`', '' -replace '[\[\]]', '').Trim())
}

function Get-AdrField([string]$path, [string]$labels) {
  try {
    $hit = Select-String -Path $path -Pattern ("^\s*[-*]?\s*(\*\*)?({0})(\*\*)?\s*[:：]" -f $labels) |
      Select-Object -First 1
    if (-not $hit) { return '' }
    $line = $hit.Line
    $idx = $line.IndexOf(':')
    $idxFw = $line.IndexOf([char]0xFF1A)
    if ($idxFw -ge 0 -and ($idx -lt 0 -or $idxFw -lt $idx)) { $idx = $idxFw }
    if ($idx -lt 0) { return '' }
    return (Strip-Md $line.Substring($idx + 1))
  } catch { return '' }
}

function Test-Retired([string]$s) {
  return [bool]($s -match '(?i)superseded|deprecated|rejected|retired|已废弃|废弃|已取代|已否决|已替代')
}

function Test-Manual([string]$s) {
  return [bool]($s -match '^(?i)(manual|review|人工|评审|人工评审)$')
}

function Classify-Token([string]$raw) {
  $t = Strip-Md $raw
  if (-not $t) { return 'ghost' }
  $lower = $t.ToLowerInvariant()
  if ($lower -match '(^|[^a-z])(fitness\.sh|fitness)([^a-z]|$)') { return 'machine' }
  if ($lower -match '(^|[^a-z])(arch-check|boundaries)([^a-z]|$)') {
    if (Test-Path -LiteralPath '.grok/arch/boundaries.txt') { return 'machine' }
    return 'ghost'
  }
  if ((Test-Path -LiteralPath $t) -or (Test-Path -LiteralPath $lower)) { return 'machine' }
  $name = [IO.Path]::GetFileNameWithoutExtension($t)
  if (Test-Path -LiteralPath (".grok/scripts/{0}.sh" -f $name)) { return 'machine' }
  if (Test-Manual $t) { return 'manual' }
  if ($t -match '^[A-Za-z0-9._/-]+$') { return 'ghost' }
  return 'prose'
}

$fail = 0
$checked = 0
Write-Host ("adr-check: scanning {0} ADR file(s)" -f $files.Count)

foreach ($fi in $files) {
  $f = $fi.FullName
  $rel = $fi.Name
  $status = Get-AdrField $f '状态|Status'
  if (Test-Retired $status) {
    Write-Host ("  skip (retired): docs/adr/{0}  status={1}" -f $rel, $(if ($status) { $status } else { '?' }))
    continue
  }
  $checked++
  $enforced = Get-AdrField $f 'Enforced-by|Enforced by|执法方式'
  if (-not $enforced) {
    Write-Host ("  FAIL docs/adr/{0}: missing Enforced-by" -f $rel)
    $fail++
    continue
  }
  $parts = @($enforced -split '[，、；;,]')
  $machine = 0; $ghost = 0
  $ghosts = New-Object System.Collections.Generic.List[string]
  foreach ($p in $parts) {
    $tok = Strip-Md $p
    if (-not $tok) { continue }
    switch (Classify-Token $tok) {
      'machine' { $machine++ }
      'ghost' { $ghost++; $ghosts.Add($tok) }
    }
  }
  if ($ghost -gt 0) {
    Write-Host ("  FAIL docs/adr/{0}: ghost Enforced-by token(s): {1}  (raw: {2})" -f $rel, ($ghosts -join ';'), $enforced)
    $fail++
    continue
  }
  if ($machine -eq 0) {
    Write-Host ("  FAIL docs/adr/{0}: Enforced-by has no resolvable machine token (manual-only/empty does not count): {1}" -f $rel, $enforced)
    $fail++
    continue
  }
  Write-Host ("  ok docs/adr/{0}  enforced={1}" -f $rel, $enforced)
}

if ($checked -eq 0) {
  Write-Host "adr-check: nothing to check"
  exit 0
}
if ($fail -gt 0) {
  Write-Host ("adr-check: FAIL ({0}/{1} active ADR(s))" -f $fail, $checked)
  exit 1
}
Write-Host ("adr-check: PASS ({0} active ADR(s))" -f $checked)
exit 0
