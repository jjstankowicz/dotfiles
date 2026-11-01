#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Preserve existing files and directories before replacing them with managed links.
link_config() {
    local source="$1" destination="$2" backup
    mkdir -p "$(dirname "$destination")" || return 1
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
        return 0
    fi
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        backup="$(mktemp -d "${destination}.backup.XXXXXXXX")" || return 1
        mv "$destination" "$backup/original" || return 1
        echo "Preserved $destination in $backup/original"
    fi
    ln -s "$source" "$destination"
}

setup_symlinks() {
    link_config "$DOTFILES_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
    link_config "$DOTFILES_DIR/configs/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    link_config "$DOTFILES_DIR/configs/zsh/.cl_aliases" "$HOME/.cl_aliases"
    link_config "$DOTFILES_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
    link_config "$DOTFILES_DIR/configs/nvim" "$HOME/.config/nvim"
    link_config "$DOTFILES_DIR/configs/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
    link_config "$DOTFILES_DIR/configs/lazygit/dark.yml" "$HOME/.config/lazygit/dark.yml"
    link_config "$DOTFILES_DIR/bin/lazygit-diff" "$HOME/.local/bin/lazygit-diff"
}
