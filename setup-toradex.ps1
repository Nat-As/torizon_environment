#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sets up the complete Toradex build environment in VS Code on Windows 11
.DESCRIPTION
    This script installs and configures:
    - WSL2 with Ubuntu
    - Docker Desktop
    - VS Code with required extensions
    - Toradex development tools
.NOTES
    Requires Administrator privileges
    System may require multiple restarts
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Step($message) {
    Write-ColorOutput Cyan "`n==> $message"
}

function Write-Success($message) {
    Write-ColorOutput Green "✓ $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "⚠ $message"
}

function Write-ErrorMsg($message) {
    Write-ColorOutput Red "✗ $message"
}

# Check Windows version
function Test-WindowsVersion {
    Write-Step "Checking Windows version..."
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 19041) {
        Write-ErrorMsg "Windows 10 build 19041 or Windows 11 is required for WSL2"
        exit 1
    }
    Write-Success "Windows version is compatible (Build: $build)"
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install WSL2
function Install-WSL2 {
    Write-Step "Setting up WSL2..."
    
    # Check if WSL is already installed
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "WSL is already installed"
    } else {
        Write-Output "Installing WSL2..."
        wsl --install --no-distribution
        Write-Warning "WSL installation requires a system restart"
        $restart = Read-Host "Restart now? (Y/N)"
        if ($restart -eq 'Y' -or $restart -eq 'y') {
            Restart-Computer
        } else {
            Write-Warning "Please restart manually and re-run this script"
            exit 0
        }
    }
    
    # Set WSL2 as default
    wsl --set-default-version 2
    Write-Success "WSL2 set as default version"
}

# Install Ubuntu on WSL2
function Install-Ubuntu {
    Write-Step "Installing Ubuntu on WSL2..."
    
    $distros = wsl --list --quiet
    if ($distros -match "Ubuntu") {
        Write-Success "Ubuntu is already installed"
        return
    }
    
    Write-Output "Installing Ubuntu..."
    wsl --install -d Ubuntu
    Write-Output "`nPlease complete Ubuntu setup (create username and password) in the window that opens."
    Write-Output "After setup is complete, close the Ubuntu window and press Enter here to continue..."
    Read-Host
    Write-Success "Ubuntu installation completed"
}

# Install Docker Desktop
function Install-Docker {
    Write-Step "Installing Docker Desktop..."
    
    # Check if Docker is already installed
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Success "Docker Desktop is already installed"
        return
    }
    
    Write-Output "Downloading Docker Desktop..."
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
    
    try {
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath -UseBasicParsing
        Write-Output "Installing Docker Desktop (this may take several minutes)..."
        Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet" -Wait
        Remove-Item $installerPath -Force
        Write-Success "Docker Desktop installed successfully"
        Write-Warning "Docker Desktop requires a restart or logout/login"
    } catch {
        Write-ErrorMsg "Failed to install Docker Desktop: $_"
        Write-Output "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
    }
}

# Install VS Code
function Install-VSCode {
    Write-Step "Installing Visual Studio Code..."
    
    $vscodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    $vscodePathSystem = "$env:ProgramFiles\Microsoft VS Code\Code.exe"
    
    if ((Test-Path $vscodePath) -or (Test-Path $vscodePathSystem)) {
        Write-Success "VS Code is already installed"
        return
    }
    
    Write-Output "Downloading VS Code..."
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $installerPath = "$env:TEMP\VSCodeSetup.exe"
    
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $installerPath -UseBasicParsing
        Write-Output "Installing VS Code..."
        Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT", "/MERGETASKS=!runcode" -Wait
        Remove-Item $installerPath -Force
        Write-Success "VS Code installed successfully"
    } catch {
        Write-ErrorMsg "Failed to install VS Code: $_"
        Write-Output "Please install VS Code manually from: https://code.visualstudio.com/"
    }
}

# Install VS Code extensions
function Install-VSCodeExtensions {
    Write-Step "Installing VS Code extensions..."
    
    $codePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
    if (-not (Test-Path $codePath)) {
        $codePath = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
    }
    
    if (-not (Test-Path $codePath)) {
        Write-Warning "VS Code command line tool not found. Please install extensions manually."
        return
    }
    
    $extensions = @(
        "ms-vscode-remote.remote-wsl",
        "ms-vscode-remote.remote-containers",
        "ms-azuretools.vscode-docker",
        "ms-vscode.cpptools",
        "ms-vscode.cpptools-extension-pack",
        "ms-python.python",
        "yoctoproject.yocto-bitbake"
    )
    
    foreach ($ext in $extensions) {
        Write-Output "Installing extension: $ext"
        & $codePath --install-extension $ext --force 2>&1 | Out-Null
    }
    
    Write-Success "VS Code extensions installed"
}

