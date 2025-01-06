eval "$(starship init bash)"

set -o vi

set show-mode-in-prompt on

set editing-mode vi
bldylw='\e[1;33m'
txtrst='\e[0m'
set vi-cmd-mode-string \[$bldylw\] [N] \[$txtrst\]

export PATH=$PATH:~/.poetry/bin/
export PATH=$PATH:/Library/Frameworks/Python.framework/Versions/3.10/bin

export CHEATCOLORS=true
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'

complete -d cd
bind TAB:menu-complete

VISUAL=vim; export VISUAL EDITOR=vim; export EDITOR
HISTCONTROL=ignoreboth
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=5000

if [ -d ~/.bash_completion.d ]; then
  for file in ~/.bash_completion.d/*; do
    . $file
  done
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

# some more ls aliases
alias gc='git clone'
alias cls='printf "\033[2J\033[H\033[3J"'
alias python='python3'
alias r='ranger'
alias pi='ipython3'
alias bat='batcat --theme TwoDark'
alias fd='fdfind'
alias ll='exa -alF'
alias ls='exa'
alias svim='sudo vim'
alias clk='kitty -o font_size=20 -e tty-clock -s -c -C 4 -t -f %d-%m-%Y &'
alias k='kubectl'


if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi




# Function to search GitHub for a commit hash or pull requests
searchcommit() {
    local SEARCH_TYPE="commits"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pr)
                SEARCH_TYPE="pullrequests"
                shift
                ;;
            --cm)
                SEARCH_TYPE="commits"
                shift
                ;;
            *)
                COMMIT_HASH="$1"
                shift
                ;;
        esac
    done

    if [ -z "$COMMIT_HASH" ]; then
        echo "Usage: searchcommit [--pr|--cm] <commit-hash>"
        return 1
    fi

    local SEARCH_URL="https://github.com/search?q=${COMMIT_HASH}&type=${SEARCH_TYPE}"

    if command -v xdg-open > /dev/null; then
        # Linux
        xdg-open "$SEARCH_URL"
    elif command -v open > /dev/null; then
        # macOS
        open "$SEARCH_URL"
    else
        echo "Could not detect the command to open a browser."
        echo "Please copy and paste this URL into your browser: $SEARCH_URL"
        return 2
    fi
}

code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
