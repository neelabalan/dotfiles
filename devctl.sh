#!/bin/bash

# devctl.sh - Development Environment Control Script
# Usage: ./devctl.sh [MODE] [OPTIONS]
# Modes: build, run, refresh, interactive

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVENV_DIR="$SCRIPT_DIR"
IMAGE_NAME="dotfiles-dev"
CONTAINER_NAME="dotfiles-container"
SSH_COPY=false
GITCONFIG_COPY=false
VOLUME_MOUNT=false
HOME_MOUNT_PATH="$HOME"
INTERACTIVE_MODE=false
REFRESH_DOCKERFILE=false

# Available devenv configurations
declare -A DEVENVS=(
    ["deb-x86_64"]="Dockerfile.deb.x86_64"
    ["rpm-x86_64"]="Dockerfile.rpm.x86_64"
    ["rpm-aarch64"]="Dockerfile.rpm.aarch64"
)

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [MODE] [OPTIONS]

MODES:
    build       Build the Docker image
    run         Run the container
    refresh     Refresh Dockerfile using envcraft
    interactive Interactive mode with prompts

OPTIONS:
    -e, --env ENV           Development environment to use (deb-x86_64, rpm-x86_64, rpm-aarch64)
    -s, --ssh               Copy SSH keys from home directory
    -g, --gitconfig         Copy .gitconfig from home directory
    -v, --volume            Mount home directory as volume
    -p, --path PATH         Custom path for home directory mounting
    -n, --name NAME         Container name (default: dotfiles-container)
    -i, --image NAME        Image name (default: dotfiles-dev)
    -h, --help              Show this help message

EXAMPLES:
    $0 build --env rpm-x86_64
    $0 run --env deb-x86_64 --ssh --gitconfig --volume
    $0 refresh --env rpm-aarch64
    $0 interactive
EOF
}

# List available devenvs
list_devenvs() {
    log "Available development environments:"
    for key in "${!DEVENVS[@]}"; do
        echo "  - $key (${DEVENVS[$key]})"
    done
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
    fi
}

# Check if envcraft is available
check_envcraft() {
    if ! command -v envcraft &> /dev/null; then
        error "envcraft is not installed. Please install it first."
    fi
}

# Refresh Dockerfile using envcraft
refresh_dockerfile() {
    local env=$1
    check_envcraft
    
    if [[ -z "${DEVENVS[$env]:-}" ]]; then
        error "Invalid environment: $env"
    fi
    
    log "Refreshing Dockerfile for $env using envcraft..."
    cd "$PROJECT_ROOT"
    envcraft --env "$env" --refresh
    log "Dockerfile refreshed successfully"
}

# Build Docker image
build_image() {
    local env=$1
    local dockerfile="${DEVENVS[$env]:-}"
    
    if [[ -z "$dockerfile" ]]; then
        error "Invalid environment: $env"
    fi
    
    log "Building Docker image for $env..."
    cd "$DEVENV_DIR"
    
    docker build -f "$dockerfile" -t "$IMAGE_NAME:$env" .
    
    log "Image built successfully: $IMAGE_NAME:$env"
}

