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
PVM_RAW_BASE="https://pvm.violetteam.cloud"

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

# Main installation
install_pvm() {
    print_color "$CYAN" ""
    print_color "$CYAN" "=================================="
    print_color "$CYAN" "  pvm - Python Version Manager"
    print_color "$CYAN" "  Unix Installer"
    print_color "$CYAN" "=================================="
    print_color "$CYAN" ""

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
    print_color "$GREEN" "=================================="
    print_color "$GREEN" "  pvm installed successfully!"
    print_color "$GREEN" "=================================="
    print_color "$GREEN" ""

    echo "To start using pvm, run:"
    print_color "$CYAN" "  source $profile"
    echo ""
    echo "Or open a new terminal and run:"
    print_color "$CYAN" "  pvm --help"
    echo ""

    echo "Quick start:"
    print_color "$CYAN" "  pvm list available     # List available Python versions"
    print_color "$CYAN" "  pvm install 3.12.4     # Install Python 3.12.4"
    print_color "$CYAN" "  pvm use 3.12.4         # Switch to Python 3.12.4"
    echo ""

    print_color "$YELLOW" "Note: Building Python from source requires development tools."
    echo "See the README for dependency installation instructions."
}

# Run installer
install_pvm

