#!/usr/bin/env bash

# pvm installer for Unix (Linux/macOS)
# Installs pvm (Python Version Manager) on Unix systems.
#
# Usage:
#   curl -o- https://raw.githubusercontent.com/violettoolssite/pym/main/install.sh | bash
#   
#   Or with wget:
#   wget -qO- https://raw.githubusercontent.com/violettoolssite/pym/main/install.sh | bash

set -e

# Configuration
PVM_HOME="${PVM_HOME:-$HOME/.pvm}"
PVM_REPO="https://github.com/violettoolssite/pym.git"
PVM_RAW_BASE="https://raw.githubusercontent.com/violettoolssite/pym/main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect shell
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "sh"
    fi
}

# Get shell profile file
get_profile() {
    local shell_name
    shell_name=$(detect_shell)
    
    case "$shell_name" in
        zsh)
            if [[ -f "$HOME/.zshrc" ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zprofile"
            fi
            ;;
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.profile"
            fi
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Download file
download_file() {
    local url="$1"
    local dest="$2"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &> /dev/null; then
        wget -qO "$dest" "$url"
    else
        print_color "$RED" "Error: curl or wget is required to download files."
        exit 1
    fi
}

# Detect OS and install dependencies
install_dependencies() {
    print_color "$YELLOW" "Checking and installing build dependencies..."
    
    local os_type=""
    local pkg_manager=""
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        os_type="$ID"
    elif [[ -f /etc/redhat-release ]]; then
        os_type="rhel"
    elif [[ "$(uname)" == "Darwin" ]]; then
        os_type="macos"
    fi
    
    case "$os_type" in
        ubuntu|debian|linuxmint|pop)
            print_color "$CYAN" "Detected: Debian/Ubuntu based system"
            if command -v apt-get &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with apt..."
                sudo apt-get update -qq
                sudo apt-get install -y -qq build-essential libssl-dev zlib1g-dev \
                    libbz2-dev libreadline-dev libsqlite3-dev libffi-dev \
                    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev liblzma-dev \
                    curl wget 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            fi
            ;;
        centos|rhel|fedora|rocky|almalinux)
            print_color "$CYAN" "Detected: RHEL/CentOS based system"
            if command -v dnf &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with dnf..."
                sudo dnf groupinstall -y "Development Tools" 2>/dev/null || true
                sudo dnf install -y openssl-devel bzip2-devel libffi-devel \
                    readline-devel sqlite-devel xz-devel zlib-devel \
                    ncurses-devel tk-devel curl wget 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            elif command -v yum &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with yum..."
                sudo yum groupinstall -y "Development Tools" 2>/dev/null || true
                sudo yum install -y openssl-devel bzip2-devel libffi-devel \
                    readline-devel sqlite-devel xz-devel zlib-devel \
                    ncurses-devel tk-devel curl wget 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            fi
            ;;
        arch|manjaro)
            print_color "$CYAN" "Detected: Arch based system"
            if command -v pacman &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with pacman..."
                sudo pacman -Sy --noconfirm base-devel openssl zlib bzip2 \
                    readline sqlite libffi xz tk curl wget 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            fi
            ;;
        opensuse*|sles)
            print_color "$CYAN" "Detected: openSUSE/SLES"
            if command -v zypper &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with zypper..."
                sudo zypper install -y -t pattern devel_basis 2>/dev/null || true
                sudo zypper install -y libopenssl-devel zlib-devel libbz2-devel \
                    readline-devel sqlite3-devel libffi-devel xz-devel tk-devel \
                    curl wget 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            fi
            ;;
        alpine)
            print_color "$CYAN" "Detected: Alpine Linux"
            if command -v apk &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with apk..."
                sudo apk add --no-cache build-base openssl-dev zlib-dev bzip2-dev \
                    readline-dev sqlite-dev libffi-dev xz-dev tk-dev linux-headers \
                    curl wget 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            fi
            ;;
        macos)
            print_color "$CYAN" "Detected: macOS"
            if ! command -v xcode-select &> /dev/null || ! xcode-select -p &> /dev/null; then
                print_color "$YELLOW" "Installing Xcode Command Line Tools..."
                xcode-select --install 2>/dev/null || true
                print_color "$YELLOW" "Please complete Xcode CLI tools installation if prompted."
            fi
            
            if command -v brew &> /dev/null; then
                print_color "$YELLOW" "Installing dependencies with Homebrew..."
                brew install openssl@3 readline sqlite3 xz zlib tcl-tk 2>/dev/null || {
                    print_color "$YELLOW" "Some packages may have failed, continuing..."
                }
                print_color "$GREEN" "Dependencies installed!"
            else
                print_color "$YELLOW" "Homebrew not found. Install it from https://brew.sh for best experience."
            fi
            ;;
        *)
            print_color "$YELLOW" "Unknown OS: $os_type"
            print_color "$YELLOW" "Please install build dependencies manually."
            print_color "$YELLOW" "Needed: gcc, make, openssl-dev, zlib-dev, bzip2-dev, readline-dev, sqlite-dev, libffi-dev"
            ;;
    esac
}

