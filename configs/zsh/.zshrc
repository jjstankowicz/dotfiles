# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

# Enable oh-my-zsh framework
export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="cl_theme"  # Use your preferred theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Ensure compatibility with your terminal
# export TERM=xterm-256color

# Fancy prompt similar to your bash prompt
# export PS1="%{$(tput setaf 1)%}%n%{$(tput sgr0)%}@%{$(tput setaf 2)%}%m%{$(tput sgr0)%}:%{$(tput setaf 4)%}%1~%{$(tput sgr0)%}
# $ "

# Aliases
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias for long-running command alerts
alias alert='notify-send --urgency=low -i "$(test $? -eq 0 && echo terminal || echo error)" "$(fc -ln -1)"'

# Use control keys to move forward and back in words
bindkey '^[[5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^U' backward-kill-line

# Path to nvim
export PATH="$PATH:/opt/nvim-linux64/bin"

# Enable conda initialization
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
else
    export PATH="$HOME/miniconda3/bin:$PATH"
fi

# History settings (similar to bash)
HISTSIZE=1000
SAVEHIST=2000
HISTFILE=~/.zsh_history

# Check window size after commands
TRAPWINCH() {
  zle reset-prompt
}

# Enable colors for grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Enable programmable completion
autoload -U compinit && compinit

# Source ~/.cl_aliases if it exists
if [ -f ~/.cl_aliases ]; then
    source ~/.cl_aliases
fi

if [ -f ~/.keys ]; then
    source ~/.keys
fi


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export PYTHONBREAKPOINT=ipdb.set_trace

git config --global user.name "James Stankowicz"
git config --global user.email "james.stankowicz@lumagroup.com"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/snap/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"