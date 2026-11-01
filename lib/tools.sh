#!/bin/bash

install_lazygit() {
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit lazygit.tar.gz
}

# Download release archives only when they match the pinned upstream SHA256 digest.
download_verified_archive() {
    local url="$1" checksum="$2" destination="$3"
    curl -fL --retry 3 -o "$destination" "$url" || return 1
    printf '%s  %s\n' "$checksum" "$destination" | sha256sum --check --status
}

install_neovim() (
    local version="0.11.7" architecture checksum archive_dir download_dir installed_version
    local install_dir="$HOME/.local/opt/neovim-v$version"
    local binary="$HOME/.local/bin/nvim"

    installed_version="$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\.[0-9]*\)$/\1/p' || true)"
    if [ -n "$installed_version" ] && [ "$(printf '%s\n' "$version" "$installed_version" | sort -V | head -n 1)" = "$version" ]; then
        echo "Neovim $installed_version already meets the minimum version $version"
        return 0
    fi
    case "$(uname -s):$(uname -m)" in
        Linux:x86_64)
            architecture="x86_64"
            checksum="38a7c6317f94503841096c00e8fde05ef04b9472fc9d7d62b6e033cecd6f7991"
            ;;
        Linux:aarch64|Linux:arm64)
            architecture="arm64"
            checksum="99bb3c53604e83ce18fc0b459e34cf1a5e212f4e5fbe2eb136b3c18092ae9905"
            ;;
        *) echo "Unsupported platform for Neovim: $(uname -s) $(uname -m)" >&2; return 1 ;;
    esac
    archive_dir="nvim-linux-$architecture"
    download_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$download_dir"' EXIT
    download_verified_archive \
        "https://github.com/neovim/neovim/releases/download/v$version/$archive_dir.tar.gz" \
        "$checksum" "$download_dir/nvim.tar.gz" || return 1
    tar -xzf "$download_dir/nvim.tar.gz" -C "$download_dir" || return 1
    "$download_dir/$archive_dir/bin/nvim" --version >/dev/null || return 1
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin" || return 1
    if [ -e "$install_dir" ]; then
        local backup_dir
        backup_dir="$(mktemp -d "${install_dir}.backup.XXXXXXXX")" || return 1
        mv "$install_dir" "$backup_dir/original" || return 1
    fi
    mv "$download_dir/$archive_dir" "$install_dir" || return 1
    link_config "$install_dir/bin/nvim" "$binary" || return 1
    "$binary" --version
)

install_delta() (
    local version="0.20.1" target checksum archive_dir download_dir
    local binary="$HOME/.local/bin/delta"
    if [ -x "$binary" ] && [ "$("$binary" --version)" = "delta $version" ]; then
        echo "Delta $version is already installed"
        return 0
    fi
    case "$(uname -s):$(uname -m)" in
        Linux:x86_64)
            target="x86_64-unknown-linux-musl"
            checksum="69dcb4043f55c29118f408c6efd30115e0a4e0a6709253343b8c8fa814ab4a31"
            ;;
        Linux:aarch64|Linux:arm64)
            target="aarch64-unknown-linux-gnu"
            checksum="da7f4338f593572ff426ae153e0870e2fdc72729416eff551b40cdeb67940db8"
            ;;
        *) echo "Unsupported platform for Delta: $(uname -s) $(uname -m)" >&2; return 1 ;;
    esac
    archive_dir="delta-$version-$target"
    download_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$download_dir"' EXIT
    download_verified_archive \
        "https://github.com/dandavison/delta/releases/download/$version/$archive_dir.tar.gz" \
        "$checksum" "$download_dir/delta.tar.gz" || return 1
    tar -xzf "$download_dir/delta.tar.gz" -C "$download_dir" || return 1
    "$download_dir/$archive_dir/delta" --version >/dev/null || return 1
    mkdir -p "$HOME/.local/bin" || return 1
    if [ -e "$binary" ] || [ -L "$binary" ]; then
        local backup_dir
        backup_dir="$(mktemp -d "${binary}.backup.XXXXXXXX")" || return 1
        mv "$binary" "$backup_dir/original" || return 1
    fi
    install -m755 "$download_dir/$archive_dir/delta" "$binary" || return 1
    "$binary" --version
)

