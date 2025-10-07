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
function Write-Step {
    param([string]$message)
    Write-Host "`n==> $message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$message)
    Write-Host "Success: $message" -ForegroundColor Green
}

function Write-Info {
    param([string]$message)
    Write-Host $message -ForegroundColor White
}

function Write-Warn {
    param([string]$message)
    Write-Host "Warning: $message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$message)
    Write-Host "Error: $message" -ForegroundColor Red
}

# Check Windows version
function Test-WindowsVersion {
    Write-Step "Checking Windows version..."
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 19041) {
        Write-Err "Windows 10 build 19041 or Windows 11 is required for WSL2"
        exit 1
    }
    Write-Success "Windows version is compatible (Build: $build)"
}

# Install WSL2
function Install-WSL2 {
    Write-Step "Setting up WSL2..."
    
    # Check if WSL is already installed
    try {
        $wslStatus = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "WSL is already installed"
        } else {
            throw "WSL not installed"
        }
    } catch {
        Write-Info "Installing WSL2..."
        wsl --install --no-distribution
        Write-Warn "WSL installation requires a system restart"
        $restart = Read-Host "Restart now? (Y/N)"
        if ($restart -eq 'Y' -or $restart -eq 'y') {
            Restart-Computer
        } else {
            Write-Warn "Please restart manually and re-run this script"
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
    
    Write-Info "Installing Ubuntu..."
    
    # Try the standard install first
    $installResult = wsl --install -d Ubuntu 2>&1
    
    # Check if it failed with certificate error
    if ($LASTEXITCODE -ne 0 -and $installResult -match "certificate|0x80072f06") {
        Write-Warn "Standard installation failed. Trying alternative method..."
        
        # Download Ubuntu appx directly
        $ubuntuUrl = "https://aka.ms/wslubuntu2204"
        $appxPath = Join-Path $env:TEMP "Ubuntu.appx"
        
        try {
            Write-Info "Downloading Ubuntu 22.04..."
            # Use TLS 1.2
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $ubuntuUrl -OutFile $appxPath -UseBasicParsing
            
            Write-Info "Installing Ubuntu from downloaded package..."
            Add-AppxPackage -Path $appxPath
            
            Remove-Item $appxPath -Force -ErrorAction SilentlyContinue
            Write-Success "Ubuntu installed via alternative method"
        } catch {
            Write-Err "Failed to install Ubuntu: $_"
            Write-Info "Please install Ubuntu manually from the Microsoft Store"
            Write-Info "Or download from: https://aka.ms/wslubuntu2204"
            return
        }
    }
    
    Write-Info "`nPlease complete Ubuntu setup (create username and password) in the window that opens."
    Write-Info "After setup is complete, close the Ubuntu window and press Enter here to continue..."
    
    # Launch Ubuntu for first-time setup
    Start-Process "ubuntu2204.exe" -Wait
    
    Read-Host "Press Enter after completing Ubuntu setup"
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
    
    Write-Info "Downloading Docker Desktop..."
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = Join-Path $env:TEMP "DockerDesktopInstaller.exe"
    
    try {
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "Installing Docker Desktop (this may take several minutes)..."
        Start-Process -FilePath $installerPath -ArgumentList "install","--quiet" -Wait
        Remove-Item $installerPath -Force
        Write-Success "Docker Desktop installed successfully"
        Write-Warn "Docker Desktop requires a restart or logout/login"
    } catch {
        Write-Err "Failed to install Docker Desktop: $_"
        Write-Info "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
    }
}

# Install VS Code
function Install-VSCode {
    Write-Step "Installing Visual Studio Code..."
    
    $vscodePath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\Code.exe"
    $vscodePathSystem = Join-Path $env:ProgramFiles "Microsoft VS Code\Code.exe"
    
    if ((Test-Path $vscodePath) -or (Test-Path $vscodePathSystem)) {
        Write-Success "VS Code is already installed"
        return
    }
    
    Write-Info "Downloading VS Code..."
    $vscodeUrl = "https://code.visualstudio.com/sha/download?build=stable" + "&os=win32-x64-user"
    $installerPath = Join-Path $env:TEMP "VSCodeSetup.exe"
    
    try {
        Invoke-WebRequest -Uri $vscodeUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "Installing VS Code..."
        Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT","/MERGETASKS=!runcode" -Wait
        Remove-Item $installerPath -Force
        Write-Success "VS Code installed successfully"
    } catch {
        Write-Err "Failed to install VS Code: $_"
        Write-Info "Please install VS Code manually from: https://code.visualstudio.com/"
    }
}

# Install VS Code extensions
function Install-VSCodeExtensions {
    Write-Step "Installing VS Code extensions..."
    
    $codePath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
    if (-not (Test-Path $codePath)) {
        $codePath = Join-Path $env:ProgramFiles "Microsoft VS Code\bin\code.cmd"
    }
    
    if (-not (Test-Path $codePath)) {
        Write-Warn "VS Code command line tool not found. Please install extensions manually."
        return
    }
    
    $extensions = @(
        "ms-vscode-remote.remote-wsl"
        "ms-vscode-remote.remote-containers"
        "ms-azuretools.vscode-docker"
        "ms-vscode.cpptools"
        "ms-vscode.cpptools-extension-pack"
        "ms-python.python"
        "toradex.toradex-torizon-toolkit"
    )
    
    $failed = @()
    foreach ($ext in $extensions) {
        Write-Info "Installing extension: $ext"
        try {
            $result = & $codePath --install-extension $ext --force 2>&1
            if ($LASTEXITCODE -ne 0) {
                $failed += $ext
                Write-Warn "Failed to install: $ext"
            }
        } catch {
            $failed += $ext
            Write-Warn "Failed to install: $ext"
        }
    }
    
    if ($failed.Count -gt 0) {
        Write-Warn "Some extensions failed to install: $($failed -join ', ')"
        Write-Info "You can install these manually later from VS Code"
    }
    
    Write-Success "VS Code extensions installation completed"
}

# Configure WSL for Toradex development
function Configure-WSLForToradex {
    Write-Step "Configuring WSL for Toradex development..."
    
    $bashScript = @'
#!/bin/bash
set -e

echo "Updating package lists..."
sudo apt-get update

echo "Installing development tools..."
sudo apt-get install -y git curl wget build-essential gawk diffstat unzip \
    texinfo gcc-multilib chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping libsdl1.2-dev xterm zstd liblz4-tool locales

echo "Installing repo tool for Toradex BSP..."
sudo curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
sudo chmod a+x /usr/local/bin/repo

echo "Installing Docker in WSL..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

echo ""
echo "WSL configuration complete!"
echo ""
echo "IMPORTANT: Configure git with your details:"
echo "  git config --global user.name \"Your Name\""
echo "  git config --global user.email \"your.email@example.com\""
echo ""
echo "You may need to restart WSL for all changes to take effect."
'@
    
    $scriptPath = Join-Path $env:TEMP "wsl_setup.sh"
    $bashScript | Out-File -FilePath $scriptPath -Encoding UTF8 -NoNewline
    
    Write-Info "Running configuration in WSL Ubuntu..."
    $wslPath = $scriptPath -replace '\\', '/' -replace 'C:', '/mnt/c' -replace 'D:', '/mnt/d' -replace 'E:', '/mnt/e'
    
    try {
        wsl -d Ubuntu bash -c "sed -i 's/\r$//' '$wslPath' && bash '$wslPath'"
        Write-Success "WSL configured for Toradex development"
    } catch {
        Write-Warn "WSL configuration encountered an issue. You may need to run the configuration manually."
    } finally {
        Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

# Create workspace directory
function New-ToradexWorkspace {
    Write-Step "Creating Toradex workspace..."
    
    $workspaceDir = Join-Path $HOME "ToradexProjects"
    if (-not (Test-Path $workspaceDir)) {
        New-Item -ItemType Directory -Path $workspaceDir | Out-Null
        Write-Success "Workspace created at: $workspaceDir"
    } else {
        Write-Success "Workspace already exists at: $workspaceDir"
    }
    
    # Create a README with getting started info
    $readmeLines = @(
        "# Toradex Development Environment"
        ""
        "## Getting Started"
        ""
        "1. Start Docker Desktop"
        "2. Open VS Code"
        "3. Use the Remote WSL extension to connect to Ubuntu"
        "4. Clone your Toradex projects here"
        ""
        "## Useful Commands"
        ""
        "- Start WSL: ``wsl``"
        "- Check WSL status: ``wsl --status``"
        "- Stop WSL: ``wsl --shutdown``"
        ""
        "## Resources"
        ""
        "- Toradex Developer Center: https://developer.toradex.com/"
        "- Toradex BSP Layers: https://git.toradex.com/"
        "- Yocto Project: https://www.yoctoproject.org/"
        ""
        "## Next Steps"
        ""
        "### 1. Configure git in WSL"
        ""
        "``````bash"
        "git config --global user.name `"Your Name`""
        "git config --global user.email `"your.email@example.com`""
        "``````"
        ""
        "### 2. Initialize a Toradex BSP workspace"
        ""
        "``````bash"
        "mkdir -p ~/toradex-bsp"
        "cd ~/toradex-bsp"
        "repo init -u https://git.toradex.com/toradex-manifest.git -b kirkstone-6.x.y"
        "repo sync"
        "``````"
        ""
        "### 3. Set up the build environment"
        ""
        "``````bash"
        ". export"
        "``````"
        ""
    )
    
    $readmeContent = $readmeLines -join "`r`n"
    $readmePath = Join-Path $workspaceDir "README.md"
    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   Toradex Build Environment Setup for Windows 11" -ForegroundColor Cyan
    Write-Host "   This script will install:" -ForegroundColor Cyan
    Write-Host "   - WSL2 with Ubuntu" -ForegroundColor Cyan
    Write-Host "   - Docker Desktop" -ForegroundColor Cyan
    Write-Host "   - VS Code with extensions" -ForegroundColor Cyan
    Write-Host "   - Toradex development tools" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if running as administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Err "This script must be run as Administrator"
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
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
        
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "   Setup Complete!" -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Restart your computer if you have not already" -ForegroundColor White
        Write-Host "2. Start Docker Desktop" -ForegroundColor White
        Write-Host "3. Open VS Code" -ForegroundColor White
        Write-Host "4. Use Ctrl+Shift+P and select 'WSL: Connect to WSL'" -ForegroundColor White
        Write-Host "5. Check the README.md in $HOME\ToradexProjects for more info" -ForegroundColor White
        Write-Host ""
        Write-Host "Happy developing!" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Err "An error occurred: $_"
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        exit 1
    }
}

# Run main function
Main
