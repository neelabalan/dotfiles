
#!/bin/bash

function init {
    # File copy for init
    mkdir -p $(dirname '$HOME/')
    cp .bashrc '$HOME/'
    # Setup for init
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y vim curl git build-essential make
}

function python {
    # Preparation for python
    sudo apt install -y \
    curl \
    gcc \
    libbz2-dev \
    libev-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncurses-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    make \
    tk-dev \
    wget \
    zlib1g-dev \
    ncdu

    # Setup for python
    curl -fsSL https://pyenv.run | bash
    eval "$(pyenv init -)" && pyenv install 3.11 && pyenv install 3.10 && pyenv global 3.11
    curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    pyenv exec python3.11 get-pip.py
    rm get-pip.py
    # Validation for python
    command -v pyenv --version >/dev/null 2>&1 && \
            command -v pyenv exec python3.10 --version >/dev/null 2>&1 &&  \
            command -v pyenv exec python3.11 --version >/dev/null 2>&1
}

function starship {
    # Preparation for starship
    sudo apt install -y curl
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
    sudo apt install -y curl
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
    sudo apt install -y tar
    # Setup for tools
    sudo apt install -y ranger fzf ripgrep
    mkdir -p ~/.local/bin && curl -L "https://github.com/eza-community/eza/releases/download/v0.21.1/eza_x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /tmp && mv /tmp/eza ~/.local/bin/
    pyenv exec python3.11 -m pip install ipython
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

function ssh {
    # Preparation for ssh
    sudo apt install -y openssh-server
    # Setup for ssh
    sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
    sudo ssh-keygen -A
}

function optional {
    # Setup for optional
    sudo apt install -y procps iproute2
}

function go {
    # Preparation for go
    sudo apt install -y curl
    # Setup for go
    GO_VERSION=1.22.4
    curl -LO https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
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

