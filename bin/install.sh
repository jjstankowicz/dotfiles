#!/bin/bash

# Exit on error
set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source all library files
source "$SCRIPT_DIR/lib/os.sh"
source "$SCRIPT_DIR/lib/tools.sh"
source "$SCRIPT_DIR/lib/shell.sh"
source "$SCRIPT_DIR/lib/config.sh"

# Prefer managed binaries throughout this run, including plugin build hooks.
export PATH="$HOME/.local/bin:$PATH"

# Main installation
echo "Starting installation..."

echo "Installing system packages..."
install_packages_for_os

echo "Installing lazygit..."
install_lazygit
install_node

echo "Installing editor binaries..."
install_neovim
install_delta
install_tree_sitter
install_utftex
install_termtex

echo "Setting up shell environment..."
setup_shell
verify_shell_setup

echo "Setting up configuration files..."
setup_symlinks

echo "Restoring pinned editor plugins and language tools..."
restore_neovim_plugins

echo "Installation complete! Open a new zsh terminal to use the configuration."
