# Torizon Development Environment Setup

Automated setup scripts for configuring your development environment for Torizon OS development with Visual Studio Code.

## Overview

This repository contains automated setup scripts for both native Ubuntu and Windows 11 environments, installing and configuring all necessary tools and dependencies required for developing applications on Torizon OS using VS Code.

## Platform Support

- **Ubuntu 20.04+** - Native Linux development (bash script)
- **Windows 11** - WSL2-based development (PowerShell script)

## What Gets Installed

The scripts install and configure the following:

### Core Tools
- **Docker Engine/Desktop** - Container runtime for Torizon development
- **Docker Compose** - Multi-container application management
- **Visual Studio Code** - Primary IDE for Torizon development
- **WSL2 with Ubuntu** (Windows only) - Linux environment on Windows

### VS Code Extensions
- Toradex Torizon Toolkit - Official Torizon development extension
- Docker Extension - Container management
- C/C++ Tools - Native code development
- CMake Tools - Build system support
- Remote WSL (Windows only) - Seamless WSL integration

### Development Tools
- Git - Version control
- Python 3 & pip - Scripting and package management
- CMake & Ninja - Build systems
- GDB & GDB-multiarch - Debugging tools
- Device Tree Compiler - DTB/DTS handling
- Build essentials - Compilers and build tools

### Torizon-Specific Tools
- **torizoncore-builder** - CLI tool for customizing TorizonCore OS images

## Prerequisites

### For Ubuntu
- **Operating System**: Ubuntu 20.04 LTS or later (tested on Ubuntu 22.04 LTS)
- **Architecture**: x86_64 (amd64)
- **User Permissions**: Non-root user with sudo privileges
- **Internet Connection**: Required for downloading packages

### For Windows 11
- **Operating System**: Windows 11 (or Windows 10 build 19041+)
- **User Permissions**: Administrator privileges
- **Internet Connection**: Required for downloading packages
- **System Requirements**: Virtualization enabled in BIOS

## Installation

### Ubuntu Setup

#### Quick Start

```bash
# Clone the repository
git clone https://github.com/Nat-As/torizon_environment.git

# Navigate to the directory
cd torizon_environment

# Make the script executable
chmod +x setup_torizon.sh

# Run the setup script
./setup_torizon.sh
```

#### Step-by-Step Guide

1. **Clone or Download**
   ```bash
   git clone https://github.com/Nat-As/torizon_environment.git
   cd torizon_environment
   ```

2. **Review the Script** (Optional but recommended)
   ```bash
   cat setup_torizon.sh
   ```

3. **Make Executable**
   ```bash
   chmod +x setup_torizon.sh
   ```

4. **Run the Script**
   ```bash
   ./setup_torizon.sh
   ```
   
   The script will prompt for your sudo password when needed.

5. **Log Out and Back In**
   
   After the script completes, you **must** log out and log back in for Docker group permissions to take effect.
   
   Alternatively, run:
   ```bash
   newgrp docker
   ```

### Windows 11 Setup

#### Quick Start

```powershell
# Clone the repository
git clone https://github.com/Nat-As/torizon_environment.git

# Navigate to the directory
cd torizon_environment

# Run PowerShell as Administrator (Right-click > Run as Administrator)
# Then execute the script
.\setup_torizon_windows.ps1
```

> [!NOTE]
> If you receive an error that the .ps1 file is not digitally signed, you may need to right-click on the script file, select Properties, and check the "Unblock" box at the bottom, then click Apply.

#### Step-by-Step Guide

1. **Clone or Download**
   ```powershell
   git clone https://github.com/Nat-As/torizon_environment.git
   cd torizon_environment
   ```

2. **Review the Script** (Optional but recommended)
   ```powershell
   Get-Content .\setup_torizon_windows.ps1
   ```

3. **Run as Administrator**
   - Right-click on PowerShell
   - Select "Run as Administrator"
   - Navigate to the script directory

4. **Execute the Script**
   ```powershell
   .\setup_torizon_windows.ps1
   ```
   
   The script will guide you through the installation process.
> [!NOTE]
> If you receive an error that the .ps1 file is not digitally signed, you may need to right-click on the script file, select Properties, and check the "Unblock" box at the bottom, then click Apply.

5. **Restart Your Computer**
   
   After the script completes, restart your computer for all changes to take effect.

6. **Post-Restart**
   - Start Docker Desktop
   - Launch VS Code
   - Use `Ctrl+Shift+P` and select "WSL: Connect to WSL"

