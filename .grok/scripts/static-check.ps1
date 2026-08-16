# Stack-aware static gate (Stage 0 of code-review). ASCII only.
# Usage: pwsh -File .grok/scripts/static-check.ps1 [-Target .]
# Exit 0 = green (missing tools skipped). Exit 1 = static errors found.
param([string]$Target = ".")

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $Target
$fail = $false
$ran = $false

function Have($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

if (Test-Path tsconfig.json) {
  if (Have npx) {
    $ran = $true
    Write-Host "== tsc --noEmit =="
    & npx --no-install tsc --noEmit
    if ($LASTEXITCODE -ne 0) { $fail = $true }
  } else { Write-Host "skip: tsconfig.json found but npx unavailable" }
}

$py = @()
if (Have git) { $py = @(git ls-files "*.py" 2>$null) }
if ($py.Count -gt 0) {
  $ran = $true
  if (Have ruff) {
    Write-Host "== ruff check =="
    & ruff check @py
    if ($LASTEXITCODE -ne 0) { $fail = $true }
  } elseif (Have python) {
    Write-Host "== py_compile =="
    & python -m py_compile @py
    if ($LASTEXITCODE -ne 0) { $fail = $true }
  } else { Write-Host "skip: python files found but ruff/python unavailable" }
}

if ((Test-Path Cargo.toml) -and (Have cargo)) {
  $ran = $true
  Write-Host "== cargo check -q =="
  & cargo check -q
  if ($LASTEXITCODE -ne 0) { $fail = $true }
}

$ps1files = @()
if (Have git) { $ps1files = @(git ls-files "*.ps1" 2>$null) }
foreach ($f in $ps1files) {
  $ran = $true
  $tokens = $null; $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $f), [ref]$tokens, [ref]$errors)
  if ($errors -and $errors.Count -gt 0) {
    Write-Host "ps1 parse errors in $f"
    $errors | ForEach-Object { Write-Host ("  " + $_.Message) }
    $fail = $true
  }
}

if (-not $ran) { Write-Host "static-check: no recognized stack or tools; skipped (green)" }

if ($fail) { Write-Host "static-check: FAIL"; exit 1 }
Write-Host "static-check: PASS"
exit 0
