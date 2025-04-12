#!/bin/bash

setup_shell() {
    echo "Setting up Oh My Zsh..."
    
    # Remove existing Oh My Zsh if it exists
    if [ -d "$HOME/.oh-my-zsh" ]; then
        rm -rf "$HOME/.oh-my-zsh"
    fi
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install plugins
    echo "Installing Oh My Zsh plugins..."
    
    # zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    
    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    
    # Install powerlevel10k theme
    echo "Installing powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    
    # Change default shell to zsh
    if [ "$SHELL" != "$(which zsh)" ]; then
        sudo chsh -s $(which zsh) $USER
    fi
}

verify_shell_setup() {
    echo "Verifying shell setup..."
    local errors=0
    
    # Verify plugins
    for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting"; do
        if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin" ]; then
            echo "Warning: Plugin $plugin not installed properly"
            errors=$((errors + 1))
        else
            echo "Plugin $plugin installed successfully"
        fi
    done
    
    # Verify theme
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        echo "Warning: powerlevel10k theme not installed properly"
        errors=$((errors + 1))
    else
        echo "Theme powerlevel10k installed successfully"
    fi
    
    return $errors
}
