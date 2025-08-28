# macOS-specific configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
    PATH="/usr/local/bin:$PATH"
    export PATH=/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Applications/kitty.app/Contents/MacOS
    . "$HOME/.cargo/env"

    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$PATH:$HOME/.scripts:$HOME/.local/bin:$HOME/.local/go/bin:$HOME/.cargo/bin:/usr/local/go/bin"

export CHEATCOLORS=true
export LIBVA_DRIVER_NAME=i965
export LS_COLORS="*.*=0:di=34"
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export VISUAL=vim
export EDITOR=vim

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Set python path using uv if available
if command -v uv &> /dev/null; then
    for dir in $(uv python dir)/*/bin; do
        if [ -d "$dir" ]; then
            export PATH="$dir:$PATH"
        fi
    done
fi

exec bash

[[ -f ~/.bashrc ]] && source ~/.bashrc
