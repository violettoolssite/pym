@echo off
setlocal EnableDelayedExpansion

rem pvm - Python Version Manager for Windows
rem This is a batch wrapper that calls the PowerShell script

rem Set code page to UTF-8 for proper encoding
chcp 65001 >nul 2>&1

rem Get the directory where this script is located
set "PVM_DIR=%~dp0"

rem Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is required but not found.
    exit /b 1
)

rem Execute the PowerShell script with proper argument handling
powershell -NoProfile -ExecutionPolicy Bypass -File "%PVM_DIR%pvm.ps1" %*
exit /b %errorlevel%