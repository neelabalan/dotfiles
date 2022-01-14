# If not running interactively, don't do anything
export PATH=$PATH:~/.scripts/
export PATH=$PATH:~/.local/bin/
export PATH=$PATH:~/.poetry/bin/
#export PYTHONPATH=$HOME/.local/lib/python3.8/site-packages/
export CHEATCOLORS=true
export LIBVA_DRIVER_NAME=i965
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'
#python3 $HOME/stoic-quote/stoic_quote.py 

complete -d cd
bind TAB:menu-complete

VISUAL=vim; export VISUAL EDITOR=vim; export EDITOR
HISTCONTROL=ignoreboth
PROMPT_COMMAND='echo -en "\033]0; $("pwd") \a"'
# append to the history file, don't overwrite it
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

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# xmodmap setting
/usr/bin/setxkbmap -option "ctrl:swapcaps"
xmodmap -e "keycode 23 = Alt_L"
xmodmap -e "keycode 64 = grave asciitilde"
xmodmap -e "keycode 49 = Tab"
# end 

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes

__git_status() 
{
    STATUS=$(git status 2>/dev/null |
    awk '
    /^On branch / {printf($3)}
    /^You are currently rebasing/ {printf("rebasing %s", $6)}
    /^Initial commit/ {printf(" (init)")}
    /^Untracked files/ {printf("|+")}
    /^Changes not staged / {printf("|?")}
    /^Changes to be committed/ {printf("|*")}
    /^Your branch is ahead of/ {printf("|^")}
    ')
    if [ -n "$STATUS" ]; then
        echo -ne " [$STATUS]"
    fi
}
git_stash_size() 
{
  n=$( (git stash list 2> /dev/null || :) | wc -l )
  if [ $n -gt 0 ]; then
    echo -n " +$n"
  fi
}


txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset - Useful for avoiding color bleed


#__ps1_startline="\[$txtblu\]\u\[$txtcyn\]@\[$txtblu\]\h\[$txtwht\]__:\[$txtgrn\]\w \[$txtrst\]"
__ps1_startline="\[$txtgrn\]\w \[$txtrst\]"
__ps1_endline="\[$txtylw\]→ \[$txtrst\]"
export PS1="\n\n${__ps1_startline} \$(__git_status)\$(git_stash_size)\n ${__ps1_endline}"




# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias python='python3'
#alias tmt='python3 ~/code/github/tmt/tmt.py'
alias quo='python3 ~/code/github/quote/quote.py'
alias randname='python3 ~/.scripts/namesgenerator.py'
alias zone='python3 ~/.dotfiles/.scripts/zone.py'
alias py='python3'
alias cls='clear'
alias dotsync='rsync -avzPR $(cat $HOME/.dotfiles/.dotlist) $HOME/.dotfiles/'
alias pdf='ranger ~/pdf'
alias clk='kitty -o font_size=20 -e tty-clock -s -c -C 4 -t -f %d-%m-%Y &'
alias man='man "$1" | vim -'
alias r='ranger'
alias hs='ghci'
alias pi='ipython3'
alias bat='batcat --theme TwoDark'
alias fd='fdfind'
alias ll='exa -alF'
alias la='exa -A'
alias  l='exa -CF'
alias ls='exa'
alias tmux='tmux -u'
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


# pip bash completion start
_pip_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 ) )
}
complete -o default -F _pip_completion pip
# pip bash completion end


#---------------------------------------------------------------------------#
# 				commented code

export NOTESDIR="$HOME/notes"

prvu()
{
    fzf --preview 'batcat --theme ansi-dark --color "always" {}' $1
}
# opencode
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

md()
{
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
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
#sudo cryptsetup luksOpen /dev/sdb1 disk && sudo mount /dev/mapper/disk /media/user/disk
#upower -i /org/freedesktop/UPower/devices/battery_BAT0


. "$HOME/.cargo/env"



source /home/blue/.bash_completions/qn.sh

source /home/blue/.bash_completions/tmt.py.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
