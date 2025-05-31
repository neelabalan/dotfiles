
#!/bin/bash

function init {
    # File copy for init
    mkdir -p $(dirname '$HOME/')
    cp .bashrc '$HOME/'
    # Setup for init
    sudo dnf update -y
    sudo dnf install -y vim curl git make gcc --skip-broken
}

function python {
    # Setup for python
    curl -LsSf https://astral.sh/uv/install.sh | sh
    uv python install 3.11 3.13
}

function starship {
    # Preparation for starship
    sudo dnf install -y curl --skip-broken
    # File copy for starship
    mkdir -p $(dirname '$HOME/.config/')
    cp starship.toml '$HOME/.config/'
    # Setup for starship
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    mkdir -p $HOME/.config
    # Validation for starship
    command -v starship --version >/dev/null 2>&1
}

function node {
    # Preparation for node
    sudo dnf install -y curl --skip-broken
    # Setup for node
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \
            export NVM_DIR=$HOME/.nvm && \
            bash -c "source $NVM_DIR/nvm.sh && nvm install 22" 
}

function rust {
    # Setup for rust
    curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path
    # Validation for rust
    command -v rustc --version >/dev/null 2>&1
    command -v cargo -version >/dev/null 2>&1
}

function tools {
    # Preparation for tools
    sudo dnf install -y tar
    # Setup for tools
    sudo dnf install -y epel-release
    sudo dnf update -y
    sudo dnf install -y ranger fzf ripgrep
    mkdir -p ~/.local/bin && curl -L "https://github.com/eza-community/eza/releases/download/v0.21.1/eza_x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /tmp && mv /tmp/eza ~/.local/bin/
    uv tool install --python 3.11 ipython
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

function ssh {
    # Preparation for ssh
    sudo dnf install -y openssh-server
    # Setup for ssh
    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
    sudo ssh-keygen -A
}

function optional {
    # Setup for optional
    sudo dnf install -y procps iproute
}

function go {
    # Preparation for go
    sudo dnf install -y curl --skip-broken
    # Setup for go
    curl -LO https://go.dev/dl/go1.23.9.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.9.linux-amd64.tar.gz
    rm go1.23.9.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc
    source $HOME/.bashrc
    # Validation for go
    command -v go >/dev/null 2>&1
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

