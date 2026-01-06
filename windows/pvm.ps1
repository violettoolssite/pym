<#
.SYNOPSIS
    pvm - Python Version Manager for Windows
.DESCRIPTION
    A simple Python version manager that allows you to install, switch between,
    and manage multiple Python versions on Windows.
.NOTES
    Author: pvm contributors
    License: Apache 2.0
#>

# Set console output encoding to UTF-8 to prevent encoding issues
if ($PSVersionTable.PSVersion.Major -ge 6) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,
    
    [Parameter(Position = 1)]
    [string]$Version,
    
    [Parameter()]
    [ValidateSet('32', '64', 'arm64')]
    [string]$Arch = '',
    
    [Parameter()]
    [switch]$Help
)

# Configuration
$script:PVM_VERSION = "1.0.0"
$script:PVM_HOME = Join-Path $env:USERPROFILE ".pvm"
$script:PVM_VERSIONS_DIR = Join-Path $script:PVM_HOME "versions"
$script:PVM_CURRENT_FILE = Join-Path $script:PVM_HOME "current"
$script:PVM_SETTINGS_FILE = Join-Path $script:PVM_HOME "settings.json"
$script:PVM_SYMLINK = Join-Path $script:PVM_HOME "python"

# Default Python download mirror
$script:DEFAULT_MIRROR = "https://www.python.org/ftp/python"

# Preset mirrors for Python download
$script:MIRRORS = @{
    "default"   = "https://www.python.org/ftp/python"
    "tsinghua"  = "https://mirrors.tuna.tsinghua.edu.cn/python"
    "qinghua"   = "https://mirrors.tuna.tsinghua.edu.cn/python"
    "huawei"    = "https://mirrors.huaweicloud.com/python"
    "npmmirror" = "https://registry.npmmirror.com/-/binary/python"
    "aliyun"    = "https://mirrors.aliyun.com/python"
}

# Preset mirrors for pip
$script:PIP_MIRRORS = @{
    "default"   = "https://pypi.org/simple"
    "tsinghua"  = "https://pypi.tuna.tsinghua.edu.cn/simple"
    "qinghua"   = "https://pypi.tuna.tsinghua.edu.cn/simple"
    "huawei"    = "https://repo.huaweicloud.com/repository/pypi/simple"
    "npmmirror" = "https://registry.npmmirror.com/-/binary/pypi/simple"
    "aliyun"    = "https://mirrors.aliyun.com/pypi/simple"
}

# Available Python versions (commonly used stable versions)
$script:AVAILABLE_VERSIONS = @(
    "3.13.1", "3.13.0",
    "3.12.8", "3.12.7", "3.12.6", "3.12.5", "3.12.4", "3.12.3", "3.12.2", "3.12.1", "3.12.0",
    "3.11.11", "3.11.10", "3.11.9", "3.11.8", "3.11.7", "3.11.6", "3.11.5", "3.11.4", "3.11.3", "3.11.2", "3.11.1", "3.11.0",
    "3.10.16", "3.10.15", "3.10.14", "3.10.13", "3.10.12", "3.10.11", "3.10.10", "3.10.9", "3.10.8", "3.10.7", "3.10.6", "3.10.5", "3.10.4", "3.10.3", "3.10.2", "3.10.1", "3.10.0",
    "3.9.21", "3.9.20", "3.9.19", "3.9.18", "3.9.17", "3.9.16", "3.9.15", "3.9.14", "3.9.13", "3.9.12", "3.9.11", "3.9.10", "3.9.9", "3.9.8", "3.9.7", "3.9.6", "3.9.5", "3.9.4", "3.9.3", "3.9.2", "3.9.1", "3.9.0",
    "3.8.20", "3.8.19", "3.8.18", "3.8.17", "3.8.16", "3.8.15", "3.8.14", "3.8.13", "3.8.12", "3.8.11", "3.8.10", "3.8.9", "3.8.8", "3.8.7", "3.8.6", "3.8.5", "3.8.4", "3.8.3", "3.8.2", "3.8.1", "3.8.0"
)

