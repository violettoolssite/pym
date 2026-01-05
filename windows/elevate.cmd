@echo off
:: elevate.cmd - Run a command with administrator privileges
:: Usage: elevate.cmd <command> [arguments]

if "%1"=="" (
    echo Usage: elevate.cmd ^<command^> [arguments]
    exit /b 1
)

:: Check if already running as admin
net session >nul 2>&1
if %errorlevel% == 0 (
    :: Already admin, just run the command
    %*
    exit /b %errorlevel%
)

:: Not admin, request elevation
echo Requesting administrator privileges...

:: Create a temporary VBScript to request elevation
set "TEMP_VBS=%TEMP%\pvm_elevate_%RANDOM%.vbs"

echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP_VBS%"
echo args = "" >> "%TEMP_VBS%"
echo For i = 1 to WScript.Arguments.Count - 1 >> "%TEMP_VBS%"
echo     args = args ^& " " ^& WScript.Arguments(i) >> "%TEMP_VBS%"
echo Next >> "%TEMP_VBS%"
echo UAC.ShellExecute WScript.Arguments(0), args, "", "runas", 1 >> "%TEMP_VBS%"

:: Run the VBScript
cscript //nologo "%TEMP_VBS%" %*

:: Cleanup
del "%TEMP_VBS%" >nul 2>&1

exit /b 0

