#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source all library files
source "$SCRIPT_DIR/lib/os.sh"
source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/shell.sh"
source "$SCRIPT_DIR/lib/config.sh"

# Main installation
echo "Starting installation..."

echo "Installing system packages..."
install_packages_for_os

echo "Installing lazygit..."
install_lazygit

echo "Setting up shell environment..."
setup_shell
verify_shell_setup || echo "Warning: Some shell components may not have installed correctly"

echo "Setting up configuration files..."
setup_symlinks

echo "Installation complete! Please log out and log back in to start using zsh."
