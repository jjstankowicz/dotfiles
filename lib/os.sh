#!/bin/bash

# Detect the OS ID (e.g. ubuntu, debian, arch, omarchy, amzn)
get_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        uname -s
    fi
}

# Detect ID_LIKE (e.g. "debian", "arch")
get_os_like() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID_LIKE"
    else
        echo ""
    fi
}

check_cmd_installed() {
    command -v "$1" >/dev/null 2>&1
}

install_amazon_linux_packages() {
    echo "Detected Amazon Linux; installing packages via dnf/yum..."

    local packages_to_install=()

    check_cmd_installed zsh      || packages_to_install+=("zsh")
    check_cmd_installed git      || packages_to_install+=("git")
    check_cmd_installed gcc      || packages_to_install+=("gcc")
    check_cmd_installed make     || packages_to_install+=("make")
    check_cmd_installed tmux     || packages_to_install+=("tmux")
    check_cmd_installed neovim   || packages_to_install+=("neovim")
    check_cmd_installed rg       || packages_to_install+=("ripgrep")
    check_cmd_installed fzf      || packages_to_install+=("fzf")
    check_cmd_installed lazygit  || packages_to_install+=("lazygit")

    if [ "${#packages_to_install[@]}" -eq 0 ]; then
        echo "All required packages already installed."
        return 0
    fi

    if command -v dnf >/dev/null 2>&1; then
        sudo dnf update -y
        sudo dnf install -y "${packages_to_install[@]}"
    else
        sudo yum update -y
        sudo yum install -y "${packages_to_install[@]}"
    fi
}

install_debian_packages() {
    echo "Detected Debian/Ubuntu; installing packages via apt..."

    sudo apt-get update -y

    local packages_to_install=()

    check_cmd_installed zsh      || packages_to_install+=("zsh")
    check_cmd_installed git      || packages_to_install+=("git")
    check_cmd_installed build-essential >/dev/null 2>&1 || packages_to_install+=("build-essential")
    check_cmd_installed tmux     || packages_to_install+=("tmux")
    check_cmd_installed nvim     || packages_to_install+=("neovim")
    check_cmd_installed rg       || packages_to_install+=("ripgrep")
    check_cmd_installed fd       || packages_to_install+=("fd-find")
    check_cmd_installed fzf      || packages_to_install+=("fzf")
    check_cmd_installed lazygit  || packages_to_install+=("lazygit")

    if [ "${#packages_to_install[@]}" -eq 0 ]; then
        echo "All required packages already installed."
        return 0
    fi

    sudo apt-get install -y "${packages_to_install[@]}"
}

install_arch_packages() {
    echo "Detected Arch/Omarchy; installing packages via pacman..."

    # Sync package database first
    sudo pacman -Syu --noconfirm

    local packages_to_install=()

    check_cmd_installed zsh      || packages_to_install+=("zsh")
    check_cmd_installed git      || packages_to_install+=("git")
    check_cmd_installed gcc      || packages_to_install+=("gcc")
    check_cmd_installed make     || packages_to_install+=("make")
    check_cmd_installed tmux     || packages_to_install+=("tmux")
    check_cmd_installed nvim     || packages_to_install+=("neovim")
    check_cmd_installed rg       || packages_to_install+=("ripgrep")
    check_cmd_installed fd       || packages_to_install+=("fd")
    check_cmd_installed fzf      || packages_to_install+=("fzf")
    check_cmd_installed lazygit  || packages_to_install+=("lazygit")
    check_cmd_installed tree     || packages_to_install+=("tree")
    check_cmd_installed curl     || packages_to_install+=("curl")

    if [ "${#packages_to_install[@]}" -eq 0 ]; then
        echo "All required packages already installed."
        return 0
    fi

    sudo pacman -S --needed --noconfirm "${packages_to_install[@]}"
}

install_packages_for_os() {
    local OS
    OS="$(get_os)"
    local OS_LIKE
    OS_LIKE="$(get_os_like)"

    echo "OS detected: $OS (ID_LIKE=$OS_LIKE)"

    case "$OS" in
        amzn)
            install_amazon_linux_packages
            ;;
        ubuntu|debian)
            install_debian_packages
            ;;
        arch)
            install_arch_packages
            ;;
        omarchy)
            # Omarchy is Arch-based; treat it as Arch
            install_arch_packages
            ;;
        *)
            # Fallback: if ID_LIKE says "arch", use arch install
            if echo "$OS_LIKE" | grep -qi "arch"; then
                install_arch_packages
            else
                echo "Unsupported OS: $OS"
                exit 1
            fi
            ;;
    esac
}