# Configure WSL for Toradex development
function Configure-WSLForToradex {
    Write-Step "Configuring WSL for Toradex development..."
    
    $wslConfig = @"
sudo apt-get update
sudo apt-get install -y git curl wget build-essential gawk diffstat unzip \
    texinfo gcc-multilib chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping libsdl1.2-dev xterm zstd liblz4-tool locales

# Install repo tool for Toradex BSP
sudo curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
sudo chmod a+x /usr/local/bin/repo

# Set up git (user should configure with their own details)
echo 'Please configure git with your details:'
echo 'git config --global user.name "Your Name"'
echo 'git config --global user.email "your.email@example.com"'

# Install Docker in WSL (for container-based builds)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker `$USER
rm get-docker.sh

echo 'WSL configuration complete. You may need to restart WSL for all changes to take effect.'
"@
    
    $configFile = "$env:TEMP\wsl_setup.sh"
    $wslConfig | Out-File -FilePath $configFile -Encoding UTF8
    
    Write-Output "Running configuration in WSL Ubuntu..."
    wsl -d Ubuntu bash -c "dos2unix 2>/dev/null || sed -i 's/\r$//' /mnt/c/Users/$env:USERNAME/AppData/Local/Temp/wsl_setup.sh && bash /mnt/c/Users/$env:USERNAME/AppData/Local/Temp/wsl_setup.sh"
    
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    Write-Success "WSL configured for Toradex development"
}

# Create workspace directory
function New-ToradexWorkspace {
    Write-Step "Creating Toradex workspace..."
    
    $workspaceDir = "$HOME\ToradexProjects"
    if (-not (Test-Path $workspaceDir)) {
        New-Item -ItemType Directory -Path $workspaceDir | Out-Null
        Write-Success "Workspace created at: $workspaceDir"
    } else {
        Write-Success "Workspace already exists at: $workspaceDir"
    }
    
    # Create a README with getting started info
    $readmeContent = @"
# Toradex Development Environment

## Getting Started

1. Start Docker Desktop
2. Open VS Code
3. Use the Remote - WSL extension to connect to Ubuntu
4. Clone your Toradex projects here

## Useful Commands

- Start WSL: ``wsl``
- Check WSL status: ``wsl --status``
- Stop WSL: ``wsl --shutdown``

## Resources

- Toradex Developer Center: https://developer.toradex.com/
- Toradex BSP Layers: https://git.toradex.com/
- Yocto Project: https://www.yoctoproject.org/

## Next Steps

1. Configure git in WSL:
   ```
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. Initialize a Toradex BSP workspace:
   ```
   mkdir -p ~/toradex-bsp
   cd ~/toradex-bsp
   repo init -u https://git.toradex.com/toradex-manifest.git -b kirkstone-6.x.y
   repo sync
   ```

3. Set up the build environment:
   ```
   . export
   ```

"@
    
    $readmeContent | Out-File -FilePath "$workspaceDir\README.md" -Encoding UTF8
}

# Main execution
function Main {
    Write-Output @"
╔════════════════════════════════════════════════════════════╗
║   Toradex Build Environment Setup for Windows 11          ║
║   This script will install:                               ║
║   - WSL2 with Ubuntu                                      ║
║   - Docker Desktop                                        ║
║   - VS Code with extensions                               ║
║   - Toradex development tools                             ║
╚════════════════════════════════════════════════════════════╝
"@
    
    if (-not (Test-Administrator)) {
        Write-ErrorMsg "This script must be run as Administrator"
        Write-Output "Right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }
    
    try {
        Test-WindowsVersion
        Install-WSL2
        Install-Ubuntu
        Install-Docker
        Install-VSCode
        Install-VSCodeExtensions
        Configure-WSLForToradex
        New-ToradexWorkspace
        
        Write-Output "`n"
        Write-ColorOutput Green @"
╔════════════════════════════════════════════════════════════╗
║   Setup Complete!                                          ║
╚════════════════════════════════════════════════════════════╝
"@
        Write-Output "`nNext steps:"
        Write-Output "1. Restart your computer if you haven't already"
        Write-Output "2. Start Docker Desktop"
        Write-Output "3. Open VS Code"
        Write-Output "4. Use Ctrl+Shift+P and select 'WSL: Connect to WSL'"
        Write-Output "5. Check the README.md in $HOME\ToradexProjects for more info"
        Write-Output "`nHappy developing!"
        
    } catch {
        Write-ErrorMsg "An error occurred: $_"
        exit 1
    }
}

# Run main function
Main
