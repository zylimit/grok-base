@echo off
setlocal
set "HERE=%~dp0"
set "PS1=%HERE%mark-review.ps1"
if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
  "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
  exit /b %ERRORLEVEL%
)
where pwsh >nul 2>&1
if %ERRORLEVEL%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
  exit /b %ERRORLEVEL%
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
exit /b %ERRORLEVEL%