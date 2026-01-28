
#!/bin/bash
set -euo pipefail

# generated setup script for profile: macos
# distro: darwin, arch: aarch64

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

TOOLS_TO_INSTALL=()
INSTALL_ALL=false

declare -A TOOL_FUNCTIONS
TOOL_FUNCTIONS[curl]='true'
TOOL_FUNCTIONS[tar]='true'
TOOL_FUNCTIONS[python]='curl -LsSf https://astral.sh/uv/0.7.9/install.sh | sh && uv python install 3.11 3.13'
TOOL_FUNCTIONS[node]='curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \ export NVM_DIR=$HOME/.nvm && \ source $NVM_DIR/nvm.sh && nvm install 22'
TOOL_FUNCTIONS[rust]='curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path'
TOOL_FUNCTIONS[go]='curl -LO https://go.dev/dl/go1.23.9.darwin-arm64.tar.gz && \ sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.9.darwin-arm64.tar.gz && \ rm go1.23.9.darwin-arm64.tar.gz && \ echo '"'"'export PATH=$PATH:/usr/local/go/bin'"'"' >> $HOME/.bashrc'
TOOL_FUNCTIONS[unzip]='true'
TOOL_FUNCTIONS[zip]='true'
TOOL_FUNCTIONS[sdkman]='curl -s "https://get.sdkman.io" | bash'
TOOL_FUNCTIONS[git]='true'
TOOL_FUNCTIONS[dotsync]='curl -L https://github.com/neelabalan/tools/releases/download/dotsync-v0.0.2/dotsync-darwin-aarch64.tar.gz | tar xz && mv dotsync $HOME/.local/bin/'
TOOL_FUNCTIONS[dotfiles]='mkdir -p $(dirname dotsync.json) && cp dotsync.json dotsync.json && dotsync init --config $HOME/dotsync.json && dotsync setup --profile macos'
TOOL_FUNCTIONS[neovim]='curl -LO https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-macos-arm64.tar.gz && \ mkdir -p $HOME/.local/nvim && tar -C $HOME/.local/nvim -xzf nvim-macos-arm64.tar.gz --strip-components=1 && \ ln -sf $HOME/.local/nvim/bin/nvim $HOME/.local/bin/nvim && \ rm nvim-macos-arm64.tar.gz && nvim --headless "+Lazy! sync" +qa'
TOOL_FUNCTIONS[starship]='curl -sS https://starship.rs/install.sh | sh -s -- -y && mkdir -p $HOME/.config'
TOOL_FUNCTIONS[fzf]='curl -LO https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-darwin_arm64.tar.gz && \ tar -xzf fzf-0.56.3-darwin_arm64.tar.gz && \ mv fzf $HOME/.local/bin/ && rm fzf-0.56.3-darwin_arm64.tar.gz'
TOOL_FUNCTIONS[ripgrep]='curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-aarch64-apple-darwin.tar.gz && \ tar -xzf ripgrep-14.1.1-aarch64-apple-darwin.tar.gz && \ mv ripgrep-14.1.1-aarch64-apple-darwin/rg $HOME/.local/bin/ && \ rm -rf ripgrep-14.1.1-aarch64-apple-darwin*'
TOOL_FUNCTIONS[tokei]='curl -LO https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-aarch64-apple-darwin.tar.gz && \ tar -xzf tokei-aarch64-apple-darwin.tar.gz && \ mv tokei $HOME/.local/bin/ && rm tokei-aarch64-apple-darwin.tar.gz'
TOOL_FUNCTIONS[eza]='curl -L https://github.com/eza-community/eza/releases/download/v0.21.1/eza_aarch64-apple-darwin.tar.gz | tar -xz -C /tmp && \ mv /tmp/eza $HOME/.local/bin/'
TOOL_FUNCTIONS[bat]='curl -LO https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-aarch64-apple-darwin.tar.gz && \ tar -xzf bat-v0.24.0-aarch64-apple-darwin.tar.gz && \ mv bat-v0.24.0-aarch64-apple-darwin/bat $HOME/.local/bin/ && \ rm -rf bat-v0.24.0-aarch64-apple-darwin*'
TOOL_FUNCTIONS[fd]='curl -LO https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-aarch64-apple-darwin.tar.gz && \ tar -xzf fd-v10.2.0-aarch64-apple-darwin.tar.gz && \ mv fd-v10.2.0-aarch64-apple-darwin/fd $HOME/.local/bin/ && \ rm -rf fd-v10.2.0-aarch64-apple-darwin*'
TOOL_FUNCTIONS[btop]='curl -LO https://github.com/aristocratos/btop/releases/download/v1.4.0/btop-aarch64-macos.tbz && \ tar -xjf btop-aarch64-macos.tbz && \ mv btop/bin/btop $HOME/.local/bin/ && \ rm -rf btop btop-aarch64-macos.tbz'
TOOL_FUNCTIONS[age]='curl -LO https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-darwin-arm64.tar.gz && \ tar -xzf age-v1.2.0-darwin-arm64.tar.gz && \ mv age/age age/age-keygen $HOME/.local/bin/ && \ rm -rf age age-v1.2.0-darwin-arm64.tar.gz'
TOOL_FUNCTIONS[jq]='curl -LO https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-macos-arm64 && \ chmod +x jq-macos-arm64 && mv jq-macos-arm64 $HOME/.local/bin/jq'
TOOL_FUNCTIONS[yq]='curl -LO https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_darwin_arm64 && \ chmod +x yq_darwin_arm64 && mv yq_darwin_arm64 $HOME/.local/bin/yq'
TOOL_FUNCTIONS[helm]='curl -LO https://get.helm.sh/helm-v3.16.3-darwin-arm64.tar.gz && \ tar -xzf helm-v3.16.3-darwin-arm64.tar.gz && \ mv darwin-arm64/helm $HOME/.local/bin/ && \ rm -rf darwin-arm64 helm-v3.16.3-darwin-arm64.tar.gz'
TOOL_FUNCTIONS[hurl]='curl -LO https://github.com/Orange-OpenSource/hurl/releases/download/5.0.1/hurl-5.0.1-aarch64-apple-darwin.tar.gz && \ tar -xzf hurl-5.0.1-aarch64-apple-darwin.tar.gz && \ mv hurl-5.0.1-aarch64-apple-darwin/bin/hurl $HOME/.local/bin/ && \ rm -rf hurl-5.0.1-aarch64-apple-darwin*'
TOOL_FUNCTIONS[zoxide]='curl -LO https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.6/zoxide-0.9.6-aarch64-apple-darwin.tar.gz && \ tar -xzf zoxide-0.9.6-aarch64-apple-darwin.tar.gz && \ mv zoxide $HOME/.local/bin/ && \ rm zoxide-0.9.6-aarch64-apple-darwin.tar.gz'
TOOL_FUNCTIONS[yazi]='curl -LO https://github.com/sxyazi/yazi/releases/download/v0.4.2/yazi-aarch64-apple-darwin.zip && \ unzip -o yazi-aarch64-apple-darwin.zip && \ mv yazi-aarch64-apple-darwin/yazi $HOME/.local/bin/ && \ rm -rf yazi-aarch64-apple-darwin*'
TOOL_FUNCTIONS[typst]='curl -LO https://github.com/typst/typst/releases/download/v0.12.0/typst-aarch64-apple-darwin.tar.xz && \ tar -xJf typst-aarch64-apple-darwin.tar.xz && \ mv typst-aarch64-apple-darwin/typst $HOME/.local/bin/ && \ rm -rf typst-aarch64-apple-darwin*'
TOOL_FUNCTIONS[tree-sitter]='curl -LO https://github.com/tree-sitter/tree-sitter/releases/download/v0.24.5/tree-sitter-macos-arm64.gz && \ gunzip tree-sitter-macos-arm64.gz && \ chmod +x tree-sitter-macos-arm64 && \ mv tree-sitter-macos-arm64 $HOME/.local/bin/tree-sitter'
TOOL_FUNCTIONS[kubectl]='curl -LO https://dl.k8s.io/release/v1.33.1/bin/darwin/arm64/kubectl && \ chmod +x kubectl && mv kubectl $HOME/.local/bin/kubectl'
TOOL_FUNCTIONS[ipython]='uv tool install --python 3.11 ipython'
TOOL_FUNCTIONS[ranger]='uv tool install ranger-fm'

ALL_TOOLS=("curl" "tar" "python" "node" "rust" "go" "unzip" "zip" "sdkman" "git" "dotsync" "dotfiles" "neovim" "starship" "fzf" "ripgrep" "tokei" "eza" "bat" "fd" "btop" "age" "jq" "yq" "helm" "hurl" "zoxide" "yazi" "typst" "tree-sitter" "kubectl" "ipython" "ranger")

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
