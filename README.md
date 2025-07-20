# dotfiles

no `yadm` no `dotdrop`

just 
```bash
alias dotsync='rsync -avzPR $(cat .dotlist) $HOME/.dotfiles/'
```


`python3.11 envcraft.py --arch=aarch64 --mode=docker`

`python3.11 envcraft.py --arch=x86_64 --mode=docker`