#!/bin/bash

set -e  # Exit on error

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

# get directory where this script install_all.sh executed
BASE_DIR=$(pwd)

SOC_DIR="/home/$(logname)/socarium"

cd "$SOC_DIR"

# DFIR IRIS installation
echo "Installing DFIR IRIS..."
if [ ! -d "iris-web" ]; then
    git clone https://github.com/dfir-iris/iris-web.git
    cd $SOC_DIR/iris-web
    # switch to stable version v2.4.19
    git checkout v2.4.19

    # Create the socarium-network if it doesn't exist
    echo "Ensuring socarium-network exists..."
    if ! sudo docker network ls | grep "socarium-network"; then
        echo "Creating external network: socarium-network"
        sudo docker network create socarium-network
    else
        echo "Network socarium-network already exists."
    fi
    # Rename env.model to .env
    cp $SOC_DIR/modules/iris-web/.env.model .env
    cp $SOC_DIR/modules/iris-web/docker-compose.yml docker-compose.yml
    cp $SOC_DIR/modules/iris-web/docker-compose.base.yml docker-compose.base.yml
    cp $SOC_DIR/modules/iris-web/docker-compose.dev.yml docker-compose.dev.yml
    sudo docker-compose build
    sudo docker-compose up -d
    cd "$SOC_DIR"
else
    echo "DFIR IRIS already installed. Checking health..."
    #ensure_container_health "dfir-iris" "iris-web/docker-compose.yml"
    sudo docker ps --filter "name=irisweb"
fi