function Initialize-Pvm {
    <#
    .SYNOPSIS
        Initialize pvm directories and configuration
    #>
    if (-not (Test-Path $script:PVM_HOME)) {
        New-Item -ItemType Directory -Path $script:PVM_HOME -Force | Out-Null
    }
    if (-not (Test-Path $script:PVM_VERSIONS_DIR)) {
        New-Item -ItemType Directory -Path $script:PVM_VERSIONS_DIR -Force | Out-Null
    }
    if (-not (Test-Path $script:PVM_SETTINGS_FILE)) {
        $defaultSettings = @{
            mirror = $script:DEFAULT_MIRROR
        } | ConvertTo-Json
        Set-Content -Path $script:PVM_SETTINGS_FILE -Value $defaultSettings -Encoding UTF8
    }
}

function Get-PvmSettings {
    <#
    .SYNOPSIS
        Get pvm settings from configuration file
    #>
    if (Test-Path $script:PVM_SETTINGS_FILE) {
        try {
            return Get-Content $script:PVM_SETTINGS_FILE -Raw | ConvertFrom-Json
        }
        catch {
            return @{ mirror = $script:DEFAULT_MIRROR }
        }
    }
    return @{ mirror = $script:DEFAULT_MIRROR }
}

function Get-Mirror {
    <#
    .SYNOPSIS
        Get the configured mirror URL
    #>
    $settings = Get-PvmSettings
    if ($settings.mirror) {
        return $settings.mirror
    }
    return $script:DEFAULT_MIRROR
}

function Show-Help {
    <#
    .SYNOPSIS
        Display help information
    #>
    $helpText = @"

pvm - Python Version Manager v$($script:PVM_VERSION)

Usage:
    pvm <command> [options]

Commands:
    list                    List installed Python versions
    list available          List available Python versions for download
    install <version>       Install a specific Python version
    uninstall <version>     Uninstall a specific Python version
    use <version>           Switch to a specific Python version
    current                 Show the currently active Python version
    which                   Show the path to the current Python executable
    config [mirror]         Configure mirror (show current if no argument)
    arch                    Show detected system architecture
    --help, -h              Show this help message
    --version, -v           Show pvm version

Options:
    --arch <32|64|arm64>    Architecture for install (auto-detect if not specified)

Mirror Presets:
    tsinghua, qinghua       Tsinghua University (China)
    huawei                  Huawei Cloud (China)
    npmmirror               npmmirror (China)
    aliyun                  Aliyun (China)
    default                 python.org (Official)

Examples:
    pvm install 3.12.4           Install Python 3.12.4
    pvm use 3.12.4               Switch to Python 3.12.4
    pvm config tsinghua          Use Tsinghua mirror
    pvm config huawei            Use Huawei Cloud mirror
    pvm config default           Use official python.org

Configuration:
    pvm stores data in: $($script:PVM_HOME)

"@
    Write-Host $helpText
}

function Show-Version {
    Write-Host "pvm version $($script:PVM_VERSION)"
}

function Get-InstalledVersions {
    <#
    .SYNOPSIS
        Get list of installed Python versions
    #>
    $versions = @()
    if (Test-Path $script:PVM_VERSIONS_DIR) {
        $dirs = Get-ChildItem -Path $script:PVM_VERSIONS_DIR -Directory
        foreach ($dir in $dirs) {
            $versions += $dir.Name
        }
    }
    return $versions | Sort-Object { [version]($_ -replace '-.*', '') } -Descending
}

function Get-CurrentVersion {
    <#
    .SYNOPSIS
        Get the currently active Python version
    #>
    if (Test-Path $script:PVM_CURRENT_FILE) {
        return (Get-Content $script:PVM_CURRENT_FILE -Raw).Trim()
    }
    return $null
}

