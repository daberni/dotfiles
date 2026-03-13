# Plain zsh setup with lazy-loaded tool managers and cached CLI completions.

# Enable prompt interpolation and keep zsh's command autocorrection off.
setopt prompt_subst
unsetopt correct_all

# Treat punctuation as separators for completion and cursor movement.
WORDCHARS=''

# Load the modules used for interactive completion menus and prompt hooks.
zmodload -i zsh/complist
autoload -Uz add-zsh-hook compinit

unsetopt menu_complete
unsetopt flowcontrol
setopt auto_menu
setopt complete_in_word
setopt always_to_end

bindkey -M menuselect '^o' accept-and-infer-next-history

# Make Homebrew completions available even when a shell is started without .zprofile.
if [[ -z "$HOMEBREW_PREFIX" && -d /opt/homebrew/share/zsh/site-functions ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
fi
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

# Keep completion behavior close to the previous oh-my-zsh setup.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list \
  'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' \
  'r:|=*' \
  'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle '*' single-ignored show

typeset -g ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump-${HOST%%.*}-${ZSH_VERSION}"
if [[ -s "$ZSH_COMPDUMP" ]]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -d "$ZSH_COMPDUMP"
fi

if [[ -f "$HOME/.oh-my-zsh/plugins/history-substring-search/history-substring-search.zsh" ]]; then
  export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=
  export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=
  source "$HOME/.oh-my-zsh/plugins/history-substring-search/history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

alias bubu='brew update && brew upgrade'
alias ll="ls -la"
alias cd..="cd .."

# Lazy-load version managers so startup stays fast.
_load_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  [[ -s "$nvm_dir/nvm.sh" ]] && source "$nvm_dir/nvm.sh" --no-use
  [[ -s "$nvm_dir/bash_completion" ]] && source "$nvm_dir/bash_completion"
}

nvm() {
  unset -f nvm
  _load_nvm
  nvm "$@"
}

_load_sdkman() {
  local sdkman_dir="${SDKMAN_DIR:-$HOME/.sdkman}"
  [[ -s "$sdkman_dir/bin/sdkman-init.sh" ]] && source "$sdkman_dir/bin/sdkman-init.sh"
}

sdk() {
  unset -f sdk
  _load_sdkman
  sdk "$@"
}

_load_rvm() {
  local rvm_dir="${RVM_DIR:-$HOME/.rvm}"
  [[ -s "$rvm_dir/scripts/rvm" ]] && source "$rvm_dir/scripts/rvm"
}

rvm() {
  unset -f rvm
  _load_rvm
  rvm "$@"
}

# Cache generated completion scripts from external CLIs instead of regenerating them.
_load_cached_completion() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
  local cache_file cmd_name
  cache_file="$cache_dir/$1.zsh"
  cmd_name="$2"
  shift 2

  (( $+commands[$cmd_name] )) || return
  mkdir -p "$cache_dir"

  if [[ ! -s "$cache_file" || "${commands[$cmd_name]}" -nt "$cache_file" ]]; then
    "$@" >| "$cache_file" 2>/dev/null || return
  fi

  source "$cache_file"
}

_load_cached_completion forge forge forge --completion
_load_cached_completion ngrok ngrok ngrok completion
_load_cached_completion bb bb bb completion zsh

# Build the prompt from a static host/path part and a git segment refreshed before each draw.
_user_host() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    print -n '%F{cyan}%n@%m%f:'
  elif [[ "$LOGNAME" != "$USER" ]]; then
    print -n '%F{cyan}%n%f:'
  fi
}

# Compute git state once per prompt redraw instead of running git inside PROMPT itself.
_update_git_prompt_segment() {
  local branch='' git_status_output line
  integer dirty=0 untracked=0

  GIT_PROMPT_SEGMENT=''
  git_status_output=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain=2 --branch 2>/dev/null) || return

  while IFS= read -r line; do
    if [[ "$line" == '# branch.head '* ]]; then
      branch=${line##* }
    elif [[ "$line" == \?\ * ]]; then
      untracked=1
    elif [[ "$line" == [12u]' '* ]]; then
      dirty=1
    fi
  done <<< "$git_status_output"

  if [[ -z "$branch" || "$branch" == '(detached)' ]]; then
    branch=$(command git rev-parse --short HEAD 2>/dev/null) || return
  fi

  GIT_PROMPT_SEGMENT=" %F{green} ${branch}%f"
  (( dirty )) && GIT_PROMPT_SEGMENT+=" %F{yellow}⚡%f"
  (( untracked )) && GIT_PROMPT_SEGMENT+=" %F{green}?%f"
}

add-zsh-hook precmd _update_git_prompt_segment

PROMPT='$(_user_host)%B%F{blue}${PWD/#$HOME/~}%f%b${GIT_PROMPT_SEGMENT} %B%F{white}$%f%b '
