@echo off
setlocal EnableDelayedExpansion

:: pvm - Python Version Manager for Windows
:: This is a batch wrapper that calls the PowerShell script

:: Get the directory where this script is located
set "PVM_DIR=%~dp0"

:: Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is required but not found.
    exit /b 1
)

:: Build the argument string
set "ARGS="
:parse_args
if "%~1"=="" goto run
set "ARGS=!ARGS! %1"
shift
goto parse_args

:run
:: Execute the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%PVM_DIR%pvm.ps1" %ARGS%
exit /b %errorlevel%

