# Plain zsh setup with lazy-loaded tool managers and cached CLI completions.

setopt prompt_subst
unsetopt correct_all

WORDCHARS=''

zmodload -i zsh/complist
autoload -Uz add-zsh-hook compinit

unsetopt menu_complete
unsetopt flowcontrol
setopt auto_menu
setopt complete_in_word
setopt always_to_end

bindkey -M menuselect '^o' accept-and-infer-next-history

if [[ -z "$HOMEBREW_PREFIX" && -d /opt/homebrew/share/zsh/site-functions ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
fi
if [[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

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

alias ll="ls -la"
alias cd..="cd .."

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

git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return

  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify "refs/heads/$branch"; then
      print -r -- "$branch"
      return 0
    fi
  done

  print -r -- develop
  return 1
}

git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return

  local remote ref

  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref -q --verify "$ref"; then
      print -r -- "${ref:t}"
      return 0
    fi
  done

  for remote in origin upstream; do
    ref=$(command git rev-parse --abbrev-ref "$remote/HEAD" 2>/dev/null)
    if [[ "$ref" == "$remote/"* ]]; then
      print -r -- "${ref#"$remote/"}"
      return 0
    fi
  done

  print -r -- master
  return 1
}

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias gcb='git checkout -b'
alias gcB='git checkout -B'
alias gco='git checkout'
alias gcd='git checkout $(git_develop_branch)'
alias gcm='git checkout $(git_main_branch)'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias gsw='git switch'

alias bi='brew install'
alias bl='brew list'
alias bo='brew outdated'
alias bsl='brew services list'
alias bu='brew update'
alias bup='brew upgrade'

_user_host() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    print -n '%F{cyan}%n@%m%f:'
  elif [[ "$LOGNAME" != "$USER" ]]; then
    print -n '%F{cyan}%n%f:'
  fi
}

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
