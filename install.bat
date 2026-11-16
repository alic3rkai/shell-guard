@echo off
rem Installs Shell Guard into Claude Code from this folder.
cd /d "%~dp0"
call claude plugin marketplace add "%~dp0."
if errorlevel 1 goto fail
call claude plugin install shell-guard@shell-guard
if errorlevel 1 goto fail
echo.
echo Shell Guard installed. Start a new Claude session to use it.
pause
exit /b 0
:fail
echo.
echo Install failed. Copy the text above and paste it to Claude.
pause
exit /b 1