function Show-InstalledVersions {
    <#
    .SYNOPSIS
        Display installed Python versions
    #>
    $versions = Get-InstalledVersions
    $current = Get-CurrentVersion
    
    if ($versions.Count -eq 0) {
        Write-Host "No Python versions installed." -ForegroundColor Yellow
        Write-Host "Use 'pvm install <version>' to install a version."
        Write-Host "Use 'pvm list available' to see available versions."
        return
    }
    
    Write-Host "`nInstalled Python versions:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($v in $versions) {
        if ($v -eq $current) {
            Write-Host "  * $v (current)" -ForegroundColor Green
        }
        else {
            Write-Host "    $v"
        }
    }
    Write-Host ""
}

function Show-AvailableVersions {
    <#
    .SYNOPSIS
        Display available Python versions for download
    #>
    $installed = Get-InstalledVersions
    
    Write-Host "`nAvailable Python versions:" -ForegroundColor Cyan
    Write-Host ""
    
    $grouped = $script:AVAILABLE_VERSIONS | Group-Object { $_.Split('.')[0..1] -join '.' }
    
    foreach ($group in $grouped | Sort-Object { [version]$_.Name } -Descending) {
        Write-Host "  $($group.Name).x:" -ForegroundColor Yellow
        $line = "    "
        foreach ($v in $group.Group) {
            $isInstalled = $installed -contains $v
            if ($isInstalled) {
                $line += "[$v] "
            }
            else {
                $line += "$v "
            }
        }
        Write-Host $line
    }
    Write-Host ""
    Write-Host "  [version] = already installed" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-SystemArchitecture {
    <#
    .SYNOPSIS
        Detect system architecture
    #>
    $arch = $env:PROCESSOR_ARCHITECTURE
    switch ($arch) {
        'AMD64' { return '64' }
        'x86' { return '32' }
        'ARM64' { return 'arm64' }
        default { return '64' }
    }
}

function Install-PythonVersion {
    <#
    .SYNOPSIS
        Install a specific Python version
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,
        [string]$Architecture = ''
    )
    
    # Auto-detect architecture if not specified
    if ([string]::IsNullOrEmpty($Architecture)) {
        $Architecture = Get-SystemArchitecture
        Write-Host "Detected architecture: $Architecture" -ForegroundColor DarkGray
    }
    
    # Validate version format
    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-Host "Error: Invalid version format. Use format like '3.12.4'" -ForegroundColor Red
        return $false
    }
    
    # Check if already installed
    $versionDir = Join-Path $script:PVM_VERSIONS_DIR $Version
    if (Test-Path $versionDir) {
        Write-Host "Python $Version is already installed." -ForegroundColor Yellow
        Write-Host "Use 'pvm use $Version' to switch to it."
        return $true
    }
    
    # Determine architecture suffix
    $archSuffix = switch ($Architecture) {
        '32' { 'win32' }
        'arm64' { 'arm64' }
        default { 'amd64' }
    }
    
    # Build download URL
    $mirror = Get-Mirror
    $zipName = "python-$Version-embed-$archSuffix.zip"
    $downloadUrl = "$mirror/$Version/$zipName"
    
    $archDisplay = if ($Architecture -eq 'arm64') { 'ARM64' } else { "$Architecture-bit" }
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  Installing Python $Version ($archDisplay)" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Mirror:       $mirror" -ForegroundColor DarkGray
    Write-Host "  Package:      $zipName" -ForegroundColor DarkGray
    Write-Host "  Install to:   $versionDir" -ForegroundColor DarkGray
    Write-Host ""
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "pvm-install-$Version"
    $zipPath = Join-Path $tempDir $zipName
    
    try {
        # Create temp directory
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        # Download Python embeddable package
        Write-Host "[1/3] Downloading Python $Version..." -ForegroundColor Yellow
        
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        }
        catch {
            Write-Host "Error: Failed to download Python $Version" -ForegroundColor Red
            Write-Host "URL: $downloadUrl" -ForegroundColor Red
            Write-Host "This version may not be available for $Architecture-bit architecture." -ForegroundColor Yellow
            return $false
        }
        $ProgressPreference = 'Continue'
        
        Write-Host "      Download complete!" -ForegroundColor Green
        
        # Extract
        Write-Host "[2/3] Extracting files..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $versionDir -Force
        
        # Enable pip by modifying python*._pth file
        $pthFiles = Get-ChildItem -Path $versionDir -Filter "python*._pth"
        foreach ($pthFile in $pthFiles) {
            $content = Get-Content $pthFile.FullName
            $newContent = $content -replace '#import site', 'import site'
            Set-Content -Path $pthFile.FullName -Value $newContent
        }
        
        Write-Host "      Extraction complete!" -ForegroundColor Green
        
        # Download get-pip.py and install pip
        Write-Host "[3/3] Installing pip..." -ForegroundColor Yellow
        $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
        $getPipPath = Join-Path $versionDir "get-pip.py"
        
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath -UseBasicParsing
            $ProgressPreference = 'Continue'
            
            $pythonExe = Join-Path $versionDir "python.exe"
            & $pythonExe $getPipPath --no-warn-script-location 2>&1 | Out-Null
            Remove-Item -Path $getPipPath -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Warning: Could not install pip. You may need to install it manually." -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host "  Python $Version installed successfully!" -ForegroundColor Green
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Location: $versionDir" -ForegroundColor White
        Write-Host ""
        Write-Host "  Next steps:" -ForegroundColor Yellow
        Write-Host "    pvm use $Version        # Switch to this version" -ForegroundColor Cyan
        Write-Host "    python --version        # Verify installation" -ForegroundColor Cyan
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "Error: Installation failed - $_" -ForegroundColor Red
        if (Test-Path $versionDir) {
            Remove-Item -Path $versionDir -Recurse -Force
        }
        return $false
    }
    finally {
        # Cleanup temp directory
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Uninstall-PythonVersion {
    <#
    .SYNOPSIS
        Uninstall a specific Python version
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    $versionDir = Join-Path $script:PVM_VERSIONS_DIR $Version
    
    if (-not (Test-Path $versionDir)) {
        Write-Host "Error: Python $Version is not installed." -ForegroundColor Red
        return $false
    }
    
    $current = Get-CurrentVersion
    if ($Version -eq $current) {
        Write-Host "Warning: Uninstalling the currently active version." -ForegroundColor Yellow
        # Remove current marker
        if (Test-Path $script:PVM_CURRENT_FILE) {
            Remove-Item -Path $script:PVM_CURRENT_FILE -Force
        }
        # Remove symlink
        if (Test-Path $script:PVM_SYMLINK) {
            Remove-Item -Path $script:PVM_SYMLINK -Force -Recurse
        }
    }
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  Uninstalling Python $Version" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Location: $versionDir" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Removing files..." -ForegroundColor Yellow
    
    try {
        Remove-Item -Path $versionDir -Recurse -Force
        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host "  Python $Version uninstalled successfully!" -ForegroundColor Green
        Write-Host "=============================================" -ForegroundColor Green
        Write-Host ""
        
        # Show remaining versions
        $remaining = Get-InstalledVersions
        if ($remaining.Count -gt 0) {
            Write-Host "  Remaining installed versions:" -ForegroundColor White
            foreach ($v in $remaining) {
                Write-Host "    - $v" -ForegroundColor Cyan
            }
            Write-Host ""
        }
        else {
            Write-Host "  No Python versions remaining." -ForegroundColor Yellow
            Write-Host "  Use 'pvm install <version>' to install a new version." -ForegroundColor White
            Write-Host ""
        }
        
        return $true
    }
    catch {
        Write-Host "Error: Failed to uninstall - $_" -ForegroundColor Red
        return $false
    }
}

function Use-PythonVersion {
    <#
    .SYNOPSIS
        Switch to a specific Python version
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    $versionDir = Join-Path $script:PVM_VERSIONS_DIR $Version
    
    if (-not (Test-Path $versionDir)) {
        Write-Host "Error: Python $Version is not installed." -ForegroundColor Red
        Write-Host "Use 'pvm install $Version' to install it first."
        return $false
    }
    
    # Update current version file
    Set-Content -Path $script:PVM_CURRENT_FILE -Value $Version -NoNewline
    
    # Create/update symlink
    if (Test-Path $script:PVM_SYMLINK) {
        Remove-Item -Path $script:PVM_SYMLINK -Force -Recurse
    }
    
    # Try to create symlink (requires admin or developer mode)
    try {
        New-Item -ItemType Junction -Path $script:PVM_SYMLINK -Target $versionDir -Force | Out-Null
    }
    catch {
        # Fallback: copy files (less efficient but works without admin)
        Copy-Item -Path $versionDir -Destination $script:PVM_SYMLINK -Recurse -Force
    }
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  Switched to Python $Version" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    
    # Show Python version
    $pythonExe = Join-Path $script:PVM_SYMLINK "python.exe"
    if (Test-Path $pythonExe) {
        $versionOutput = & $pythonExe --version 2>&1
        Write-Host "  Python:  $versionOutput" -ForegroundColor White
        
        # Try to get pip version
        $pipExe = Join-Path $script:PVM_SYMLINK "Scripts\pip.exe"
        if (Test-Path $pipExe) {
            try {
                $pipVersion = & $pipExe --version 2>&1
                $pipVersion = $pipVersion -replace ' from.*', ''
                Write-Host "  pip:     $pipVersion" -ForegroundColor White
            }
            catch { }
        }
        
        Write-Host ""
        Write-Host "  Path:    $pythonExe" -ForegroundColor DarkGray
    }
    
    # Check if pvm\python is in PATH
    $pvmPythonPath = $script:PVM_SYMLINK
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -notlike "*$pvmPythonPath*") {
        Write-Host ""
        Write-Host "  Warning: pvm Python path not in PATH" -ForegroundColor Yellow
        Write-Host "  Add these paths to use pvm-managed Python:" -ForegroundColor Yellow
        Write-Host "    $pvmPythonPath" -ForegroundColor Cyan
        Write-Host "    $pvmPythonPath\Scripts" -ForegroundColor Cyan
    }
    
    Write-Host ""
    return $true
}

