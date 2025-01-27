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

# Wazuh installation
echo "Installing Wazuh..."
if [ ! -d "wazuh-docker" ]; then
    echo "Cloning Wazuh Docker repository..."
    git clone https://github.com/wazuh/wazuh-docker.git -b v4.9.2
    cd $SOC_DIR/wazuh-docker/single-node/

    sysctl -w vm.max_map_count=262144
    if grep -q "vm.max_map_count" /etc/sysctl.conf; then
        echo "Updating existing vm.max_map_count value in /etc/sysctl.conf..."
        sed -i 's/^vm\.max_map_count=.*/vm.max_map_count=262144/' /etc/sysctl.conf
    else
        echo "Adding vm.max_map_count to /etc/sysctl.conf..."
        echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    fi

    echo "Done. Current value of vm.max_map_count is:"
    sysctl vm.max_map_count

    # Create the socarium-network if it doesn't exist
    echo "Ensuring socarium-network exists..."
    if ! sudo docker network ls | grep "socarium-network"; then
        echo "Creating external network: socarium-network"
        sudo docker network create socarium-network
    else
        echo "Network socarium-network already exists."
    fi

    # Add config to docker
    cp $SOC_DIR/modules/wazuh/docker-compose.yml docker-compose.yml
    # Check and handle SSL certificates folder
    echo "Checking and preparing SSL certificates..."
    if [ -d "config/wazuh_indexer_ssl_certs" ]; then
        echo "Removing existing SSL certificates folder..."
        rm -rf config/wazuh_indexer_ssl_certs
    fi

    echo "Running certificate creation script..."
    sudo docker-compose -f generate-indexer-certs.yml run --rm generator

    echo "Starting Wazuh environment with Docker Compose..."
    sudo docker-compose up -d
    cd "$SOC_DIR"
else
    echo "Wazuh already installed."
    #ensure_container_health "wazuh" "wazuh-docker/single-node/docker-compose.yml"
    sudo docker ps --filter "name=wazuh"
fi
