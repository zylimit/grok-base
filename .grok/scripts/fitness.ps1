# Five-attribute anti-pattern scan. ASCII only.
# Usage: pwsh -File .grok/scripts/fitness.ps1 [-Target .] [-AllowEmpty]
# Output: rule<TAB>file:line<TAB>snippet. Exit 1 if any finding.
param([string]$Target = ".", [switch]$AllowEmpty)

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $Target

$cSecret = 0; $cPii = 0; $cSwallow = 0; $cRetry = 0; $cTodo = 0
$findings = 0

function Test-SkipPath([string]$f) {
  $n = $f -replace '\\', '/'
  if ($n -match '(^|/)\.grok/|(^|/)\.git/|(^|/)node_modules/|(^|/)\.venv/|(^|/)venv/|(^|/)dist/|(^|/)target/|(^|/)__pycache__/') { return $true }
  if ($n -match '\.(png|jpg|jpeg|gif|webp|ico|pdf|zip|gz|tgz|woff2?|ttf|eot|bin|exe|dll|so|dylib|o|a|class|jar|pyc|pyo|wasm|mp3|mp4|mov|lock)$') { return $true }
  $leaf = Split-Path -Leaf $n
  if ($leaf -in @('.env.example', '.env.sample', '.env.template', '.env.dist') -or $leaf -like '*.example') { return $true }
  return $false
}

function Test-IsMd([string]$f) { return $f -match '\.(md|mdx|markdown)$' }

function Test-Placeholder([string]$v) {
  return [bool]($v -match '^(?i)(your[-_].*|x+|placeholder.*|change.?me|redacted|dummy|example|insert[-_].*|<[^>]+>|\$\{[^}]+\})$')
}

function Test-Ticket([string]$a, [string]$b, [string]$c) {
  $blob = "$a`n$b`n$c"
  return [bool]($blob -match '(?i)(^|[^A-Za-z])(issue|ticket)([^A-Za-z]|$)|#\d+')
}

