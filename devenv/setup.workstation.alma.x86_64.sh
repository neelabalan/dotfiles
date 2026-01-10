
#!/bin/bash

function curl {
    # setup for curl
    sudo dnf install -y curl --skip-broken
}

function tar {
    # setup for tar
    sudo dnf install -y tar --skip-broken
}

function python {
    # setup for python
    curl -LsSf https://astral.sh/uv/0.7.9/install.sh | sh && uv python install 3.11 3.13
}

function node {
    # setup for node
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \
        export NVM_DIR=$HOME/.nvm && \
        source $NVM_DIR/nvm.sh && nvm install 22
}

function rust {
    # setup for rust
    curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path
}

function go {
    # setup for go
    curl -LO https://go.dev/dl/go1.23.9.linux-amd64.tar.gz && \
        sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.9.linux-amd64.tar.gz && \
        rm go1.23.9.linux-amd64.tar.gz && \
        echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc
}

function unzip {
    # setup for unzip
    sudo dnf install -y unzip --skip-broken
}

function zip {
    # setup for zip
    sudo dnf install -y zip --skip-broken
}

function sdkman {
    # setup for sdkman
    curl -s "https://get.sdkman.io" | bash
}

function neovim {
    # setup for neovim
    curl -LO https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz && \
        sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz && \
        sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim && \
        rm nvim-linux-x86_64.tar.gz
}

function starship {
    # setup for starship
    curl -sS https://starship.rs/install.sh | sh -s -- -y && mkdir -p $HOME/.config
}

function fzf {
    # setup for fzf
    curl -LO https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-linux_amd64.tar.gz && \
        tar -xzf fzf-0.56.3-linux_amd64.tar.gz && \
        sudo mv fzf /usr/local/bin/ && rm fzf-0.56.3-linux_amd64.tar.gz
}

function ripgrep {
    # setup for ripgrep
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz && \
        tar -xzf ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz && \
        sudo mv ripgrep-14.1.1-x86_64-unknown-linux-musl/rg /usr/local/bin/ && \
        rm -rf ripgrep-14.1.1-x86_64-unknown-linux-musl*
}

function tokei {
    # setup for tokei
    curl -LO https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-x86_64-unknown-linux-gnu.tar.gz && \
        tar -xzf tokei-x86_64-unknown-linux-gnu.tar.gz && \
        sudo mv tokei /usr/local/bin/ && rm tokei-x86_64-unknown-linux-gnu.tar.gz
}

function eza {
    # setup for eza
    curl -L https://github.com/eza-community/eza/releases/download/v0.21.1/eza_x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /tmp && \
        sudo mv /tmp/eza /usr/local/bin/
}

function kubectl {
    # setup for kubectl
    curl -LO https://dl.k8s.io/release/v1.33.1/bin/linux/amd64/kubectl && \
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
}

function ipython {
    # setup for ipython
    uv tool install --python 3.11 ipython
}

function ranger {
    # setup for ranger
    uv tool install ranger-fm
}

function sysutils {
    # setup for sysutils
    sudo dnf install -y procps iproute --skip-broken
}

function openssh {
    # setup for openssh
    sudo dnf install -y openssh-server --skip-broken
}

function ssh {
    # setup for ssh
    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
        sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
        sudo sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config && \
        sudo ssh-keygen -A
}

function docker {
    # setup for docker
    sudo dnf -y install dnf-plugins-core && \
        sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
        sudo dnf install -y docker-ce-cli
}

function git {
    # setup for git
    sudo dnf install -y git --skip-broken
}

function dotsync {
    # setup for dotsync
    curl -L https://github.com/neelabalan/tools/releases/download/dotsync-v0.0.2/dotsync-linux-x86_64.tar.gz | tar xz
    sudo mv dotsync /usr/local/bin/
}

function dotfiles {
    # file copy for dotfiles
    mkdir -p $(dirname dotsync.json)
    cp dotsync.json dotsync.json
    # setup for dotfiles
    dotsync init --config $HOME/dotsync.json
    dotsync setup --profile workstation
}



function install_deps() {
    echo "Installing base dependencies..."
    # This function can be customized to install any base dependencies
    # that are needed before running the individual tool functions
}

if [ "$1" == "--install" ]; then
    shift
    install_deps
    for tool in "$@"; do
        if declare -f "$tool" > /dev/null; then
            "$tool"
        else
            echo "Error: Unknown tool '$tool'"
            exit 1
        fi
    done
else
    echo "Usage: $0 --install tool1 tool2 ..."
    exit 1
fi

