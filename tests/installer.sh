#!/usr/bin/env bash
# Exercise configuration installation in an isolated home directory.
set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -gt 1 || ( $# -eq 1 && $1 != --download ) ]]; then
    echo "Usage: $0 [--download]" >&2
    exit 2
fi

scratch_dir="$(mktemp -d)"
trap 'rm -rf "$scratch_dir"' EXIT
env HOME="$scratch_dir" bash -s -- "$repository_dir" "$scratch_dir" "$@" <<'CHECKS'
set -euo pipefail
repository_dir="$1"
scratch_dir="$2"
shift 2
source "$repository_dir/lib/config.sh"
source "$repository_dir/lib/tools.sh"
mkdir -p "$HOME/.config/nvim" "$HOME/.config/lazygit"
printf original > "$HOME/.config/nvim/user.lua"
printf original > "$HOME/.config/lazygit/config.yml"
ln -s "$scratch_dir/missing-config" "$HOME/.config/lazygit/dark.yml"

setup_symlinks
[[ -L "$HOME/.config/nvim" ]]
[[ $(readlink "$HOME/.config/nvim") == "$repository_dir/configs/nvim" ]]
[[ $(readlink "$HOME/.config/lazygit/config.yml") == "$repository_dir/configs/lazygit/config.yml" ]]
[[ $(readlink "$HOME/.config/lazygit/dark.yml") == "$repository_dir/configs/lazygit/dark.yml" ]]
[[ $(readlink "$HOME/.local/bin/lazygit-diff") == "$repository_dir/bin/lazygit-diff" ]]
[[ $(cat "$HOME"/.config/nvim.backup.*/original/user.lua) == original ]]
[[ $(cat "$HOME"/.config/lazygit/config.yml.backup.*/original) == original ]]
broken_link_backup="$(find "$HOME/.config/lazygit" -path '*dark.yml.backup.*/original')"
[[ -L "$broken_link_backup" ]]
[[ $(readlink "$broken_link_backup") == "$scratch_dir/missing-config" ]]

backup_count="$(find "$HOME" -name '*.backup.*' | wc -l)"
setup_symlinks
[[ $(find "$HOME" -name '*.backup.*' | wc -l) == "$backup_count" ]]

printf test > "$scratch_dir/download.txt"
checksum="$(sha256sum "$scratch_dir/download.txt" | cut -d ' ' -f 1)"
download_verified_archive "file://$scratch_dir/download.txt" "$checksum" "$scratch_dir/verified.txt"
cmp "$scratch_dir/download.txt" "$scratch_dir/verified.txt"
if download_verified_archive "file://$scratch_dir/download.txt" "$(printf '0%.0s' {1..64})" "$scratch_dir/mismatch.txt"; then
    echo 'Expected checksum mismatch to fail' >&2
    exit 1
fi

if [[ ${1:-} == --download ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    install_neovim
    installed_version="$(nvim --version | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\.[0-9]*\)$/\1/p')"
    [[ -n "$installed_version" ]]
    [[ $(printf '%s\n' 0.11.7 "$installed_version" | sort -V | head -n 1) == 0.11.7 ]]
    install_neovim
    install_delta
    [[ $("$HOME/.local/bin/delta" --version) == 'delta 0.20.1' ]]
    install_delta
    install_tree_sitter
    [[ $("$HOME/.local/bin/tree-sitter" --version) == tree-sitter\ 0.25.10\ * ]]
    install_tree_sitter
    install_utftex
    "$HOME/.local/bin/utftex" --version | grep -Fxq 'Powered by libtexprintf 1.31'
    "$HOME/.local/bin/utftex" '\frac{1}{2}' | grep -q 1
    install_utftex
    install_termtex
    "$HOME/.local/bin/termtex" '\xrightarrow{label}' | grep -q label
    install_termtex
fi

printf 'Installer smoke checks passed\n'
CHECKS
