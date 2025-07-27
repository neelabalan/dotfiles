#!/bin/bash

# fzf-man7.sh - Interactive man page browser using fzf and man7.org

set -euo pipefail

# cross-platform opener
case "$(uname -s)" in
    Darwin*)  OPENER="open" ;;
    Linux*)   OPENER="xdg-open" ;;
    *)        echo "Unsupported OS" >&2; exit 1 ;;
esac
# Base URL for man7.org
BASE_URL="https://man7.org/linux/man-pages"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-man7"
mkdir -p "$CACHE_DIR"

INDEX_FILE="$CACHE_DIR/man7_index.txt"

build_index() {
    echo "Building man page index from man7.org..." >&2
    
    curl -s "https://man7.org/linux/man-pages/dir_all_alphabetic.html" |
    sed -n 's/.*href="\([^"]*\.html\).*/\1/p' |
    grep -v '^index\|^../' |
    sed 's|\.html$||' |
    sort -u > "$INDEX_FILE"
    
    echo "Index built with $(wc -l < "$INDEX_FILE") man pages" >&2
}

# Function to search man pages
search_man_pages() {
    local search_term="${1:-}"
    
    # build index if it doesn't exist or is older than 7 days
    if [[ ! -f "$INDEX_FILE" ]] || [[ $(find "$INDEX_FILE" -mtime +7 2>/dev/null) ]]; then
        build_index
    fi
    
    local fzf_input
    if [[ -n "$search_term" ]]; then
        fzf_input=$(grep -i "$search_term" "$INDEX_FILE" || echo "No matches found")
    else
        fzf_input=$(cat "$INDEX_FILE")
    fi
    
    local selected
    selected=$(echo "$fzf_input" | fzf --prompt="Select man page: " --height=40% --reverse)
    
    if [[ -z "$selected" ]]; then
        echo "No selection made." >&2
        exit 1
    fi
    
    local url="$BASE_URL/$selected.html"
    
    echo "Opening: $url" >&2
    $OPENER "$url"
}

search_man_pages "$@"
