#!/bin/bash

is_container_running() {
    local container_id=$1
    docker inspect --format '{{.State.Running}}' "$container_id" 2>/dev/null | grep -q "true"
}

start_container_if_stopped() {
    local container_id=$1
    if ! is_container_running "$container_id"; then
        echo "Container $container_id is stopped. Starting it..."
        docker start "$container_id"
        sleep 3
    fi
}

# Better formatted container selection with improved preview
containers=$(docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}' | \
    fzf --height=50% --reverse --header-lines=1 \
        --preview='docker inspect --format "Container: {{.Name}}
ID: {{.Id}}
Image: {{.Config.Image}}
Status: {{.State.Status}}
Created: {{.Created}}
Ports: {{range $p, $conf := .NetworkSettings.Ports}}{{$p}} -> {{(index $conf 0).HostPort}}{{println}}{{end}}
Command: {{.Config.Cmd}}" {2}' \
        --preview-window=right:60%:wrap)

if [ -z "$containers" ]; then
    echo "No container selected"
    exit 0
fi

container_id=$(echo "$containers" | awk '{print $1}')
start_container_if_stopped "$container_id"
echo "Executing into container $container_id"
docker exec -it "$container_id" bash