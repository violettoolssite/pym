#!/usr/bin/env bash

# pvm - Python Version Manager for Unix (Linux/macOS)
# A simple Python version manager inspired by nvm
#
# Author: pvm contributors
# License: Apache 2.0

set -e

# Version
PVM_VERSION="1.0.0"

# Directories
PVM_HOME="${PVM_HOME:-$HOME/.pvm}"
PVM_VERSIONS_DIR="$PVM_HOME/versions"
PVM_CURRENT_FILE="$PVM_HOME/current"
PVM_SETTINGS_FILE="$PVM_HOME/settings.json"
PVM_SYMLINK="$PVM_HOME/python"

# Default mirror
DEFAULT_MIRROR="https://www.python.org/ftp/python"

# Preset mirrors for Python download
declare -A MIRRORS=(
    ["default"]="https://www.python.org/ftp/python"
    ["tsinghua"]="https://mirrors.tuna.tsinghua.edu.cn/python"
    ["qinghua"]="https://mirrors.tuna.tsinghua.edu.cn/python"
    ["huawei"]="https://mirrors.huaweicloud.com/python"
    ["npmmirror"]="https://registry.npmmirror.com/-/binary/python"
    ["aliyun"]="https://mirrors.aliyun.com/python"
)

# Preset mirrors for pip
declare -A PIP_MIRRORS=(
    ["default"]="https://pypi.org/simple"
    ["tsinghua"]="https://pypi.tuna.tsinghua.edu.cn/simple"
    ["qinghua"]="https://pypi.tuna.tsinghua.edu.cn/simple"
    ["huawei"]="https://repo.huaweicloud.com/repository/pypi/simple"
    ["npmmirror"]="https://registry.npmmirror.com/-/binary/pypi/simple"
    ["aliyun"]="https://mirrors.aliyun.com/pypi/simple"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Available Python versions
AVAILABLE_VERSIONS=(
    "3.13.1" "3.13.0"
    "3.12.8" "3.12.7" "3.12.6" "3.12.5" "3.12.4" "3.12.3" "3.12.2" "3.12.1" "3.12.0"
    "3.11.11" "3.11.10" "3.11.9" "3.11.8" "3.11.7" "3.11.6" "3.11.5" "3.11.4" "3.11.3" "3.11.2" "3.11.1" "3.11.0"
    "3.10.16" "3.10.15" "3.10.14" "3.10.13" "3.10.12" "3.10.11" "3.10.10" "3.10.9" "3.10.8" "3.10.7" "3.10.6" "3.10.5" "3.10.4" "3.10.3" "3.10.2" "3.10.1" "3.10.0"
    "3.9.21" "3.9.20" "3.9.19" "3.9.18" "3.9.17" "3.9.16" "3.9.15" "3.9.14" "3.9.13" "3.9.12" "3.9.11" "3.9.10" "3.9.9" "3.9.8" "3.9.7" "3.9.6" "3.9.5" "3.9.4" "3.9.3" "3.9.2" "3.9.1" "3.9.0"
    "3.8.20" "3.8.19" "3.8.18" "3.8.17" "3.8.16" "3.8.15" "3.8.14" "3.8.13" "3.8.12" "3.8.11" "3.8.10" "3.8.9" "3.8.8" "3.8.7" "3.8.6" "3.8.5" "3.8.4" "3.8.3" "3.8.2" "3.8.1" "3.8.0"
)

# Initialize pvm directories
pvm_init() {
    mkdir -p "$PVM_HOME"
    mkdir -p "$PVM_VERSIONS_DIR"
    
    if [[ ! -f "$PVM_SETTINGS_FILE" ]]; then
        echo '{"mirror": "'"$DEFAULT_MIRROR"'"}' > "$PVM_SETTINGS_FILE"
    fi
}

# Get mirror from settings
pvm_get_mirror() {
    if [[ -f "$PVM_SETTINGS_FILE" ]]; then
        local mirror
        mirror=$(grep -o '"mirror"[[:space:]]*:[[:space:]]*"[^"]*"' "$PVM_SETTINGS_FILE" 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/')
        if [[ -n "$mirror" ]]; then
            echo "$mirror"
            return
        fi
    fi
    echo "$DEFAULT_MIRROR"
}

# Show help
pvm_help() {
    cat << EOF

pvm - Python Version Manager v${PVM_VERSION}

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

Configuration:
    pvm stores data in: $PVM_HOME

EOF
}

# Show version
pvm_version() {
    echo "pvm version $PVM_VERSION"
}

# Get installed versions
pvm_get_installed() {
    if [[ -d "$PVM_VERSIONS_DIR" ]]; then
        find "$PVM_VERSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -V -r
    fi
}

# Get current version
pvm_get_current() {
    if [[ -f "$PVM_CURRENT_FILE" ]]; then
        cat "$PVM_CURRENT_FILE" | tr -d '[:space:]'
    fi
}

# List installed versions
pvm_list() {
    local installed current
    installed=$(pvm_get_installed)
    current=$(pvm_get_current)
    
    if [[ -z "$installed" ]]; then
        echo -e "${YELLOW}No Python versions installed.${NC}"
        echo "Use 'pvm install <version>' to install a version."
        echo "Use 'pvm list available' to see available versions."
        return
    fi
    
    echo -e "\n${CYAN}Installed Python versions:${NC}"
    echo ""
    
    while IFS= read -r v; do
        if [[ "$v" == "$current" ]]; then
            echo -e "  ${GREEN}* $v (current)${NC}"
        else
            echo "    $v"
        fi
    done <<< "$installed"
    echo ""
}

# List available versions
pvm_list_available() {
    local installed
    installed=$(pvm_get_installed)
    
    echo -e "\n${CYAN}Available Python versions:${NC}"
    echo ""
    
    local prev_minor=""
    local line=""
    
    for v in "${AVAILABLE_VERSIONS[@]}"; do
        local minor
        minor=$(echo "$v" | cut -d. -f1-2)
        
        if [[ "$minor" != "$prev_minor" ]]; then
            if [[ -n "$line" ]]; then
                echo "$line"
            fi
            echo -e "  ${YELLOW}${minor}.x:${NC}"
            line="    "
            prev_minor="$minor"
        fi
        
        if echo "$installed" | grep -q "^${v}$"; then
            line+="[$v] "
        else
            line+="$v "
        fi
    done
    
    if [[ -n "$line" ]]; then
        echo "$line"
    fi
    
    echo ""
    echo -e "  ${GRAY}[version] = already installed${NC}"
    echo ""
}

# Detect OS and architecture
pvm_detect_platform() {
    local os arch
    
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    case "$os" in
        linux*)
            os="linux"
            ;;
        darwin*)
            os="macos"
            ;;
        *)
            echo "Unsupported OS: $os" >&2
            return 1
            ;;
    esac
    
    case "$arch" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        armv7l|armhf)
            arch="armv7"
            ;;
        i686|i386)
            arch="i686"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
    
    echo "${os}-${arch}"
}

