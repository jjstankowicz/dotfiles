#!/usr/bin/env bash
# Check rerun safety and orchestration without changing the host or using sudo.
set -euo pipefail
repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scratch_dir="$(mktemp -d)"
trap 'rm -rf "$scratch_dir"' EXIT
env -u ZSH_CUSTOM HOME="$scratch_dir" bash -s -- "$repository_dir" <<'CHECKS'
set -euo pipefail
repository_dir="$1"
source "$repository_dir/lib/config.sh"
source "$repository_dir/lib/shell.sh"
source "$repository_dir/lib/tools.sh"
source "$repository_dir/lib/os.sh"

mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
mkdir -p "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"
printf keep > "$HOME/.oh-my-zsh/custom/user.zsh"
curl() { echo 'Unexpected shell framework download' >&2; return 1; }
git() { echo 'Unexpected shell plugin clone' >&2; return 1; }
sudo() { echo 'Unexpected privilege escalation' >&2; return 1; }
setup_shell
setup_shell
[[ $(cat "$HOME/.oh-my-zsh/custom/user.zsh") == keep ]]
[[ -d "$HOME/.myrm" ]]

# Existing shells stay intact while a missing plugin is installed once.
rmdir "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git() { [[ $1 == clone ]]; mkdir -p "${@: -1}"; }
setup_shell
verify_shell_setup

# A fresh home gets the framework and plugins without invoking a shell installer.
mv "$HOME/.oh-my-zsh" "$HOME/saved-oh-my-zsh"
git() {
    [[ $1 == clone ]]
    local destination="${@: -1}"
    mkdir -p "$destination"
    if [[ $destination == "$HOME/.oh-my-zsh" ]]; then
        touch "$destination/oh-my-zsh.sh"
    fi
}
setup_shell
verify_shell_setup
[[ $(cat "$HOME/saved-oh-my-zsh/custom/user.zsh") == keep ]]

# Refuse an incomplete framework without deleting any of its contents.
rm "$HOME/.oh-my-zsh/oh-my-zsh.sh"
printf keep > "$HOME/.oh-my-zsh/local-file"
if setup_shell; then
    echo 'Expected incomplete framework detection' >&2
    exit 1
fi
[[ $(cat "$HOME/.oh-my-zsh/local-file") == keep ]]

# Debian installs every prerequisite without requesting a full system upgrade.
sudo() { printf '%s\n' "$*" >> "$HOME/packages.log"; }
install_debian_packages
for package in ca-certificates curl tar gzip unzip build-essential zsh git tmux ripgrep fd-find fzf; do
    grep -qw "$package" "$HOME/packages.log"
done
! grep -Eq 'upgrade|dist-upgrade|lazygit|neovim' "$HOME/packages.log"

# A failed headless restore must reach the caller and leave the source lock alone.
mkdir -p "$HOME/bin"
printf '#!/bin/sh\nexit 23\n' > "$HOME/bin/nvim"
chmod +x "$HOME/bin/nvim"
export PATH="$HOME/bin:$PATH"
before="$(sha256sum "$repository_dir/configs/nvim/lazy-lock.json")"
if restore_neovim_plugins; then
    echo 'Expected plugin restoration failure' >&2
    exit 1
fi
[[ $(sha256sum "$repository_dir/configs/nvim/lazy-lock.json") == "$before" ]]
printf 'Installer workflow checks passed\n'
CHECKS
