
eval "$(starship init bash)"

set -o vi

set show-mode-in-prompt on

set editing-mode vi
bldylw='\e[1;33m'
txtrst='\e[0m'
set vi-cmd-mode-string \[$bldylw\] [N] \[$txtrst\]

export PATH=$PATH:~/.scripts/
export PATH=$PATH:~/.local/bin/
export PATH=$PATH:~/.poetry/bin/
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

/usr/bin/setxkbmap -option "ctrl:swapcaps"
xmodmap -e "keycode 23 = Alt_L"
xmodmap -e "keycode 64 = grave asciitilde"
xmodmap -e "keycode 49 = Tab"
# end 

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes


export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias cls='printf "\033[2J\033[H\033[3J"'
alias python='python3'
alias randname='python3 ~/.scripts/namesgenerator.py'
alias zone='python3 ~/.dotfiles/.scripts/zone.py'
alias dotsync='rsync -avzPR $(cat $HOME/.dotfiles/.dotlist) $HOME/.dotfiles/'
#alias clk='kitty -o font_size=20 -e tty-clock -s -c -C 4 -t -f %d-%m-%Y &'
alias man='man "$1" | vim -'
alias r='ranger'
alias pi='ipython3'
alias bat='batcat --theme TwoDark'
alias fd='fdfind'
alias ll='exa -alF'
alias ls='exa'
alias svim='sudo vim'

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

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

#. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