# Show detected platform info
pvm_show_platform() {
    local platform
    platform=$(pvm_detect_platform) || return 1
    
    local os arch
    os=$(echo "$platform" | cut -d'-' -f1)
    arch=$(echo "$platform" | cut -d'-' -f2)
    
    echo -e "${CYAN}Detected Platform:${NC}"
    echo "  OS: $os"
    echo "  Architecture: $arch"
}

# Check build dependencies
pvm_check_dependencies() {
    local missing=()
    
    for cmd in gcc make curl tar; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warning: Missing build dependencies: ${missing[*]}${NC}"
        echo "You may need to install them to build Python from source."
        echo ""
        echo "On Ubuntu/Debian:"
        echo "  sudo apt-get install build-essential libssl-dev zlib1g-dev \\"
        echo "    libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev \\"
        echo "    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev"
        echo ""
        echo "On macOS:"
        echo "  xcode-select --install"
        echo "  brew install openssl readline sqlite3 xz zlib"
        echo ""
        return 1
    fi
    return 0
}

# Install Python version
pvm_install() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo -e "${RED}Error: Please specify a version to install.${NC}"
        echo "Usage: pvm install <version>"
        echo "Example: pvm install 3.12.4"
        return 1
    fi
    
    # Validate version format
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid version format. Use format like '3.12.4'${NC}"
        return 1
    fi
    
    local version_dir="$PVM_VERSIONS_DIR/$version"
    
    # Check if already installed
    if [[ -d "$version_dir" ]]; then
        echo -e "${YELLOW}Python $version is already installed.${NC}"
        echo "Use 'pvm use $version' to switch to it."
        return 0
    fi
    
    local mirror
    mirror=$(pvm_get_mirror)
    
    # Try to use python-build-standalone for prebuilt binaries
    local platform
    platform=$(pvm_detect_platform) || return 1
    
    echo ""
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}  Installing Python $version${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo ""
    echo -e "  Mirror:     $mirror"
    echo -e "  Platform:   $platform"
    echo -e "  Install to: $version_dir"
    echo ""
    
    # Download source and build
    local source_url="$mirror/$version/Python-$version.tgz"
    local temp_dir
    temp_dir=$(mktemp -d)
    local source_file="$temp_dir/Python-$version.tgz"
    
    echo -e "${YELLOW}[1/5] Downloading Python $version source...${NC}"
    echo -e "${GRAY}      URL: $source_url${NC}"
    
    if ! curl -fSL "$source_url" -o "$source_file" 2>/dev/null; then
        echo -e "${RED}Error: Failed to download Python $version${NC}"
        echo "URL: $source_url"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${GREEN}      Download complete!${NC}"
    
    echo -e "${YELLOW}[2/5] Extracting source files...${NC}"
    tar -xzf "$source_file" -C "$temp_dir"
    
    local source_dir="$temp_dir/Python-$version"
    
    if [[ ! -d "$source_dir" ]]; then
        echo -e "${RED}Error: Failed to extract Python source${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check dependencies
    pvm_check_dependencies || {
        echo -e "${YELLOW}Continuing anyway...${NC}"
    }
    
    echo -e "${GREEN}      Extraction complete!${NC}"
    
    echo -e "${YELLOW}[3/5] Configuring build options...${NC}"
    cd "$source_dir"
    
    # Configure with optimization
    local configure_opts="--prefix=$version_dir --enable-optimizations --with-ensurepip=install"
    
    # Add macOS specific options
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # Try to find OpenSSL from Homebrew
        if [[ -d "/opt/homebrew/opt/openssl@3" ]]; then
            configure_opts="$configure_opts --with-openssl=/opt/homebrew/opt/openssl@3"
        elif [[ -d "/usr/local/opt/openssl@3" ]]; then
            configure_opts="$configure_opts --with-openssl=/usr/local/opt/openssl@3"
        elif [[ -d "/opt/homebrew/opt/openssl@1.1" ]]; then
            configure_opts="$configure_opts --with-openssl=/opt/homebrew/opt/openssl@1.1"
        elif [[ -d "/usr/local/opt/openssl@1.1" ]]; then
            configure_opts="$configure_opts --with-openssl=/usr/local/opt/openssl@1.1"
        fi
    fi
    
    if ! ./configure $configure_opts > "$temp_dir/configure.log" 2>&1; then
        echo -e "${RED}Error: Configuration failed. Check $temp_dir/configure.log for details.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}      Configuration complete!${NC}"
    
    echo -e "${YELLOW}[4/5] Building (this may take 5-15 minutes)...${NC}"
    local cpu_count
    cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
    echo -e "${GRAY}      Using $cpu_count CPU cores${NC}"
    
    if ! make -j"$cpu_count" > "$temp_dir/make.log" 2>&1; then
        echo -e "${RED}Error: Build failed. Check $temp_dir/make.log for details.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}      Build complete!${NC}"
    
    echo -e "${YELLOW}[5/5] Installing to $version_dir...${NC}"
    if ! make install > "$temp_dir/install.log" 2>&1; then
        echo -e "${RED}Error: Installation failed. Check $temp_dir/install.log for details.${NC}"
        return 1
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}  Python $version installed successfully!${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    echo "  Location: $version_dir"
    echo ""
    echo -e "${YELLOW}  Next steps:${NC}"
    echo -e "${CYAN}    pvm use $version        # Switch to this version${NC}"
    echo -e "${CYAN}    python3 --version       # Verify installation${NC}"
    echo ""
}

