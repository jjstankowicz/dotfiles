# SSH Agent Management
ssh_agent_start() {
    # Don't run if we're in an SSH session
    if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
        return
    fi

    # Path to store the agent environment variables
    local agent_env="$HOME/.ssh/agent.env"

    # Source the stored agent environment if it exists
    if [ -f "$agent_env" ]; then
        source "$agent_env" >/dev/null
    fi

    # Check if agent is still running
    if ! kill -0 $SSH_AGENT_PID >/dev/null 2>&1; then
        # Start new agent
        mkdir -p "$(dirname "$agent_env")"
        ssh-agent > "$agent_env"
        source "$agent_env" >/dev/null
    fi

    # Load keys if agent has none
    ssh-add -l >/dev/null 2>&1 || ssh-add
}

# Debug function with more verbose output
ssh_agent_debug() {
    local agent_env="$HOME/.ssh/agent.env"
    echo "Current SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
    echo "Current SSH_AGENT_PID: $SSH_AGENT_PID"
    
    if [ -f "$agent_env" ]; then
        echo "Agent environment file exists"
        cat "$agent_env"
    else
        echo "No agent environment file found"
    fi
    
    echo "Checking for running agents:"
    pgrep -l ssh-agent
    
    echo "Loaded keys:"
    ssh-add -l || echo "No keys loaded"
}

# Alias for debugging
alias fixssh='ssh_agent_debug'

# Start the agent
ssh_agent_start


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

function codetree() {
  local debug=false
  local output_file="code_dump.txt"
  local source_dir="."  # Default to current directory
  local patterns=("*.py")  # Default pattern
  local original_dir=$(pwd)  # Store original directory

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --debug)
        debug=true
        shift
        ;;
      --output|-o)
        output_file="$2"
        shift 2
        ;;
      --source|-s)
        source_dir="$2"
        shift 2
        ;;
      *)
        # All remaining args are treated as patterns
        patterns=("$@")
        break
        ;;
    esac
  done

  # Verify source directory exists
  if [[ ! -d "${source_dir}" ]]; then
    echo "Error: Source directory '${source_dir}' does not exist"
    return 1
  fi

  # Change to source directory
  pushd "${source_dir}" >/dev/null || {
    echo "Error: Could not change to directory '${source_dir}'"
    return 1
  }

  # Print debug info if enabled
  if [[ "$debug" = true ]]; then
    echo "Running codetree from directory: $(pwd)"
    echo "Original directory: ${original_dir}"
  fi

  # Create/clear the output file
  # Use absolute path if output file path is relative
  if [[ "${output_file:0:1}" != "/" ]]; then
    output_file="${original_dir}/${output_file}"
  fi
  echo -n > "${output_file}"
  
  # Add debug info to output file if enabled
  if [[ "$debug" = true ]]; then
    echo "Generated from directory: $(pwd)" >> "${output_file}"
    echo "Timestamp: $(date)" >> "${output_file}"
    echo "===================" >> "${output_file}"
  fi

  # Store the excluded patterns in a variable for consistency
  local exclude_pattern="*.pyc|*.pyo|__pycache__|*.egg-info|*.so|*.o|*.class|node_modules|.git|build|dist"

  # Add tree structure first
  if [[ "$debug" = true ]]; then
    echo -e "\nDirectory Structure:" >> "${output_file}"
    echo "===================" >> "${output_file}"
  fi
  tree -I "${exclude_pattern}" >> "${output_file}"

  if [[ "$debug" = true ]]; then
    echo -e "\nFile Contents:" >> "${output_file}"
    echo "=============" >> "${output_file}"
  fi

  # Use find to get sorted list of files and add contents
  for pattern in "${patterns[@]}"; do
    find . \
      -name "${pattern}" \
      ! -path "*/\.*" \
      ! -path "*/__pycache__/*" \
      ! -path "*/node_modules/*" \
      ! -path "*/build/*" \
      ! -path "*/dist/*" \
      ! -path "*.egg-info/*" \
      -type f \
      -print0 | sort -z | while IFS= read -r -d $'\0' file; do
        echo -e "\n### ${file} ###" >> "${output_file}"
        if [[ "$debug" = true ]]; then
          echo "# File size: $(wc -c < "${file}") bytes" >> "${output_file}"
          echo "# Last modified: $(stat -f "%Sm" "${file}" 2>/dev/null || stat -c "%y" "${file}")" >> "${output_file}"
          echo "# MD5 hash: $(md5sum "${file}" | cut -d' ' -f1)" >> "${output_file}"
        fi
        cat "${file}" >> "${output_file}"
    done
  done

  # Return to original directory
  popd >/dev/null

  if [[ "$debug" = true ]]; then
    echo "Code tree written to ${output_file} (debug mode)"
  else
    echo "Code tree written to ${output_file}"
  fi
}

export PYTHONBREAKPOINT=ipdb.set_trace

git config --global user.name "JJ Stankowicz"
git config --global user.email "jj.stankowicz@raventures.com"
