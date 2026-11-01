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
        echo "${ID_LIKE:-}"
    else
        echo ""
    fi
}

check_cmd_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Install prerequisites explicitly; editor binaries and Node are managed separately.
install_amazon_linux_packages() {
    local manager=dnf
    command -v dnf >/dev/null 2>&1 || manager=yum
    sudo "$manager" install -y ca-certificates curl tar gzip unzip gcc gcc-c++ make \
        zsh git tmux ripgrep fzf
}

install_debian_packages() {
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl tar gzip unzip build-essential \
        zsh git tmux ripgrep fd-find fzf
}

install_arch_packages() {
    # Arch requires a synchronized full upgrade to avoid unsupported partial upgrades.
    sudo pacman -Syu --needed --noconfirm ca-certificates curl tar gzip unzip \
        base-devel zsh git tmux ripgrep fd fzf
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

