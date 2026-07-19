@echo off
setlocal EnableDelayedExpansion
set "HERE=%~dp0"
set "PS1=%HERE%block-pkill.ps1"
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
exit /b !RC!
