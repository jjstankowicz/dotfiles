#!/bin/bash

setup_shell() {
    echo "Setting up Oh My Zsh..."
    
    # Clone the framework without running its installer or changing the login shell.
    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        if [ -e "$HOME/.oh-my-zsh" ] || [ -L "$HOME/.oh-my-zsh" ]; then
            echo 'Existing ~/.oh-my-zsh is incomplete; inspect it before retrying.' >&2
            return 1
        fi
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || return 1
    fi
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$custom_dir/plugins" "$custom_dir/themes" "$HOME/.myrm" || return 1
    
    # Install plugins
    echo "Installing Oh My Zsh plugins..."
    
    # zsh-autosuggestions
    if [ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
            "$custom_dir/plugins/zsh-autosuggestions" || return 1
    fi
    
    # zsh-syntax-highlighting
    if [ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
            "$custom_dir/plugins/zsh-syntax-highlighting" || return 1
    fi
    
    # Install powerlevel10k theme
    echo "Installing powerlevel10k theme..."
    if [ ! -d "$custom_dir/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$custom_dir/themes/powerlevel10k" || return 1
    fi
}

verify_shell_setup() {
    echo "Verifying shell setup..."
    local errors=0
    
    # Verify plugins
    for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting"; do
        if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]; then
            echo "Warning: Plugin $plugin not installed properly"
            errors=$((errors + 1))
        else
            echo "Plugin $plugin installed successfully"
        fi
    done
    
    # Verify theme
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        echo "Warning: powerlevel10k theme not installed properly"
        errors=$((errors + 1))
    else
        echo "Theme powerlevel10k installed successfully"
    fi
    
    return $errors
}