# Uninstall Python version
pvm_uninstall() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo -e "${RED}Error: Please specify a version to uninstall.${NC}"
        echo "Usage: pvm uninstall <version>"
        return 1
    fi
    
    local version_dir="$PVM_VERSIONS_DIR/$version"
    
    if [[ ! -d "$version_dir" ]]; then
        echo -e "${RED}Error: Python $version is not installed.${NC}"
        return 1
    fi
    
    local current
    current=$(pvm_get_current)
    
    if [[ "$version" == "$current" ]]; then
        echo -e "${YELLOW}Warning: Uninstalling the currently active version.${NC}"
        rm -f "$PVM_CURRENT_FILE"
        rm -f "$PVM_SYMLINK"
    fi
    
    echo ""
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}  Uninstalling Python $version${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo ""
    echo "  Location: $version_dir"
    echo ""
    echo -e "${YELLOW}  Removing files...${NC}"
    
    rm -rf "$version_dir"
    
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}  Python $version uninstalled successfully!${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    
    # Show remaining versions
    local remaining
    remaining=$(pvm_list_installed)
    if [[ -n "$remaining" ]]; then
        echo "  Remaining installed versions:"
        echo "$remaining" | while read -r v; do
            echo -e "${CYAN}    - $v${NC}"
        done
        echo ""
    else
        echo -e "${YELLOW}  No Python versions remaining.${NC}"
        echo "  Use 'pvm install <version>' to install a new version."
        echo ""
    fi
}