# Main installation
install_pvm() {
    print_color "$CYAN" ""
    print_color "$CYAN" "=================================="
    print_color "$CYAN" "  pvm - Python Version Manager"
    print_color "$CYAN" "  Unix Installer"
    print_color "$CYAN" "=================================="
    print_color "$CYAN" ""

    # Install dependencies first
    install_dependencies
    echo ""
    
    # Create installation directory
    print_color "$YELLOW" "Installing pvm to: $PVM_HOME"
    
    mkdir -p "$PVM_HOME"
    mkdir -p "$PVM_HOME/versions"
    mkdir -p "$PVM_HOME/unix"

    # Download pvm script
    print_color "$YELLOW" "Downloading pvm scripts..."
    
    local pvm_script="$PVM_HOME/unix/pvm.sh"
    
    if ! download_file "$PVM_RAW_BASE/unix/pvm.sh" "$pvm_script" 2>/dev/null; then
        print_color "$YELLOW" "Could not download from GitHub, checking for local files..."
        
        # If running from cloned repo
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        
        if [[ -f "$script_dir/unix/pvm.sh" ]]; then
            cp "$script_dir/unix/pvm.sh" "$pvm_script"
        else
            print_color "$RED" "Error: Failed to download pvm script."
            exit 1
        fi
    fi

    # Make script executable
    chmod +x "$pvm_script"

    # Create symlink in pvm home
    ln -sf "$pvm_script" "$PVM_HOME/pvm.sh"

    # Create default settings
    local settings_file="$PVM_HOME/settings.json"
    if [[ ! -f "$settings_file" ]]; then
        echo '{"mirror": "https://www.python.org/ftp/python"}' > "$settings_file"
    fi

    # Add to shell profile
    print_color "$YELLOW" "Configuring shell profile..."
    
    local profile
    profile=$(get_profile)
    
    local pvm_init_snippet='
# pvm - Python Version Manager
export PVM_HOME="$HOME/.pvm"
[ -s "$PVM_HOME/pvm.sh" ] && source "$PVM_HOME/pvm.sh"
export PATH="$PVM_HOME/python/bin:$PATH"
'

    # Check if already configured
    if grep -q "PVM_HOME" "$profile" 2>/dev/null; then
        print_color "$GREEN" "Shell profile already configured."
    else
        print_color "$YELLOW" "Adding pvm to $profile..."
        echo "$pvm_init_snippet" >> "$profile"
        print_color "$GREEN" "Shell profile updated."
    fi

    # Success message
    print_color "$GREEN" ""
    print_color "$GREEN" "=============================================="
    print_color "$GREEN" "  pvm installed successfully!"
    print_color "$GREEN" "=============================================="
    print_color "$GREEN" ""

    print_color "$YELLOW" "IMPORTANT: To activate pvm, run ONE of the following:"
    echo ""
    echo "  Option 1 - Reload shell config (recommended):"
    print_color "$CYAN" "    source $profile"
    echo ""
    echo "  Option 2 - Open a new terminal window"
    echo ""

    print_color "$WHITE" "----------------------------------------------"
    print_color "$WHITE" "Quick Start Guide:"
    print_color "$WHITE" "----------------------------------------------"
    echo ""
    echo "  1. Check available versions:"
    print_color "$CYAN" "     pvm list available"
    echo ""
    echo "  2. Configure mirror (China users recommended):"
    print_color "$CYAN" "     pvm config tsinghua    # Tsinghua mirror"
    print_color "$CYAN" "     pvm config huawei      # Huawei Cloud mirror"
    print_color "$CYAN" "     pvm config npmmirror   # npmmirror"
    echo ""
    echo "  3. Install Python:"
    print_color "$CYAN" "     pvm install 3.12.4"
    echo ""
    echo "  4. Switch Python version:"
    print_color "$CYAN" "     pvm use 3.12.4"
    echo ""
    echo "  5. Verify installation:"
    print_color "$CYAN" "     python --version"
    echo ""

    print_color "$WHITE" "----------------------------------------------"
    print_color "$WHITE" "All Commands:"
    print_color "$WHITE" "----------------------------------------------"
    echo "  pvm list              - List installed versions"
    echo "  pvm list available    - List downloadable versions"
    echo "  pvm install <ver>     - Install a version"
    echo "  pvm use <ver>         - Switch to a version"
    echo "  pvm uninstall <ver>   - Remove a version"
    echo "  pvm current           - Show current version"
    echo "  pvm which             - Show Python path"
    echo "  pvm config [mirror]   - Configure download mirror"
    echo "  pvm arch              - Show system architecture"
    echo "  pvm --help            - Show help"
    echo ""

    print_color "$GREEN" "Build dependencies have been automatically installed."
    print_color "$GREEN" "Installation path: $PVM_HOME"
    print_color "$GREEN" "Config file: $profile"
    echo ""
}

# Run installer
install_pvm

