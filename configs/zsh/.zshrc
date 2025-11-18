# SSH Agent Management
# ssh_agent_start() {
#     # Don't run if we're in an SSH session
#     if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
#         return
#     fi
#
#     # Path to store the agent environment variables
#     local agent_env="$HOME/.ssh/agent.env"
#
#     # Source the stored agent environment if it exists
#     if [ -f "$agent_env" ]; then
#         source "$agent_env" >/dev/null
#     fi
#
#     # Check if agent is still running
#     if ! kill -0 $SSH_AGENT_PID >/dev/null 2>&1; then
#         # Start new agent
#         mkdir -p "$(dirname "$agent_env")"
#         ssh-agent > "$agent_env"
#         source "$agent_env" >/dev/null
#     fi
#
#     # Load keys if agent has none
#     ssh-add -l >/dev/null 2>&1 || ssh-add
# }

# # Debug function with more verbose output
# ssh_agent_debug() {
#     local agent_env="$HOME/.ssh/agent.env"
#     echo "Current SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
#     echo "Current SSH_AGENT_PID: $SSH_AGENT_PID"
#     
#     if [ -f "$agent_env" ]; then
#         echo "Agent environment file exists"
#         cat "$agent_env"
#     else
#         echo "No agent environment file found"
#     fi
#     
#     echo "Checking for running agents:"
#     pgrep -l ssh-agent
#     
#     echo "Loaded keys:"
#     ssh-add -l || echo "No keys loaded"
# }

# Alias for debugging
# alias fixssh='ssh_agent_debug'

# Start the agent
# ssh_agent_start


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


### Code dump for LLM help

codetree() {
  local src_dir="."
  local outfile="CODETREE.txt"
  local omit_patterns=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --source|-s) src_dir="$2"; shift 2 ;;
      --output|-o) outfile="$2"; shift 2 ;;
      --omit) omit_patterns+=("$2"); shift 2 ;;
      *) shift ;;
    esac
  done

  {
    echo "=== GIT FILES ==="
    git -C "$src_dir" ls-files

    echo
    echo "=== TREE VIEW (git-tracked only) ==="
    (
      cd "$src_dir" || exit 1
      git ls-files | sed 's|^|./|' | tree --fromfile .
    )

    echo
    echo "=== FILE CONTENTS ==="

    git -C "$src_dir" ls-files | while read -r file; do
      local skip=false
      for pattern in "${omit_patterns[@]}"; do
        [[ "$file" == *"$pattern"* ]] && skip=true && break
      done
      $skip && continue

      echo "----- FILE START: $file -----"
      cat "$src_dir/$file"
      echo
      echo "----- FILE END: $file -----"
      echo
    done
  } > "$outfile"
}


codeextract() {
  local src_dir="."
  local output_dir="code_extract"
  local omit_patterns=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --source|-s) src_dir="$2"; shift 2 ;;
      --output|-o) output_dir="$2"; shift 2 ;;
      --omit) omit_patterns+=("$2"); shift 2 ;;
      *) shift ;;
    esac
  done

  mkdir -p "$output_dir"

  # Copy actual file contents into flattened filenames
  git -C "$src_dir" ls-files | while read -r file; do
    local skip=false
    for pattern in "${omit_patterns[@]}"; do
      [[ "$file" == *"$pattern"* ]] && skip=true && break
    done
    $skip && continue

    local flat_name="${file//\//-SLASH-}"
    cp "$src_dir/$file" "$output_dir/$flat_name"
  done

  # Add GIT.txt
  git -C "$src_dir" ls-files > "$output_dir/GIT.txt"

  # Add TREE.txt based on git files
  (
    cd "$src_dir" || exit 1
    git ls-files | sed 's|^|./|' | tree --fromfile .
  ) > "$output_dir/TREE.txt"
}


export PYTHONBREAKPOINT=ipdb.set_trace

git config --global user.name "JJ Stankowicz"
git config --global user.email "jj.stankowicz@gmail.com"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/snap/bin:$PATH"

# . "$HOME/.local/bin/env"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
