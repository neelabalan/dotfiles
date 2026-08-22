# macOS-specific configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
    PATH="/usr/local/bin:$PATH"
    export PATH=/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Applications/kitty.app/Contents/MacOS
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    export PATH=$HOME/.opencode/bin:$PATH


    # eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$PATH:$HOME/.dotfiles/scripts:$HOME/.local/bin:$HOME/.local/go/bin:$HOME/.cargo/bin:/usr/local/go/bin"

export BASH_SILENCE_DEPRECATION_WARNING=1
export CHEATCOLORS=true
export LIBVA_DRIVER_NAME=i965
export LS_COLORS="*.*=0:di=34"
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export VISUAL=vim
export EDITOR=vim

export NVM_DIR="$HOME/.nvm"

# lazy load NVM - only load when node/npm/nvm is actually used
lazyload_nvm() {
    unset -f node npm npx nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

node() { lazyload_nvm; node "$@"; }
npm() { lazyload_nvm; npm "$@"; }
npx() { lazyload_nvm; npx "$@"; }
nvm() { lazyload_nvm; nvm "$@"; }

# set python path using uv if available (cached to avoid repeated calls)
if command -v uv &> /dev/null; then
    # cache the result to avoid running this expensive command every time
    if [ -z "$UV_PYTHON_PATHS_LOADED" ]; then
        for dir in $(uv python dir 2>/dev/null)/*/bin; do
            if [ -d "$dir" ]; then
                export PATH="$dir:$PATH"
            fi
        done
        export UV_PYTHON_PATHS_LOADED=1
    fi
fi

[[ -f ~/.bashrc ]] && source ~/.bashrc
