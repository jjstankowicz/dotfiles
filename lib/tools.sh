#!/bin/bash

install_lazygit() {
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit lazygit.tar.gz
}

install_neovim() {
    echo "Installing neovim..."
    
    if command -v nvim &> /dev/null && nvim --version > /dev/null 2>&1; then
        echo "Neovim is already installed and working"
        return 0
    fi

    # Try installing FUSE first
    echo "Installing FUSE dependencies..."
    sudo dnf install -y fuse fuse-libs || {
        echo "Warning: Failed to install FUSE dependencies"
    }
    
    # Get latest version number first
    echo "Getting latest Neovim version..."
    NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep -Po '"tag_name": "\K[^"]*')
    
    if [ -z "$NVIM_VERSION" ]; then
        echo "Failed to get Neovim version"
        return 1
    fi
    
    # Download AppImage using version-specific URL
    echo "Downloading Neovim AppImage..."
    curl -L -o nvim.appimage "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.appimage"
    chmod u+x nvim.appimage
    
    # Try running AppImage to test
    if ./nvim.appimage --version > /dev/null 2>&1; then
        echo "AppImage works, installing..."
        sudo mv nvim.appimage /usr/local/bin/nvim
        return 0
    fi
    
    echo "AppImage not working, trying tarball instead..."
    rm -f nvim.appimage
    
    # Download and extract tarball
    curl -L -o nvim.tar.gz "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
    tar xzf nvim.tar.gz
    
    # Install from tarball
    sudo mv nvim-linux-x86_64 /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    
    # Clean up
    rm -f nvim.tar.gz
    
    # Verify installation
    if command -v nvim &> /dev/null && nvim --version > /dev/null 2>&1; then
        echo "Neovim installed successfully"
        return 0
    fi
    
    echo "Failed to install neovim"
    return 1
}

install_ripgrep() {
    if command -v rg &> /dev/null; then
        echo "ripgrep is already installed"
        return 0
    fi

    echo "Installing ripgrep..."
    
    # Get latest version
    RIPGREP_VERSION=$(curl -s "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    
    if [ -z "$RIPGREP_VERSION" ]; then
        echo "Failed to get ripgrep version"
        return 1
    fi
    
    # Download and extract
    curl -Lo ripgrep.tar.gz "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    
    tar xf ripgrep.tar.gz
    
    # The extracted directory will be named like ripgrep-13.0.0-x86_64-unknown-linux-musl
    cd ripgrep-*-x86_64-unknown-linux-musl
    
    # Install the binary and man page
    sudo install -m755 rg /usr/local/bin/
    sudo install -m644 doc/rg.1 /usr/local/share/man/man1/
    
    # Clean up
    cd ..
    rm -rf ripgrep-*-x86_64-unknown-linux-musl ripgrep.tar.gz
    
    # Verify installation
    if ! command -v rg &> /dev/null; then
        echo "Failed to install ripgrep"
        return 1
    fi
    
    echo "ripgrep installed successfully"
    return 0
}