# Interactive prompts
interactive_prompts() {
    log "Interactive mode activated"
    
    # Select environment
    list_devenvs
    read -p "Select development environment: " SELECTED_ENV
    
    if [[ -z "${DEVENVS[$SELECTED_ENV]:-}" ]]; then
        error "Invalid environment selected"
    fi
    
    # SSH copy
    read -p "Copy SSH keys from home directory? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && SSH_COPY=true
    
    # Git config copy
    read -p "Copy .gitconfig from home directory? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && GITCONFIG_COPY=true
    
    # Volume mount
    read -p "Mount home directory as volume? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && VOLUME_MOUNT=true
    
    # Custom home path
    if [[ "$VOLUME_MOUNT" == true ]]; then
        read -p "Custom path for home directory (leave empty for $HOME): " CUSTOM_PATH
        [[ -n "$CUSTOM_PATH" ]] && HOME_MOUNT_PATH="$CUSTOM_PATH"
    fi
    
    echo
    log "Configuration summary:"
    echo "  Environment: $SELECTED_ENV"
    echo "  SSH copy: $SSH_COPY"
    echo "  Git config copy: $GITCONFIG_COPY"
    echo "  Volume mount: $VOLUME_MOUNT"
    [[ "$VOLUME_MOUNT" == true ]] && echo "  Mount path: $HOME_MOUNT_PATH"
    
    read -p "Proceed with these settings? (y/n): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && error "Aborted by user"
    
    # Build and run
    refresh_dockerfile "$SELECTED_ENV"
    build_image "$SELECTED_ENV"
    run_container "$SELECTED_ENV"
}

# Run Docker container
run_container() {
    local env=$1
    local dockerfile="${DEVENVS[$env]:-}"
    
    log "Starting container: $CONTAINER_NAME"
    
    # Prepare volume mounts
    local volume_args=""
    if [[ "$VOLUME_MOUNT" == true ]]; then
        volume_args="-v \"$HOME_MOUNT_PATH\":/home/blue/host"
    fi
    
    # Prepare copy commands
    local copy_commands=""
    if [[ "$SSH_COPY" == true && -d "$HOME/.ssh" ]]; then
        copy_commands="$copy_commands && cp -r /home/blue/host/.ssh /home/blue/.ssh && chmod 700 /home/blue/.ssh && chmod 600 /home/blue/.ssh/*"
    fi
    
    if [[ "$GITCONFIG_COPY" == true && -f "$HOME/.gitconfig" ]]; then
        copy_commands="$copy_commands && cp /home/blue/host/.gitconfig /home/blue/.gitconfig"
    fi
    
    # Build run command
    local run_cmd="docker run -it --name $CONTAINER_NAME"
    
    if [[ -n "$volume_args" ]]; then
        run_cmd="$run_cmd $volume_args"
    fi
    
    if [[ -n "$copy_commands" ]]; then
        run_cmd="$run_cmd --entrypoint /bin/bash $IMAGE_NAME:$env -c \"$copy_commands && exec bash\""
    else
        run_cmd="$run_cmd $IMAGE_NAME:$env"
    fi
    
    log "Executing: $run_cmd"
    eval "$run_cmd"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            build|run|refresh|interactive)
                MODE="$1"
                shift
                ;;
            -e|--env)
                SELECTED_ENV="$2"
                shift 2
                ;;
            -s|--ssh)
                SSH_COPY=true
                shift
                ;;
            -g|--gitconfig)
                GITCONFIG_COPY=true
                shift
                ;;
            -v|--volume)
                VOLUME_MOUNT=true
                shift
                ;;
            -p|--path)
                HOME_MOUNT_PATH="$2"
                VOLUME_MOUNT=true
                shift 2
                ;;
            -n|--name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            -i|--image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Main function
main() {
    log "Development Environment Control Script"
    log "======================================"
    
    check_docker
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    parse_args "$@"
    
    case "${MODE:-}" in
        build)
            if [[ -z "${SELECTED_ENV:-}" ]]; then
                error "Environment must be specified for build mode"
            fi
            build_image "$SELECTED_ENV"
            ;;
        run)
            if [[ -z "${SELECTED_ENV:-}" ]]; then
                error "Environment must be specified for run mode"
            fi
            run_container "$SELECTED_ENV"
            ;;
        refresh)
            if [[ -z "${SELECTED_ENV:-}" ]]; then
                error "Environment must be specified for refresh mode"
            fi
            refresh_dockerfile "$SELECTED_ENV"
            ;;
        interactive)
            INTERACTIVE_MODE=true
            interactive_prompts
            ;;
        *)
            error "Invalid mode: ${MODE:-}. Use -h for help"
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
