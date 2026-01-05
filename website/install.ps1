<#
.SYNOPSIS
    pvm installer for Windows
.DESCRIPTION
    Installs pvm (Python Version Manager) on Windows systems.
    Downloads and sets up pvm in the user's home directory.
.NOTES
    Run this script in PowerShell with administrator privileges for best results.
    Usage: irm https://raw.githubusercontent.com/violettoolssite/pym/main/install.ps1 | iex
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallDir = (Join-Path $env:USERPROFILE ".pvm")
)

$ErrorActionPreference = "Stop"

# Configuration
$PVM_REPO = "https://github.com/violettoolssite/pym.git"
$PVM_RAW_BASE = "https://pvm-arc.pages.dev"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Pvm {
    Write-ColorOutput "`n==================================" "Cyan"
    Write-ColorOutput "  pvm - Python Version Manager" "Cyan"
    Write-ColorOutput "  Windows Installer" "Cyan"
    Write-ColorOutput "==================================`n" "Cyan"

    # Create installation directory
    Write-ColorOutput "Installing pvm to: $InstallDir" "Yellow"
    
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # Create subdirectories
    $versionsDir = Join-Path $InstallDir "versions"
    if (-not (Test-Path $versionsDir)) {
        New-Item -ItemType Directory -Path $versionsDir -Force | Out-Null
    }

    # Download pvm files
    Write-ColorOutput "Downloading pvm scripts..." "Yellow"
    
    $windowsDir = Join-Path $InstallDir "windows"
    if (-not (Test-Path $windowsDir)) {
        New-Item -ItemType Directory -Path $windowsDir -Force | Out-Null
    }

    try {
        # Download main PowerShell script
        $ps1Content = (Invoke-WebRequest -Uri "$PVM_RAW_BASE/windows/pvm.ps1" -UseBasicParsing).Content
        Set-Content -Path (Join-Path $windowsDir "pvm.ps1") -Value $ps1Content -Encoding UTF8

        # Download batch wrapper
        $cmdContent = (Invoke-WebRequest -Uri "$PVM_RAW_BASE/windows/pvm.cmd" -UseBasicParsing).Content
        Set-Content -Path (Join-Path $windowsDir "pvm.cmd") -Value $cmdContent -Encoding UTF8

        # Download elevate script
        $elevateContent = (Invoke-WebRequest -Uri "$PVM_RAW_BASE/windows/elevate.cmd" -UseBasicParsing).Content
        Set-Content -Path (Join-Path $windowsDir "elevate.cmd") -Value $elevateContent -Encoding UTF8
    }
    catch {
        Write-ColorOutput "Error downloading pvm scripts: $_" "Red"
        Write-ColorOutput "Trying to download from local files..." "Yellow"
        
        # If running from cloned repo, copy local files
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        if (Test-Path (Join-Path $scriptDir "windows/pvm.ps1")) {
            Copy-Item -Path (Join-Path $scriptDir "windows/*") -Destination $windowsDir -Force
        }
        else {
            throw "Failed to download pvm scripts and no local files found."
        }
    }

    # Create root pvm.cmd wrapper
    $rootCmdPath = Join-Path $InstallDir "pvm.cmd"
    $rootCmdContent = @"
@echo off
"%~dp0windows\pvm.cmd" %*
"@
    Set-Content -Path $rootCmdPath -Value $rootCmdContent -Encoding ASCII

    # Create default settings
    $settingsPath = Join-Path $InstallDir "settings.json"
    if (-not (Test-Path $settingsPath)) {
        $defaultSettings = @{
            mirror = "https://www.python.org/ftp/python"
        } | ConvertTo-Json
        Set-Content -Path $settingsPath -Value $defaultSettings -Encoding UTF8
    }

    # Add to PATH
    Write-ColorOutput "Configuring PATH..." "Yellow"
    
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pvmPath = $InstallDir
    $pvmPythonPath = Join-Path $InstallDir "python"
    $pvmPythonScriptsPath = Join-Path $pvmPythonPath "Scripts"

    $pathsToAdd = @($pvmPath, $pvmPythonPath, $pvmPythonScriptsPath)
    $pathModified = $false

    foreach ($pathToAdd in $pathsToAdd) {
        if ($userPath -notlike "*$pathToAdd*") {
            $userPath = "$pathToAdd;$userPath"
            $pathModified = $true
        }
    }

    if ($pathModified) {
        try {
            [Environment]::SetEnvironmentVariable("PATH", $userPath, "User")
            Write-ColorOutput "PATH updated successfully." "Green"
        }
        catch {
            Write-ColorOutput "Warning: Could not update PATH automatically." "Yellow"
            Write-ColorOutput "Please add the following to your PATH manually:" "Yellow"
            foreach ($p in $pathsToAdd) {
                Write-ColorOutput "  $p" "Cyan"
            }
        }
    }
    else {
        Write-ColorOutput "PATH already configured." "Green"
    }

    # Create PowerShell profile integration (optional)
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Success message
    Write-ColorOutput "`n==================================" "Green"
    Write-ColorOutput "  pvm installed successfully!" "Green"
    Write-ColorOutput "==================================`n" "Green"

    Write-ColorOutput "To start using pvm, open a new terminal and run:" "White"
    Write-ColorOutput "  pvm --help`n" "Cyan"

    Write-ColorOutput "Quick start:" "White"
    Write-ColorOutput "  pvm list available     # List available Python versions" "Cyan"
    Write-ColorOutput "  pvm install 3.12.4     # Install Python 3.12.4" "Cyan"
    Write-ColorOutput "  pvm use 3.12.4         # Switch to Python 3.12.4`n" "Cyan"

    Write-ColorOutput "Note: You may need to restart your terminal for PATH changes to take effect." "Yellow"
}

# Run installer
Install-Pvm

