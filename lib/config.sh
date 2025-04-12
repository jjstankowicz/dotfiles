#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

setup_symlinks() {
    mkdir -p "$HOME/.config"
    
    # Remove existing configs
    rm -f "$HOME/.zshrc"
    rm -f "$HOME/.p10k.zsh"
    rm -f "$HOME/.cl_aliases"
    rm -f "$HOME/.tmux.conf"
    rm -rf "$HOME/.config/nvim"
    
    # Create symlinks
    ln -sf "$DOTFILES_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/configs/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    ln -sf "$DOTFILES_DIR/configs/zsh/.cl_aliases" "$HOME/.cl_aliases"
    ln -sf "$DOTFILES_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_DIR/configs/nvim" "$HOME/.config/nvim"
    
    # Make sure your .zshrc sources .cl_aliases
    grep -q "source ~/.cl_aliases" "$HOME/.zshrc" || {
        echo "# Source custom aliases" >> "$HOME/.zshrc"
        echo "source ~/.cl_aliases" >> "$HOME/.zshrc"
    }
}
