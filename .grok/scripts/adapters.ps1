#!/usr/bin/env pwsh
# Curated external-tool table (probe PATH only; not a wiring engine).
# Usage: pwsh -File .grok/scripts/adapters.ps1 [-Strict]
# Default: print PRESENT/MISSING per row, exit 0.
# -Strict: any MISSING -> exit 1.
[CmdletBinding()]
param([switch]$Strict)
$ErrorActionPreference = 'Continue'

$rows = @(
    @{ Name = 'gitleaks'; Command = 'gitleaks'; Purpose = 'secret scan'; Nfr = 'Security' }
    @{ Name = 'semgrep'; Command = 'semgrep'; Purpose = 'SAST'; Nfr = 'Security' }
    @{ Name = 'osv-scanner'; Command = 'osv-scanner'; Purpose = 'dep CVE'; Nfr = 'Security' }
    @{ Name = 'pip-audit'; Command = 'pip-audit'; Purpose = 'Python deps'; Nfr = 'Security' }
    @{ Name = 'npm'; Command = 'npm'; Purpose = 'npm audit'; Nfr = 'Security' }
    @{ Name = 'cargo-audit'; Command = 'cargo-audit'; Purpose = 'Rust deps'; Nfr = 'Security' }
    @{ Name = 'shellcheck'; Command = 'shellcheck'; Purpose = 'shell static'; Nfr = 'Reliability' }
)

Write-Output "name`tcommand`tpurpose`tnfr`tstatus"
$present = 0
$missing = 0
foreach ($r in $rows) {
    if (Get-Command $r.Command -ErrorAction SilentlyContinue) {
        $status = 'PRESENT'
        $present++
    } else {
        $status = 'MISSING'
        $missing++
    }
    Write-Output ("{0}`t{1}`t{2}`t{3}`t{4}" -f $r.Name, $r.Command, $r.Purpose, $r.Nfr, $status)
}
Write-Output "adapters: $present PRESENT, $missing MISSING"
if ($Strict -and $missing -gt 0) { exit 1 }
exit 0
