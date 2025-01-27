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

SOC_DIR="/home/$(logname)/soc"

cd "$SOC_DIR"

# Shuffle installation
echo "Installing Shuffle..."
if [ ! -d "Shuffle" ]; then
    git clone https://github.com/Shuffle/Shuffle.git
    cd $SOC_DIR/Shuffle
    # switch to stable version v1.4.2
    git checkout v1.4.2
    #check if directory shuffle-database exist
    if [ ! -d "shuffle-database" ]; then
        #create directory shuffle-database if not exist
        mkdir shuffle-database
    fi

    # Check if the user 'opensearch' exists
    if id "opensearch" &>/dev/null; then
        echo "User 'opensearch' already exists. Skipping creation."
    else
        echo "User 'opensearch' does not exist. Creating it now..."
        sudo useradd -m -s /bin/bash opensearch
        echo "User 'opensearch' created successfully."
    fi

    sudo chown -R 1000:1000 shuffle-database
    sudo swapoff -a
    sudo sysctl -w vm.max_map_count=262144

    # Create the socarium-network if it doesn't exist
    echo "Ensuring socarium-network exists..."
    if ! sudo docker network ls | grep "socarium-network"; then
        echo "Creating external network: socarium-network"
        sudo docker network create socarium-network
    else
        echo "Network socarium-network already exists."
    fi
    cp $SOC_DIR/modules/shuffle/docker-compose.yml docker-compose.yml
    sudo docker compose up -d
    cd "$SOC_DIR"
else
    echo "Shuffle already installed. Checking health..."
    #ensure_container_health "shuffle" "Shuffle/docker-compose.yml"
    sudo docker ps --filter "name=shuffle"
fi
