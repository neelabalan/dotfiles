eval "$(starship init bash)"

set -o vi

set show-mode-in-prompt on

set editing-mode vi
bldylw='\e[1;33m'
txtrst='\e[0m'
set vi-cmd-mode-string \[$bldylw\] [N] \[$txtrst\]
export LS_COLORS="*.*=0:di=34"

export PATH=$PATH:~/.scripts/
export PATH=$PATH:~/.local/bin/
export PATH=$PATH:~/.local/go/bin/
export PATH=$PATH:~/.poetry/bin/
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.cargo/bin
export CHEATCOLORS=true
export LIBVA_DRIVER_NAME=i965
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

# /usr/bin/setxkbmap -option "ctrl:swapcaps"


case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes


export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias gc='git clone'
alias gw='git worktree'
alias cls='printf "\033[2J\033[H\033[3J"'
alias python='python3'
alias randname='python3 ~/.scripts/namesgenerator.py'
alias dotsync='rsync -avzPR $(cat $HOME/.dotfiles/.dotlist) $HOME/.dotfiles/'
#alias clk='kitty -o font_size=20 -e tty-clock -s -c -C 4 -t -f %d-%m-%Y &'
alias man='man "$1" | vim -'
alias r='ranger'
alias pi='ipython3'
alias bat='batcat --theme TwoDark'
alias fd='fdfind'
alias ll='eza -alF'
alias ls='eza'
alias svim='sudo vim'
alias clk='kitty -o font_size=20 -e tty-clock -s -c -C 4 -t -f %d-%m-%Y &'
alias pn='pnpm'
alias k='kubectl'
alias yz='yazi'
alias sbrc='source ~/.bashrc'
alias vbrc='vi ~/.bashrc'
alias open='command -v open >/dev/null 2>&1 && open "$@" || command -v start >/dev/null 2>&1 && start "$@" || echo "No open command found"'

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
vman() 
{
    if [ $# -eq 0 ]; then
        /usr/bin/man
    elif whatis $* ; then
        /usr/bin/man $* | col -b | vim -c 'set ft=man nomod nolist' -
    fi
}
alias man='vman'



if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


export NOTESDIR="$HOME/notes"


oc()
{
    reponame=$(echo $1 | cut -d'/' -f 2 | cut -d'.' -f 1)
    git clone $1 /tmp/$reponame
    code /tmp/$reponame
}

nn() 
{
    local note_name="$*"
    local note_date="`date +%F`"
    local note_ext="md"
    if [[ $note_name == "" ]]; then
        note_name="$note_date.$note_ext"
    else 
        note_name="$note_name.$note_ext"
    fi
    mkdir -p $NOTESDIR
    vim "$NOTESDIR/logs/$note_name"
}

ns() 
{
    local file
    [ -z "$1" ] && echo "No argument supplied - Enter a term to search" && return 1
    file="$(rg --files-with-matches --no-ignore --ignore-case --hidden --no-heading --no-messages $1 $NOTESDIR | fzf --preview 'batcat --theme ansi-dark --color "always" {}')"
    if [[ -n $file ]]; then
        vim $file
    fi
}

nl() 
{
    local files
    files="$(rg --files $NOTESDIR | fzf --preview 'batcat --theme ansi-dark --color "always" {}')"
    if [[ -n $files ]]; then
        vim $files
    fi
}

printcolor ()
{
	for i in {0..255}; do
   		printf "\x1b[38;5;${i}mcolour${i}\x1b[0m\n"
	done
}

unmapkey()
{
	xmodmap -e "keycode 23 = Tab"
	xmodmap -e "keycode 64 = Alt_L"
	xmodmap -e "keycode 37 = Control_L"
	xmodmap -e "keycode 66 = Caps_Lock"
}

title()
{
    ORIG=$PS1
    TITLE="\e]2;$@\a"
    PS1=${ORIG}${TITLE}
}

# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
eval "$(fzf --bash)"

code () { 
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $*
    else
        # Linux and other systems
        command code $*
    fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
