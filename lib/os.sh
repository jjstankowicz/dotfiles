#!/bin/bash

get_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo $(uname -s)
    fi
}

check_cmd_installed() {
    command -v "$1" >/dev/null 2>&1
}

install_amazon_linux_packages() {
    # Update system packages
    echo "Updating system packages..."
    sudo dnf update -y
    
    echo "Checking required packages..."
    local packages_to_install=()
    
    # Check each command/package
    check_cmd_installed zsh || packages_to_install+=("zsh")
    check_cmd_installed git || packages_to_install+=("git")
    check_cmd_installed gcc || packages_to_install+=("gcc")
    check_cmd_installed make || packages_to_install+=("make")
    check_cmd_installed node || packages_to_install+=("nodejs")
    check_cmd_installed npm || packages_to_install+=("npm")
    check_cmd_installed tmux || packages_to_install+=("tmux")
    
    # Always install these as they're needed for user management
    packages_to_install+=("util-linux-user" "tar")
    
    # Install packages if any are needed
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo "Installing packages: ${packages_to_install[*]}"
        sudo dnf install -y "${packages_to_install[@]}"
    else
        echo "All base packages are already installed"
    fi

    # Check neovim separately as it has its own installation process
    check_cmd_installed nvim || install_neovim
    
    # Install ripgrep manually since it's not in Amazon Linux repos
    check_cmd_installed rg || install_ripgrep

    # Verify installations
    echo "Verifying installations..."
    local verification_failed=0
    for cmd in zsh git nvim node npm tmux rg; do
        if ! check_cmd_installed "$cmd"; then
            echo "Warning: $cmd installation may have failed"
            verification_failed=1
        fi
    done
    
    return $verification_failed
}

install_debian_packages() {
    sudo apt-get update
    sudo apt-get install -y zsh neovim git curl tar util-linux tmux ripgrep
}

install_packages_for_os() {
    OS=$(get_os)
    echo "Detected OS: $OS"
    
    case $OS in
        "amzn")
            install_amazon_linux_packages
            ;;
        "ubuntu"|"debian")
            install_debian_packages
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}
