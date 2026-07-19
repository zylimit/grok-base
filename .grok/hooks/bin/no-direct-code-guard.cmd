@echo off
setlocal EnableDelayedExpansion
set "HERE=%~dp0"
cd /d "%~dp0" 2>nul
set "PS1=%HERE%no-direct-code-guard.ps1"
if not exist "!PS1!" (
  echo {"decision":"allow"}
  exit 0
)
set "RC=0"
if exist "%ProgramW6432%\PowerShell\7\pwsh.exe" (
  "%ProgramW6432%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "!PS1!"
  set "RC=!ERRORLEVEL!"
) else if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
  "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "!PS1!"
  set "RC=!ERRORLEVEL!"
) else if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
  "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "!PS1!"
  set "RC=!ERRORLEVEL!"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!PS1!"
  set "RC=!ERRORLEVEL!"
)
if not defined RC set "RC=0"
if "!RC!"=="" set "RC=0"
if "!RC!"=="2" exit 2
if not "!RC!"=="0" (
  echo {"decision":"allow"}
  exit 0
)
exit 0
