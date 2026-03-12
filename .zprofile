eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
export PATH="$PATH:/opt/homebrew/opt/ruby/bin"
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:/opt/homebrew/opt/mysql-client/bin"

export NVM_DIR="$HOME/.nvm"
export SDKMAN_DIR="$HOME/.sdkman"
export RVM_DIR="$HOME/.rvm"

if [[ -L "$SDKMAN_DIR/candidates/java/current" ]]; then
  export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# Added by Toolbox App
export PATH="$PATH:/Users/bd/Library/Application Support/JetBrains/Toolbox/scripts"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