## Example Output
![screenshot](/src/installer.png)
## Post-Installation

### Verify Installation

#### Ubuntu

```bash
# Check Docker
docker --version
docker run hello-world

# Check Docker Compose
docker-compose --version

# Check VS Code
code --version

# Check Torizon Core Builder
torizoncore-builder --version

# Check other tools
cmake --version
gdb --version
python3 --version
```

#### Windows 11

```powershell
# Check WSL
wsl --status

# Inside WSL (run: wsl)
docker --version
docker run hello-world

# Check VS Code (in PowerShell)
code --version
```

### Configure Your First Project

1. **Launch VS Code**
   - Ubuntu: `code`
   - Windows: Launch from Start Menu, then connect to WSL (`Ctrl+Shift+P` → "WSL: Connect to WSL")

2. **Create or Open a Torizon Project**
   - Use `File > Open Folder` to open an existing project
   - Or create a new project using the Torizon extension

3. **Configure Target Device**
   - Open the Command Palette (`Ctrl+Shift+P`)
   - Search for "Torizon"
   - Follow the extension prompts to configure your target device

## Usage

### Starting Development

Once installed, you can:

1. **Create new Torizon applications** using VS Code templates
2. **Build containerized applications** for embedded Linux
3. **Debug remotely** on Torizon-powered devices
4. **Customize TorizonCore images** using torizoncore-builder

### Common Commands

#### Ubuntu

```bash
# Start VS Code
code

# Build a Docker image
docker build -t myapp .

# Run torizoncore-builder
torizoncore-builder --help

# Deploy to device (using Torizon extension)
# Use VS Code Command Palette: "Torizon: Deploy"
```

#### Windows 11

```powershell
# Start WSL
wsl

# Inside WSL, use the same commands as Ubuntu
docker build -t myapp .
torizoncore-builder --help

# Or use VS Code with WSL integration
code .
```

## Troubleshooting

### Ubuntu Issues

#### Docker Permission Denied

If you get "permission denied" errors when running Docker:

```bash
# Verify you're in the docker group
groups

# If 'docker' is not listed, log out and back in
# Or run:
newgrp docker
```

#### VS Code Extensions Not Installing

If VS Code extensions fail to install:

```bash
# Install manually
code --install-extension toradex.toradex-torizon-toolkit
code --install-extension ms-azuretools.vscode-docker
```

#### torizoncore-builder Not Found

If the command is not found after installation:

```bash
# Add to PATH temporarily
export PATH="$HOME/.local/bin:$PATH"

# Or restart your terminal session
```

### Windows 11 Issues

#### WSL Installation Failed

If WSL fails to install:

```powershell
# Check Windows version
winver  # Should be 19041 or higher

# Enable required features manually
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart and try again
```

#### Docker Desktop Won't Start

- Ensure virtualization is enabled in BIOS
- Check if Hyper-V is enabled: `Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V`
- Restart Docker Desktop from the system tray

#### WSL Can't Access Docker

```bash
# Inside WSL, check Docker socket
ls -la /var/run/docker.sock

# Restart Docker Desktop and reconnect to WSL
```

### General Issues

#### Script Fails on Non-Ubuntu Systems

This script is designed specifically for Ubuntu. For other distributions:
- Debian: May work with minor modifications
- Fedora/RHEL: Requires different package manager commands
- Arch: Requires different package names and AUR packages

## Documentation & Resources

- [Toradex Developer Website](https://developer.toradex.com/torizon)
- [TorizonCore Documentation](https://developer.toradex.com/torizon/torizoncore)
- [VS Code Torizon Extension](https://marketplace.visualstudio.com/items?itemName=Toradex.toradex-torizon-toolkit)
- [Torizon Samples](https://github.com/toradex/torizon-samples)
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/) (Windows users)

## Contributing

Contributions are welcome! If you encounter issues or have suggestions:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

## Issues

If you encounter problems:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review existing [Issues](https://github.com/Nat-As/torizon_environment/issues)
3. Create a new issue with:
   - Operating System and version (`lsb_release -a` or `winver`)
   - Error messages
   - Steps to reproduce

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This is an unofficial setup script. For official Toradex documentation and support, please visit the [Toradex Developer Center](https://developer.toradex.com/torizon/application-development/ide-extension/).

## Acknowledgments

- Toradex for creating Torizon OS and excellent developer tools
- The open-source community for the various tools and packages

---

**Made with ❤️ for the Torizon development community**
