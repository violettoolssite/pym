@echo off
rem Elevate to admin and run pvm
rem Check if already admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c %~dp0pvm.cmd %*' -Verb RunAs"
    exit /b
)
rem Already admin, run pvm
call %~dp0pvm.cmd %*