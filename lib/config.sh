#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Preserve existing files, directories, and broken links before replacement.
preserve_config() {
    local destination="$1" backup
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        backup="$(mktemp -d "${destination}.backup.XXXXXXXX")" || return 1
        mv "$destination" "$backup/original" || return 1
        echo "Preserved $destination in $backup/original"
    fi
}

link_config() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname "$destination")" || return 1
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
        return 0
    fi
    preserve_config "$destination" || return 1
    ln -s "$source" "$destination"
}

copy_config() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname "$destination")" || return 1
    if [ -f "$destination" ] && [ ! -L "$destination" ] && cmp -s "$source" "$destination"; then
        return 0
    fi
    preserve_config "$destination" || return 1
    cp "$source" "$destination"
}

# Merge regular directories without following destination directory links.
copy_config_directory() (
    local source="$1" destination="$2" entry
    if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -d "$destination" ]; }; then
        echo "Refusing to install through a linked or non-directory path: $destination" >&2
        return 1
    fi
    mkdir -p "$destination" || return 1
    shopt -s dotglob nullglob
    for entry in "$source"/*; do
        if [ -d "$entry" ]; then
            copy_config_directory "$entry" "$destination/$(basename "$entry")" || return 1
        else
            copy_config "$entry" "$destination/$(basename "$entry")" || return 1
        fi
    done
)

# Install only repository-managed skills, leaving other skill directories intact.
setup_codex_skills() {
    local codex_dir="${CODEX_HOME:-$HOME/.codex}"
    copy_config_directory "$DOTFILES_DIR/configs/codex/skills" "$codex_dir/skills"
}

setup_codex_config() {
    local codex_dir="${CODEX_HOME:-$HOME/.codex}"
    copy_config "$DOTFILES_DIR/configs/codex/AGENTS.md" "$codex_dir/AGENTS.md" || return 1
    copy_config "$DOTFILES_DIR/configs/codex/machine-context.md" "$codex_dir/machine-context.md" || return 1
    copy_config "$DOTFILES_DIR/configs/codex/runbooks/copilot-review.md" "$codex_dir/runbooks/copilot-review.md" || return 1
    copy_config "$DOTFILES_DIR/configs/codex/runbooks/planning-cookbook.md" "$codex_dir/runbooks/planning-cookbook.md" || return 1
    setup_codex_skills
}

setup_symlinks() {
    setup_codex_config || return 1
    link_config "$DOTFILES_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
    link_config "$DOTFILES_DIR/configs/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    link_config "$DOTFILES_DIR/configs/zsh/.cl_aliases" "$HOME/.cl_aliases"
    link_config "$DOTFILES_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
    link_config "$DOTFILES_DIR/configs/nvim" "$HOME/.config/nvim"
    link_config "$DOTFILES_DIR/configs/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
    link_config "$DOTFILES_DIR/configs/lazygit/dark.yml" "$HOME/.config/lazygit/dark.yml"
    link_config "$DOTFILES_DIR/bin/lazygit-diff" "$HOME/.local/bin/lazygit-diff"
}