# The LaTeX parser requires the CLI to generate its C parser during installation.
install_tree_sitter() (
    local version="0.25.10" architecture checksum download_dir
    local binary="$HOME/.local/bin/tree-sitter"
    if [ -x "$binary" ] && "$binary" --version | grep -q "^tree-sitter $version "; then
        echo "Tree-sitter CLI $version is already installed"
        return 0
    fi
    case "$(uname -s):$(uname -m)" in
        Linux:x86_64)
            architecture="x64"
            checksum="8283ddba69253c698f6e987ba0e2f9285e079c8db4d36ebe1394b5bb3a0ebdfd"
            ;;
        Linux:aarch64|Linux:arm64)
            architecture="arm64"
            checksum="07fbff8ae0eeb0d3e496e14fc1a30dcc730cc2c97d70e601e5357f2e51958af5"
            ;;
        *) echo "Unsupported platform for Tree-sitter CLI: $(uname -s) $(uname -m)" >&2; return 1 ;;
    esac
    download_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$download_dir"' EXIT
    download_verified_archive \
        "https://github.com/tree-sitter/tree-sitter/releases/download/v$version/tree-sitter-linux-$architecture.gz" \
        "$checksum" "$download_dir/tree-sitter.gz" || return 1
    gzip -dc "$download_dir/tree-sitter.gz" > "$download_dir/tree-sitter" || return 1
    mkdir -p "$HOME/.local/bin" || return 1
    if [ -e "$binary" ] || [ -L "$binary" ]; then
        local backup_dir
        backup_dir="$(mktemp -d "${binary}.backup.XXXXXXXX")" || return 1
        mv "$binary" "$backup_dir/original" || return 1
    fi
    install -m755 "$download_dir/tree-sitter" "$binary" || return 1
    "$binary" --version
)

# Build a self-contained converter without installing a full TeX distribution.
install_utftex() (
    local version="1.31" download_dir
    local checksum="8ca5a11d387631a34979295f73f9a2eccc87e17c690dcd4c1454eb65a9e372bc"
    local binary="$HOME/.local/bin/utftex"
    if [ -x "$binary" ] && "$binary" --version | grep -Fxq "Powered by libtexprintf $version"; then
        echo "utftex with libtexprintf $version is already installed"
        return 0
    fi
    download_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$download_dir"' EXIT
    download_verified_archive \
        "https://github.com/bartp5/libtexprintf/releases/download/v$version/libtexprintf-$version.tar.gz" \
        "$checksum" "$download_dir/utftex.tar.gz" || return 1
    tar -xzf "$download_dir/utftex.tar.gz" -C "$download_dir" || return 1
    cd "$download_dir/libtexprintf-$version" || return 1
    ./configure --disable-shared --enable-static || return 1
    make -j2 || return 1
    mkdir -p "$HOME/.local/bin" || return 1
    if [ -e "$binary" ] || [ -L "$binary" ]; then
        local backup_dir
        backup_dir="$(mktemp -d "${binary}.backup.XXXXXXXX")" || return 1
        mv "$binary" "$backup_dir/original" || return 1
    fi
    install -m755 src/utftex "$binary" || return 1
    "$binary" --version
)

# Use termtex for formulas outside utftex's supported syntax, including labeled arrows.
install_termtex() (
    local revision="c407d5cf52510e8b321714eda0d991827e4ed135"
    local source_checksum="17fe83d737d99fe37cb280ffd36be9740fdabcc94ec93cbd6695f36277b6e3ed"
    local go_version="1.27.3" architecture checksum download_dir
    local install_dir="$HOME/.local/opt/termtex-$revision"
    local binary="$HOME/.local/bin/termtex"
    if [ -x "$install_dir/termtex" ] && [ "$(readlink "$binary")" = "$install_dir/termtex" ]; then
        echo "termtex $revision is already installed"
        return 0
    fi
    case "$(uname -s):$(uname -m)" in
        Linux:x86_64)
            architecture="amd64"
            checksum="65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40"
            ;;
        Linux:aarch64|Linux:arm64)
            architecture="arm64"
            checksum="a06e99309dbcbdca1a8ccd2282c3ee146e55930886e26b4f1193269587165f49"
            ;;
        *) echo "Unsupported platform for termtex: $(uname -s) $(uname -m)" >&2; return 1 ;;
    esac
    download_dir="$(mktemp -d)" || return 1
    trap 'rm -rf "$download_dir"' EXIT
    download_verified_archive \
        "https://go.dev/dl/go$go_version.linux-$architecture.tar.gz" \
        "$checksum" "$download_dir/go.tar.gz" || return 1
    download_verified_archive \
        "https://codeload.github.com/doug/termtex/tar.gz/$revision" \
        "$source_checksum" "$download_dir/source.tar.gz" || return 1
    tar -xzf "$download_dir/go.tar.gz" -C "$download_dir" || return 1
    tar -xzf "$download_dir/source.tar.gz" -C "$download_dir" || return 1
    cd "$download_dir/termtex-$revision" || return 1
    GOTOOLCHAIN=local "$download_dir/go/bin/go" build -trimpath -ldflags '-s -w' \
        -o "$download_dir/termtex" ./cmd/termtex || return 1
    "$download_dir/termtex" '\xrightarrow{label}' | grep -q label || return 1
    mkdir -p "$install_dir" "$HOME/.local/bin" || return 1
    install -m755 "$download_dir/termtex" "$install_dir/termtex" || return 1
    link_config "$install_dir/termtex" "$binary" || return 1
)

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