function Show-CurrentVersion {
    <#
    .SYNOPSIS
        Show the currently active Python version
    #>
    $current = Get-CurrentVersion
    
    if ($null -eq $current -or $current -eq '') {
        Write-Host ""
        Write-Host "  No Python version is currently active." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  To get started:" -ForegroundColor White
        Write-Host "    pvm list available    # See available versions" -ForegroundColor Cyan
        Write-Host "    pvm install 3.12.4    # Install a version" -ForegroundColor Cyan
        Write-Host "    pvm use 3.12.4        # Activate it" -ForegroundColor Cyan
        Write-Host ""
        return
    }
    
    Write-Host ""
    Write-Host "  Current version: $current" -ForegroundColor Green
    
    $pythonExe = Join-Path $script:PVM_SYMLINK "python.exe"
    if (Test-Path $pythonExe) {
        $versionOutput = & $pythonExe --version 2>&1
        Write-Host "  Python output:   $versionOutput" -ForegroundColor White
        Write-Host "  Path:            $pythonExe" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-WhichPython {
    <#
    .SYNOPSIS
        Show the path to the current Python executable
    #>
    $current = Get-CurrentVersion
    
    if ($null -eq $current -or $current -eq '') {
        Write-Host ""
        Write-Host "  No Python version is currently active." -ForegroundColor Yellow
        Write-Host "  Use 'pvm use <version>' to activate a version." -ForegroundColor White
        Write-Host ""
        return
    }
    
    $pythonExe = Join-Path $script:PVM_SYMLINK "python.exe"
    $pipExe = Join-Path $script:PVM_SYMLINK "Scripts\pip.exe"
    
    Write-Host ""
    Write-Host "  Current version: $current" -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path $pythonExe) {
        Write-Host "  python:  $pythonExe" -ForegroundColor White
    }
    else {
        Write-Host "  python:  (not found)" -ForegroundColor Red
    }
    
    if (Test-Path $pipExe) {
        Write-Host "  pip:     $pipExe" -ForegroundColor White
    }
    else {
        Write-Host "  pip:     (not found)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

function Set-PvmConfig {
    <#
    .SYNOPSIS
        Configure pvm settings (mirror)
    #>
    param(
        [string]$MirrorName
    )
    
    # If no argument, show current config
    if ([string]::IsNullOrEmpty($MirrorName)) {
        Show-PvmConfig
        return
    }
    
    # Check if it's a preset name
    $mirrorUrl = $null
    if ($script:MIRRORS.ContainsKey($MirrorName.ToLower())) {
        $mirrorUrl = $script:MIRRORS[$MirrorName.ToLower()]
        Write-Host "Using preset mirror: $MirrorName" -ForegroundColor Cyan
    }
    elseif ($MirrorName -match '^https?://') {
        # It's a custom URL
        $mirrorUrl = $MirrorName
        Write-Host "Using custom mirror URL" -ForegroundColor Cyan
    }
    else {
        Write-Host "Error: Unknown mirror '$MirrorName'" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available presets:" -ForegroundColor Yellow
        Write-Host "  tsinghua, qinghua   - Tsinghua University (https://mirrors.tuna.tsinghua.edu.cn/python)"
        Write-Host "  huawei              - Huawei Cloud (https://mirrors.huaweicloud.com/python)"
        Write-Host "  npmmirror           - npmmirror (https://registry.npmmirror.com/-/binary/python)"
        Write-Host "  aliyun              - Aliyun (https://mirrors.aliyun.com/python)"
        Write-Host "  default             - python.org (https://www.python.org/ftp/python)"
        Write-Host ""
        Write-Host "Or use a custom URL: pvm config https://your-mirror.com/python"
        return
    }
    
    # Save to settings
    $settings = @{
        mirror = $mirrorUrl
    }
    $settings | ConvertTo-Json | Set-Content -Path $script:PVM_SETTINGS_FILE -Encoding UTF8
    
    Write-Host "Python mirror configured: $mirrorUrl" -ForegroundColor Green
    
    # Configure pip mirror
    $pipMirrorUrl = $null
    if ($script:PIP_MIRRORS.ContainsKey($MirrorName.ToLower())) {
        $pipMirrorUrl = $script:PIP_MIRRORS[$MirrorName.ToLower()]
    }
    
    if ($pipMirrorUrl) {
        # Create pip config directory
        $pipConfigDir = Join-Path $env:APPDATA "pip"
        if (-not (Test-Path $pipConfigDir)) {
            New-Item -ItemType Directory -Path $pipConfigDir -Force | Out-Null
        }
        
        # Write pip.ini (without BOM)
        $pipConfigFile = Join-Path $pipConfigDir "pip.ini"
        $pipConfig = @"
[global]
index-url = $pipMirrorUrl
trusted-host = $([System.Uri]::new($pipMirrorUrl).Host)
"@
        [System.IO.File]::WriteAllBytes($pipConfigFile, [System.Text.Encoding]::UTF8.GetBytes($pipConfig))
        Write-Host "pip mirror configured: $pipMirrorUrl" -ForegroundColor Green
        Write-Host "pip config file: $pipConfigFile" -ForegroundColor DarkGray
    }
}

function Show-PvmConfig {
    <#
    .SYNOPSIS
        Show current pvm configuration
    #>
    $settings = Get-PvmSettings
    $mirror = if ($settings.mirror) { $settings.mirror } else { $script:DEFAULT_MIRROR }
    
    # Get pip config
    $pipConfigFile = Join-Path $env:APPDATA "pip\pip.ini"
    $pipMirror = "https://pypi.org/simple (default)"
    if (Test-Path $pipConfigFile) {
        $pipContent = Get-Content $pipConfigFile -Raw
        if ($pipContent -match 'index-url\s*=\s*(.+)') {
            $pipMirror = $matches[1].Trim()
        }
    }
    
    Write-Host ""
    Write-Host "pvm Configuration:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Python mirror: $mirror" -ForegroundColor White
    Write-Host "  pip mirror:    $pipMirror" -ForegroundColor White
    Write-Host ""
    Write-Host "  pvm config:  $($script:PVM_SETTINGS_FILE)" -ForegroundColor DarkGray
    Write-Host "  pip config:  $pipConfigFile" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Available presets (configures both Python and pip):" -ForegroundColor Yellow
    Write-Host "  pvm config tsinghua   - Tsinghua University"
    Write-Host "  pvm config huawei     - Huawei Cloud"
    Write-Host "  pvm config npmmirror  - npmmirror"
    Write-Host "  pvm config aliyun     - Aliyun"
    Write-Host "  pvm config default    - python.org / pypi.org (Official)"
    Write-Host ""
}

# Main execution
Initialize-Pvm

# Handle help flags
if ($Help -or $Command -eq '--help' -or $Command -eq '-h') {
    Show-Help
    exit 0
}

# Handle version flag
if ($Command -eq '--version' -or $Command -eq '-v') {
    Show-Version
    exit 0
}

# Handle commands
switch ($Command) {
    'list' {
        if ($Version -eq 'available') {
            Show-AvailableVersions
        }
        else {
            Show-InstalledVersions
        }
    }
    'install' {
        if ([string]::IsNullOrEmpty($Version)) {
            Write-Host "Error: Please specify a version to install." -ForegroundColor Red
            Write-Host "Usage: pvm install <version>"
            Write-Host "Example: pvm install 3.12.4"
            exit 1
        }
        $result = Install-PythonVersion -Version $Version -Architecture $Arch
        if (-not $result) { exit 1 }
    }
    'uninstall' {
        if ([string]::IsNullOrEmpty($Version)) {
            Write-Host "Error: Please specify a version to uninstall." -ForegroundColor Red
            Write-Host "Usage: pvm uninstall <version>"
            exit 1
        }
        $result = Uninstall-PythonVersion -Version $Version
        if (-not $result) { exit 1 }
    }
    'use' {
        if ([string]::IsNullOrEmpty($Version)) {
            Write-Host "Error: Please specify a version to use." -ForegroundColor Red
            Write-Host "Usage: pvm use <version>"
            exit 1
        }
        $result = Use-PythonVersion -Version $Version
        if (-not $result) { exit 1 }
    }
    'current' {
        Show-CurrentVersion
    }
    'which' {
        Show-WhichPython
    }
    'config' {
        Set-PvmConfig -MirrorName $Version
    }
    'arch' {
        $arch = Get-SystemArchitecture
        $archDisplay = switch ($arch) {
            '64' { 'x86_64 (64-bit)' }
            '32' { 'x86 (32-bit)' }
            'arm64' { 'ARM64' }
        }
        Write-Host ""
        Write-Host "Detected Platform:" -ForegroundColor Cyan
        Write-Host "  OS: Windows"
        Write-Host "  Architecture: $archDisplay"
        Write-Host ""
    }
    'platform' {
        $arch = Get-SystemArchitecture
        $archDisplay = switch ($arch) {
            '64' { 'x86_64 (64-bit)' }
            '32' { 'x86 (32-bit)' }
            'arm64' { 'ARM64' }
        }
        Write-Host ""
        Write-Host "Detected Platform:" -ForegroundColor Cyan
        Write-Host "  OS: Windows"
        Write-Host "  Architecture: $archDisplay"
        Write-Host ""
    }
    default {
        if ([string]::IsNullOrEmpty($Command)) {
            Show-Help
        }
        else {
            Write-Host "Error: Unknown command '$Command'" -ForegroundColor Red
            Write-Host "Use 'pvm --help' for usage information."
            exit 1
        }
    }
}