# Use Python version
pvm_use() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo -e "${RED}Error: Please specify a version to use.${NC}"
        echo "Usage: pvm use <version>"
        return 1
    fi
    
    local version_dir="$PVM_VERSIONS_DIR/$version"
    
    if [[ ! -d "$version_dir" ]]; then
        echo -e "${RED}Error: Python $version is not installed.${NC}"
        echo "Use 'pvm install $version' to install it first."
        return 1
    fi
    
    # Update current version
    echo -n "$version" > "$PVM_CURRENT_FILE"
    
    # Update symlink
    rm -f "$PVM_SYMLINK"
    ln -sf "$version_dir" "$PVM_SYMLINK"
    
    echo ""
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}  Switched to Python $version${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    
    # Show Python version
    local python_exe="$PVM_SYMLINK/bin/python3"
    if [[ -x "$python_exe" ]]; then
        local python_version
        python_version=$($python_exe --version 2>&1)
        echo "  Python:  $python_version"
        
        # Try to get pip version
        local pip_exe="$PVM_SYMLINK/bin/pip3"
        if [[ -x "$pip_exe" ]]; then
            local pip_version
            pip_version=$($pip_exe --version 2>&1 | sed 's/ from.*//')
            echo "  pip:     $pip_version"
        fi
        
        echo ""
        echo -e "${GRAY}  Path:    $python_exe${NC}"
    fi
    
    # Check if pvm python is in PATH
    if [[ ":$PATH:" != *":$PVM_SYMLINK/bin:"* ]]; then
        echo ""
        echo -e "${YELLOW}  Warning: pvm Python path not in PATH${NC}"
        echo -e "${YELLOW}  Add this to your shell profile:${NC}"
        echo -e "${CYAN}    export PATH=\"$PVM_SYMLINK/bin:\$PATH\"${NC}"
    fi
    echo ""
}

# Show current version
pvm_current() {
    local current
    current=$(pvm_get_current)
    
    if [[ -z "$current" ]]; then
        echo ""
        echo -e "${YELLOW}  No Python version is currently active.${NC}"
        echo ""
        echo "  To get started:"
        echo -e "${CYAN}    pvm list available    # See available versions${NC}"
        echo -e "${CYAN}    pvm install 3.12.4    # Install a version${NC}"
        echo -e "${CYAN}    pvm use 3.12.4        # Activate it${NC}"
        echo ""
        return
    fi
    
    echo ""
    echo -e "${GREEN}  Current version: $current${NC}"
    
    local python_exe="$PVM_SYMLINK/bin/python3"
    if [[ -x "$python_exe" ]]; then
        local python_version
        python_version=$($python_exe --version 2>&1)
        echo "  Python output:   $python_version"
        echo -e "${GRAY}  Path:            $python_exe${NC}"
    fi
    echo ""
}

# Show which python
pvm_which() {
    local current
    current=$(pvm_get_current)
    
    if [[ -z "$current" ]]; then
        echo ""
        echo -e "${YELLOW}  No Python version is currently active.${NC}"
        echo "  Use 'pvm use <version>' to activate a version."
        echo ""
        return
    fi
    
    local python_exe="$PVM_SYMLINK/bin/python3"
    local pip_exe="$PVM_SYMLINK/bin/pip3"
    
    echo ""
    echo -e "${GREEN}  Current version: $current${NC}"
    echo ""
    
    if [[ -x "$python_exe" ]]; then
        echo "  python3: $python_exe"
    else
        echo -e "${RED}  python3: (not found)${NC}"
    fi
    
    if [[ -x "$pip_exe" ]]; then
        echo "  pip3:    $pip_exe"
    else
        echo -e "${YELLOW}  pip3:    (not found)${NC}"
    fi
    echo ""
}

