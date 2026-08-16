# Codebase statistics skeleton for docs/CODEMAP.md (repo-navigator skill). ASCII only.
# Usage: pwsh -File .grok/scripts/codemap.ps1 [-Target .] [-Depth 2]
param([string]$Target = ".", [int]$Depth = 2)

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $Target

$files = @()
if ((Get-Command git -ErrorAction SilentlyContinue) -and (git rev-parse --is-inside-work-tree 2>$null)) {
  $files = @(git ls-files)
} else {
  $files = @(Get-ChildItem -Recurse -File | Where-Object {
    $_.FullName -notmatch "[\\/](\.git|node_modules|target|dist|\.venv)[\\/]"
  } | ForEach-Object { $_.FullName.Substring((Get-Location).Path.Length + 1) -replace "\\", "/" })
}

$stats = @{}
$ext = @{}
foreach ($f in $files) {
  $seg = $f -split "/"
  if ($seg.Count -eq 1) { $key = "(root)" }
  else {
    $lim = [Math]::Min($seg.Count - 1, $Depth)
    $key = ($seg[0..($lim - 1)] -join "/")
  }
  $lines = 0
  try { $lines = (Get-Content -LiteralPath $f -ErrorAction Stop | Measure-Object -Line).Lines } catch {}
  if (-not $stats.ContainsKey($key)) { $stats[$key] = @{ files = 0; lines = 0 } }
  $stats[$key].files++
  $stats[$key].lines += $lines
  $m = [regex]::Match($f, "\.([A-Za-z0-9_]{1,8})$")
  if ($m.Success) {
    $e = $m.Groups[1].Value
    if (-not $ext.ContainsKey($e)) { $ext[$e] = 0 }
    $ext[$e]++
  }
}

$today = Get-Date -Format "yyyy-MM-dd"
Write-Output "# CODEMAP stats skeleton ($today) - merge into docs/CODEMAP.md"
Write-Output ""
Write-Output "Total tracked files: $($files.Count)"
Write-Output ""
Write-Output "## Directory stats (top $Depth levels, by lines desc, Top 40)"
Write-Output ""
Write-Output "| Directory | Files | Lines |"
Write-Output "|---|---|---|"
$stats.GetEnumerator() | Sort-Object { $_.Value.lines } -Descending | Select-Object -First 40 | ForEach-Object {
  Write-Output "| $($_.Key)/ | $($_.Value.files) | $($_.Value.lines) |"
}
Write-Output ""
Write-Output "## Language histogram (by extension, Top 12)"
Write-Output ""
Write-Output "| Ext | Files |"
Write-Output "|---|---|"
$ext.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 12 | ForEach-Object {
  Write-Output "| .$($_.Key) | $($_.Value) |"
}
Write-Output ""
Write-Output "## To fill manually"
Write-Output ""
Write-Output "- One-line responsibility per module (fan out explore subagents)"
Write-Output "- Quick entries (start/config/build/test commands)"
Write-Output "- No-go zones and pitfalls"
