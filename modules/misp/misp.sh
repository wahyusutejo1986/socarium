#!/bin/bash

set -e  # Exit on error

# get directory where this script install_all.sh executed
BASE_DIR=$(pwd)

# Load configuration
script_dir=$(cd "$(dirname "$0")" && pwd)
parent_dir=$(dirname "$script_dir")
grandparent_dir=$(dirname "$parent_dir")
CONFIG_FILE="${grandparent_dir}/config/config.cfg"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file $CONFIG_FILE not found! Exiting."
    exit 1
fi

SOC_DIR="/home/$(logname)/soc"

cd "$SOC_DIR"

# MISP installation
echo "Installing MISP..."
if [ ! -d "misp-docker" ]; then
    # clone official misp repository latest version
    git clone https://github.com/MISP/misp-docker.git
    #change directory to misp-docker after clone success
    cd $SOC_DIR/misp-docker
    #copy template.env to .env
    cp template.env .env
    #add value for variable BASE_URL=https://localhost:10443/    
    sed -i 's|^BASE_URL=.*|BASE_URL=https://'"$MISP_REDIRECT_URL:$MISP_HTTPS_PORT"'|' .env
    #prevent port conflict with other platform to 8181 for http and 10443 for https
    sed -i 's|- "80:80"|- "8181:80"|g; s|- "443:443"|- "10443:443"|g' docker-compose.yml
    #pull image for faster deployment instead of build
    sudo docker-compose pull
    #running the containers
    sudo docker compose up -d
    cd "$SOC_DIR"
else
    echo "MISP already installed. Checking health..."
    #ensure_container_health "misp" "misp/docker-compose.yml"
    sudo docker ps --filter "name=misp"
fi