$raw = @()
if (Get-Command git -ErrorAction SilentlyContinue) {
  Push-Location .
  try {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $raw = @(git ls-files 2>$null) }
  } catch { }
  Pop-Location
}
if ($raw.Count -eq 0) {
  $raw = @(Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
      $p = $_.FullName.Substring((Get-Location).Path.Length).TrimStart('\', '/') -replace '\\', '/'
      $p -notmatch '(^|/)\.git/|(^|/)node_modules/|(^|/)\.venv/|(^|/)dist/'
    } | ForEach-Object { $_.FullName.Substring((Get-Location).Path.Length).TrimStart('\', '/') -replace '\\', '/' })
}

$files = New-Object System.Collections.Generic.List[string]
foreach ($f in $raw) {
  if (-not $f) { continue }
  $n = $f -replace '\\', '/'
  if (Test-SkipPath $n) { continue }
  if (-not (Test-Path -LiteralPath $n -PathType Leaf)) { continue }
  try {
    if ((Get-Item -LiteralPath $n).Length -gt 1000000) { continue }
  } catch { continue }
  $files.Add($n)
}

if ($files.Count -eq 0) {
  Write-Host "fitness: no files to scan"
  Write-Host "counts: secret-literal=0 pii-log=0 swallow-error=0 unbounded-retry=0 hanging-todo=0"
  if ($AllowEmpty) { Write-Host "fitness: PASS (empty, --allow-empty)"; exit 0 }
  Write-Host "fitness: FAIL (empty; pass -AllowEmpty to allow)"
  exit 1
}

function Emit([string]$rule, [string]$loc, [string]$snippet) {
  $snippet = (($snippet -replace '[\t\r]', ' ').Trim())
  if ($snippet.Length -gt 160) { $snippet = $snippet.Substring(0, 160) }
  Write-Output ("{0}`t{1}`t{2}" -f $rule, $loc, $snippet)
  $script:findings++
  switch ($rule) {
    'secret-literal' { $script:cSecret++ }
    'pii-log' { $script:cPii++ }
    'swallow-error' { $script:cSwallow++ }
    'unbounded-retry' { $script:cRetry++ }
    'hanging-todo' { $script:cTodo++ }
  }
}

function Get-Line([string]$file, [int]$n) {
  if ($n -lt 1) { return '' }
  try {
    $ls = Get-Content -LiteralPath $file -ErrorAction Stop
    if ($n -le $ls.Count) { return [string]$ls[$n - 1] }
  } catch { }
  return ''
}

$secretPat = 'AKIA[0-9A-Z]{16}|-----BEGIN[ A-Z0-9]*PRIVATE KEY-----|(^|[^A-Za-z0-9_])sk-[A-Za-z0-9_-]{16,}|(password|passwd|api[_-]?key|secret|token)\s*=\s*[''"][^''"]+[''"]'
$piiPat = '(console\.(log|info|warn|debug|error)|logger\.(log|info|warn|debug|error|fine)|log\.(info|warn|debug|error|fine)|printf?|println|fmt\.Print[a-zA-Z]*)\s*\([^)\n]*(email|phone|id_card|password|token)'
$swallowPat = 'catch\s*(\([^)]*\))?\s*\{\s*\}|except[^:\n]*:\s*(pass|\.\.\.)\s*($|#)'

foreach ($f in $files) {
  $hits = @()
  try { $hits = @(Select-String -Path $f -Pattern $secretPat -AllMatches) } catch { $hits = @() }
  foreach ($h in $hits) {
    $line = $h.Line
    if ((Test-IsMd $f) -and ($line -match 'password\s*=\s*[''"]|token\s*=\s*[''"]') -and ($line -notmatch 'AKIA[0-9A-Z]{16}|BEGIN\s+[A-Z0-9 ]*PRIVATE\s+KEY')) { continue }
    $m = [regex]::Match($line, '[''"]([^''"]+)[''"]')
    if ($m.Success -and (Test-Placeholder $m.Groups[1].Value)) { continue }
    Emit 'secret-literal' ("{0}:{1}" -f $f, $h.LineNumber) $line
  }

  $hits = @()
  try { $hits = @(Select-String -Path $f -Pattern $piiPat) } catch { $hits = @() }
  foreach ($h in $hits) { Emit 'pii-log' ("{0}:{1}" -f $f, $h.LineNumber) $h.Line }

  $hits = @()
  try { $hits = @(Select-String -Path $f -Pattern $swallowPat) } catch { $hits = @() }
  foreach ($h in $hits) {
    $prev = Get-Line $f ($h.LineNumber - 1)
    if (("$prev`n$($h.Line)") -match '(#|//|/\*)\s*(fail-open|intentional|ignore|n/a|ok|expected)') { continue }
    if ($h.Line -match '(#|//).*(catch|except|pass)') { continue }
    Emit 'swallow-error' ("{0}:{1}" -f $f, $h.LineNumber) $h.Line
  }

  $lines = @()
  try { $lines = @(Get-Content -LiteralPath $f -ErrorAction Stop) } catch { continue }
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [string]$lines[$i]
    if ($i -gt 0 -and $lines[$i - 1] -match 'catch\s*(\([^)]*\))?\s*\{\s*$' -and $line -match '^\s*\}\s*($|#|//)') {
      if (("$($lines[$i-1])`n$line") -notmatch '(#|//|/\*)\s*(fail-open|intentional|ignore)') {
        Emit 'swallow-error' ("{0}:{1}" -f $f, ($i + 1)) "$($lines[$i-1]) / $line"
      }
    }
    if ($line -notmatch '(?i)while\s*\(\s*true\s*\)|while\s+True\s*:|while\s+true(\s*;|\s+do|\s*$)') { continue }
    $end = [Math]::Min($lines.Count - 1, $i + 24)
    $win = ($lines[$i..$end] -join "`n")
    if ($win -notmatch '(?i)\bretry|\bretries|\breconnect\b') { continue }
    if ($win -match '(?i)max[_-]?retr|max[_-]?attempt|attempt[s]?\s*[<>=]|retry_count|retries\s*[<>=]|for\s+[A-Za-z_][A-Za-z0-9_]*\s+in\s+range\(|break\s+after') { continue }
    Emit 'unbounded-retry' ("{0}:{1}" -f $f, ($i + 1)) $line
  }

  $hits = @()
  try { $hits = @(Select-String -Path $f -Pattern 'TODO|FIXME|XXX') } catch { $hits = @() }
  foreach ($h in $hits) {
    if ($h.Line -match '^\s*#{1,6}\s*(TODO|FIXME|XXX)\b') { continue }
    if ($h.Line -notmatch '(#|//|/\*|\*|<!--|--)\s*(TODO|FIXME|XXX)\b|^\s*(TODO|FIXME|XXX):') { continue }
    $prev = Get-Line $f ($h.LineNumber - 1)
    $next = Get-Line $f ($h.LineNumber + 1)
    if (Test-Ticket $prev $h.Line $next) { continue }
    Emit 'hanging-todo' ("{0}:{1}" -f $f, $h.LineNumber) $h.Line
  }
}

Write-Host ("fitness: scanned={0} findings={1}" -f $files.Count, $findings)
Write-Host ("counts: secret-literal={0} pii-log={1} swallow-error={2} unbounded-retry={3} hanging-todo={4}" -f $cSecret, $cPii, $cSwallow, $cRetry, $cTodo)
if ($findings -gt 0) { Write-Host "fitness: FAIL"; exit 1 }
Write-Host "fitness: PASS"
exit 0
