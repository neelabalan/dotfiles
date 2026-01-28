
#!/bin/bash
set -euo pipefail

# generated setup script for profile: ws-deb
# distro: debian, arch: x86_64

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[info]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $1"; }
log_error() { echo -e "${RED}[error]${NC} $1" >&2; }

# ensure local bin directory exists
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# use temp directory for downloads
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT
cd "$TMPDIR"

TOOLS_TO_INSTALL=()
INSTALL_ALL=false

declare -A TOOL_FUNCTIONS
TOOL_FUNCTIONS[curl]='sudo apt install -y curl'
TOOL_FUNCTIONS[tar]='sudo apt install -y tar'
TOOL_FUNCTIONS[python]='curl -LsSf https://astral.sh/uv/0.7.9/install.sh | sh && uv python install 3.11 3.13'
TOOL_FUNCTIONS[node]='curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \
                    export NVM_DIR=$HOME/.nvm && \
                    source $NVM_DIR/nvm.sh && nvm install 22'
TOOL_FUNCTIONS[rust]='curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path'
TOOL_FUNCTIONS[go]='curl -LO https://go.dev/dl/go1.23.9.linux-amd64.tar.gz && \
                    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.9.linux-amd64.tar.gz && \
                    rm go1.23.9.linux-amd64.tar.gz && \
                    echo '"'"'export PATH=$PATH:/usr/local/go/bin'"'"' >> $HOME/.bashrc'
TOOL_FUNCTIONS[unzip]='sudo apt install -y unzip'
TOOL_FUNCTIONS[zip]='sudo apt install -y zip'
TOOL_FUNCTIONS[sdkman]='curl -s "https://get.sdkman.io" | bash'
TOOL_FUNCTIONS[git]='sudo apt install -y git'
TOOL_FUNCTIONS[dotsync]='curl -L https://github.com/neelabalan/tools/releases/download/dotsync-v0.0.2/dotsync-linux-x86_64.tar.gz | tar xz && mv dotsync $HOME/.local/bin/'
TOOL_FUNCTIONS[dotfiles]='mkdir -p $(dirname dotsync.json) && cp dotsync.json dotsync.json && dotsync init --config $HOME/dotsync.json && dotsync setup --profile ws-deb'
TOOL_FUNCTIONS[neovim]='curl -LO https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz && \
                    mkdir -p $HOME/.local/nvim && tar -C $HOME/.local/nvim -xzf nvim-linux-x86_64.tar.gz --strip-components=1 && \
                    ln -sf $HOME/.local/nvim/bin/nvim $HOME/.local/bin/nvim && \
                    rm nvim-linux-x86_64.tar.gz && nvim --headless "+Lazy! sync" +qa'
TOOL_FUNCTIONS[starship]='curl -sS https://starship.rs/install.sh | sh -s -- -y && mkdir -p $HOME/.config'
TOOL_FUNCTIONS[fzf]='curl -LO https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-linux_amd64.tar.gz && \
                    tar -xzf fzf-0.56.3-linux_amd64.tar.gz && \
                    mv fzf $HOME/.local/bin/ && rm fzf-0.56.3-linux_amd64.tar.gz'
TOOL_FUNCTIONS[ripgrep]='curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz && \
                    tar -xzf ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz && \
                    mv ripgrep-14.1.1-x86_64-unknown-linux-musl/rg $HOME/.local/bin/ && \
                    rm -rf ripgrep-14.1.1-x86_64-unknown-linux-musl*'
TOOL_FUNCTIONS[tokei]='curl -LO https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-x86_64-unknown-linux-gnu.tar.gz && \
                    tar -xzf tokei-x86_64-unknown-linux-gnu.tar.gz && \
                    mv tokei $HOME/.local/bin/ && rm tokei-x86_64-unknown-linux-gnu.tar.gz'
TOOL_FUNCTIONS[eza]='curl -L https://github.com/eza-community/eza/releases/download/v0.21.1/eza_x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /tmp && \
                    mv /tmp/eza $HOME/.local/bin/'
TOOL_FUNCTIONS[kubectl]='curl -LO https://dl.k8s.io/release/v1.33.1/bin/linux/amd64/kubectl && \
                    chmod +x kubectl && mv kubectl $HOME/.local/bin/kubectl'
TOOL_FUNCTIONS[ipython]='uv tool install --python 3.11 ipython'
TOOL_FUNCTIONS[ranger]='uv tool install ranger-fm'
TOOL_FUNCTIONS[sysutils]='sudo apt install -y procps iproute2'
TOOL_FUNCTIONS[openssh]='sudo apt install -y openssh-server'
TOOL_FUNCTIONS[ssh]='sudo sed -i '"'"'s/^#*PermitRootLogin.*/PermitRootLogin yes/'"'"' /etc/ssh/sshd_config && \
                    sudo sed -i '"'"'s/^#*PasswordAuthentication.*/PasswordAuthentication yes/'"'"' /etc/ssh/sshd_config && \
                    sudo sed -i '"'"'s/^#*UsePAM.*/UsePAM yes/'"'"' /etc/ssh/sshd_config && \
                    sudo ssh-keygen -A'
TOOL_FUNCTIONS[docker]='sudo install -m 0755 -d /etc/apt/keyrings && \
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
sudo chmod a+r /etc/apt/keyrings/docker.asc && \
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
sudo apt-get update -y && \
sudo apt-get install docker-ce-cli -y'

ALL_TOOLS=("curl" "tar" "python" "node" "rust" "go" "unzip" "zip" "sdkman" "git" "dotsync" "dotfiles" "neovim" "starship" "fzf" "ripgrep" "tokei" "eza" "kubectl" "ipython" "ranger" "sysutils" "openssh" "ssh" "docker")

print_usage() {
    echo "usage: $0 [options] [tool1 tool2 ...]"
    echo ""
    echo "options:"
    echo "  --all        install all tools"
    echo "  --list       list available tools"
    echo "  --help       show this help"
    echo ""
    echo "available tools:"
    for tool in "${!TOOL_FUNCTIONS[@]}"; do
        echo "  $tool"
    done | sort
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --list)
            echo "available tools:"
            for tool in "${!TOOL_FUNCTIONS[@]}"; do
                echo "  $tool"
            done | sort
            exit 0
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        -*)
            log_error "unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            TOOLS_TO_INSTALL+=("$1")
            shift
            ;;
    esac
done

if [[ "$INSTALL_ALL" == true ]]; then
    TOOLS_TO_INSTALL=("${ALL_TOOLS[@]}")
fi

if [[ ${#TOOLS_TO_INSTALL[@]} -eq 0 ]]; then
    print_usage
    exit 1
fi

for tool in "${TOOLS_TO_INSTALL[@]}"; do
    if [[ -n "${TOOL_FUNCTIONS[$tool]:-}" ]]; then
        log_info "installing $tool..."
        eval "${TOOL_FUNCTIONS[$tool]}"
        log_info "$tool installed"
    else
        log_error "unknown tool: $tool"
        exit 1
    fi
done

log_info "setup complete!"
