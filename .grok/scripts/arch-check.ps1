# Architecture boundary checker with debt ratchet. ASCII only.
# Rules:    .grok/arch/boundaries.txt    lines:  deny <path-glob> -> <regex>
# Baseline: .grok/arch/arch-baseline.txt (legacy debt fingerprints, committed)
# Usage:
#   pwsh -File .grok/scripts/arch-check.ps1 [-Target .]                 # gate: NEW violations fail
#   pwsh -File .grok/scripts/arch-check.ps1 [-Target .] -BaselineWrite  # record current debt
# Exit 0 = clean or legacy-only. Exit 1 = new violations.
param([string]$Target = ".", [switch]$BaselineWrite)

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $Target
$rules = ".grok/arch/boundaries.txt"
$baselinePath = ".grok/arch/arch-baseline.txt"

if (-not (Test-Path $rules)) {
  Write-Host "arch-check: no $rules; nothing to enforce (green)"
  exit 0
}
if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
  Write-Host "arch-check: ripgrep (rg) required but not found; cannot enforce"
  exit 0
}

$current = New-Object System.Collections.Generic.List[string]
$ruleOf = @{}
$n = 0
foreach ($line in Get-Content -LiteralPath $rules) {
  $n++
  $t = $line.Trim()
  if ($t -eq "" -or $t.StartsWith("#")) { continue }
  if (-not $t.StartsWith("deny ")) {
    Write-Host "arch-check: ${rules}:${n}: unrecognized rule (expected: deny <glob> -> <regex>)"
    continue
  }
  $body = $t.Substring(5)
  $idx = $body.IndexOf(" -> ")
  if ($idx -lt 1) { Write-Host "arch-check: ${rules}:${n}: malformed rule"; continue }
  $scope = $body.Substring(0, $idx).Trim()
  $pattern = $body.Substring($idx + 4).Trim()
  $files = & rg -l --glob $scope -e $pattern . 2>$null | Where-Object { $_ -notmatch "^\.?[\\/]?\.grok[\\/]" }
  foreach ($f in @($files)) {
    if (-not $f) { continue }
    $norm = $f -replace "\\", "/"
    $fp = "deny $scope -> $pattern | $norm"
    $current.Add($fp)
    $ruleOf[$fp] = @($pattern, $norm)
  }
}
$currentSorted = @($current | Sort-Object -Unique)

if ($BaselineWrite) {
  $dir = Split-Path -Parent $baselinePath
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $header = @(
    "# arch-check debt baseline (legacy violations tolerated by the ratchet)",
    "# regenerate after paying off debt: pwsh -File .grok/scripts/arch-check.ps1 -BaselineWrite"
  )
  ($header + $currentSorted) | Set-Content -LiteralPath $baselinePath -Encoding UTF8
  Write-Host "arch-check: baseline written ($($currentSorted.Count) legacy violation(s)) -> $baselinePath"
  exit 0
}

function Show-Detail([string]$fp) {
  Write-Host "  $fp"
  if ($ruleOf.ContainsKey($fp)) {
    $pat = $ruleOf[$fp][0]; $file = $ruleOf[$fp][1]
    & rg -n -e $pat $file 2>$null | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" }
  }
}

if ($currentSorted.Count -gt 0) {
  if (Test-Path $baselinePath) {
    $known = @(Get-Content -LiteralPath $baselinePath | Where-Object { $_ -and -not $_.StartsWith("#") } | Sort-Object -Unique)
    $new = @($currentSorted | Where-Object { $known -notcontains $_ })
    $legacy = @($currentSorted | Where-Object { $known -contains $_ })
    $paid = @($known | Where-Object { $currentSorted -notcontains $_ })
    if ($paid.Count -gt 0) {
      Write-Host "arch-check: $($paid.Count) baselined violation(s) no longer present; consider -BaselineWrite to shrink the baseline"
    }
    if ($new.Count -gt 0) {
      Write-Host "NEW violations (not in baseline -- zero tolerance):"
      foreach ($v in $new) { Show-Detail $v }
      Write-Host "arch-check: FAIL ($($legacy.Count) legacy tolerated, new debt above)"
      exit 1
    }
    Write-Host "arch-check: PASS ($($legacy.Count) legacy violation(s) tolerated by baseline)"
    exit 0
  }
  Write-Host "Violations (no baseline -- all treated as new):"
  foreach ($v in $currentSorted) { Show-Detail $v }
  Write-Host "arch-check: FAIL (brownfield adoption: record legacy debt via -BaselineWrite, then keep new debt at zero)"
  exit 1
}

Write-Host "arch-check: PASS"
exit 0
