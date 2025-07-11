# macOS-specific configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
    PATH="/usr/local/bin:$PATH"
    export PATH=/opt/homebrew/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Applications/kitty.app/Contents/MacOS
    . "$HOME/.cargo/env"

    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

exec bash

[[ -f ~/.bashrc ]] && source ~/.bashrc # ghcup-env