# Configure mirror
pvm_config() {
    local mirror_name="$1"
    
    # If no argument, show current config
    if [[ -z "$mirror_name" ]]; then
        pvm_show_config
        return
    fi
    
    local mirror_url=""
    local lower_name="${mirror_name,,}"
    
    # Check if it's a preset name
    if [[ -n "${MIRRORS[$lower_name]}" ]]; then
        mirror_url="${MIRRORS[$lower_name]}"
        echo -e "${CYAN}Using preset mirror: $mirror_name${NC}"
    elif [[ "$mirror_name" =~ ^https?:// ]]; then
        # It's a custom URL
        mirror_url="$mirror_name"
        echo -e "${CYAN}Using custom mirror URL${NC}"
    else
        echo -e "${RED}Error: Unknown mirror '$mirror_name'${NC}"
        echo ""
        echo -e "${YELLOW}Available presets:${NC}"
        echo "  tsinghua, qinghua   - Tsinghua University (https://mirrors.tuna.tsinghua.edu.cn/python)"
        echo "  huawei              - Huawei Cloud (https://mirrors.huaweicloud.com/python)"
        echo "  npmmirror           - npmmirror (https://registry.npmmirror.com/-/binary/python)"
        echo "  aliyun              - Aliyun (https://mirrors.aliyun.com/python)"
        echo "  default             - python.org (https://www.python.org/ftp/python)"
        echo ""
        echo "Or use a custom URL: pvm config https://your-mirror.com/python"
        return 1
    fi
    
    # Save to settings
    echo "{\"mirror\": \"$mirror_url\"}" > "$PVM_SETTINGS_FILE"
    
    echo -e "${GREEN}Python mirror configured: $mirror_url${NC}"
    
    # Configure pip mirror
    local pip_mirror_url=""
    if [[ -n "${PIP_MIRRORS[$lower_name]}" ]]; then
        pip_mirror_url="${PIP_MIRRORS[$lower_name]}"
    fi
    
    if [[ -n "$pip_mirror_url" ]]; then
        # Create pip config directory
        local pip_config_dir="$HOME/.pip"
        mkdir -p "$pip_config_dir"
        
        # Extract host from URL for trusted-host
        local pip_host
        pip_host=$(echo "$pip_mirror_url" | sed -E 's|https?://([^/]+).*|\1|')
        
        # Write pip.conf
        local pip_config_file="$pip_config_dir/pip.conf"
        cat > "$pip_config_file" << EOF
[global]
index-url = $pip_mirror_url
trusted-host = $pip_host
EOF
        echo -e "${GREEN}pip mirror configured: $pip_mirror_url${NC}"
        echo -e "${GRAY}pip config file: $pip_config_file${NC}"
    fi
}

# Show current config
pvm_show_config() {
    local mirror
    mirror=$(pvm_get_mirror)
    
    # Get pip config
    local pip_config_file="$HOME/.pip/pip.conf"
    local pip_mirror="https://pypi.org/simple (default)"
    if [[ -f "$pip_config_file" ]]; then
        local pip_url
        pip_url=$(grep -E '^index-url\s*=' "$pip_config_file" 2>/dev/null | sed 's/index-url\s*=\s*//')
        if [[ -n "$pip_url" ]]; then
            pip_mirror="$pip_url"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}pvm Configuration:${NC}"
    echo ""
    echo "  Python mirror: $mirror"
    echo "  pip mirror:    $pip_mirror"
    echo ""
    echo -e "${GRAY}  pvm config:  $PVM_SETTINGS_FILE${NC}"
    echo -e "${GRAY}  pip config:  $pip_config_file${NC}"
    echo ""
    echo -e "${YELLOW}Available presets (configures both Python and pip):${NC}"
    echo "  pvm config tsinghua   - Tsinghua University"
    echo "  pvm config huawei     - Huawei Cloud"
    echo "  pvm config npmmirror  - npmmirror"
    echo "  pvm config aliyun     - Aliyun"
    echo "  pvm config default    - python.org / pypi.org (Official)"
    echo ""
}

# Main function
pvm() {
    pvm_init
    
    local command="$1"
    shift || true
    
    case "$command" in
        list)
            if [[ "$1" == "available" ]]; then
                pvm_list_available
            else
                pvm_list
            fi
            ;;
        install)
            pvm_install "$1"
            ;;
        uninstall)
            pvm_uninstall "$1"
            ;;
        use)
            pvm_use "$1"
            ;;
        current)
            pvm_current
            ;;
        which)
            pvm_which
            ;;
        config)
            pvm_config "$1"
            ;;
        arch|platform)
            pvm_show_platform
            ;;
        --help|-h|help)
            pvm_help
            ;;
        --version|-v)
            pvm_version
            ;;
        "")
            pvm_help
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}"
            echo "Use 'pvm --help' for usage information."
            return 1
            ;;
    esac
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    pvm "$@"
fi

