#!/bin/bash

set -e  # Exit on error

# Load configuration
CONFIG_FILE="./config/config.cfg"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file $CONFIG_FILE not found! Exiting."
    exit 1
fi

# get directory where this script install_all.sh executed
BASE_DIR=$(pwd)

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and ensure container images, volumes, and containers are healthy
ensure_container_health() {
    local service_name=$1
    local compose_file=$2

    echo "Checking health of $service_name..."
    if [ -z "$(docker images -q "$service_name")" ]; then
        echo "$service_name image not found. Building..."
        docker-compose -f "$compose_file" build
    fi

    if [ -z "$(docker volume ls | grep "$service_name")" ]; then
        echo "$service_name volume not found. Creating..."
        docker-compose -f "$compose_file" up -d
    fi

    if [ -z "$(docker ps -q -f name="$service_name")" ]; then
        echo "$service_name container not running. Starting..."
        docker-compose -f "$compose_file" up -d
    else
        echo "$service_name container is already running."
    fi
}

#Directory mapping, please check if the project name move to socarium
SOC_DIR="/home/$(logname)/socarium"

# Check and create Docker network socarium-network if it doesn't exist
if sudo docker network ls | grep "socarium-network"; then
    echo "Docker network 'socarium-network' already exists. Skipping creation."
else
    echo "Creating Docker network 'socarium-network'..."
    sudo docker network create socarium-network
fi

git config --global http.postBuffer 157286400
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

    # Add socarium-network to docker-compose.yml
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

# DFIR IRIS installation
echo "Installing DFIR IRIS..."
if [ ! -d "iris-web" ]; then
    git clone https://github.com/dfir-iris/iris-web.git
    cd iris-web
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

# Shuffle installation
echo "Installing Shuffle..."
if [ ! -d "Shuffle" ]; then
    git clone https://github.com/Shuffle/Shuffle.git
    cd Shuffle
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

# MISP installation
echo "Installing MISP..."
if [ ! -d "misp-docker" ]; then
    # clone official misp repository latest version
    git clone https://github.com/MISP/misp-docker.git
    #change directory to misp-docker after clone success
    cd misp-docker
    #copy template.env to .env
    cp template.env .env
    # Add value for variable BASE_URL=https://localhost:10443/
    sed -i 's|^BASE_URL=.*|BASE_URL=https://'"$MISP_REDIRECT_URL:$MISP_HTTPS_PORT"'|' .env

    # Prevent port conflict with other platforms to 8181 for http and 10443 for https
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

#Velociraptor installation
echo "Installing Velociraptor..."
    cd "$SOC_DIR/modules/velociraptor"
    # Add Velociraptor-specific deployment steps here
    sudo docker-compose up -d
    echo "Velociraptor deployed successfully."
    #cd $SOC_DIR
    echo "Setup API file Integration DFIR IRIS"
    sleep 10  # Check system 10 seconds
    cd $SOC_DIR/modules/velociraptor/velociraptor
    sudo ./velociraptor --config server.config.yaml config api_client --name admin --role administrator api.config.yaml
    sudo cp api.config.yaml $SOC_DIR/iris-web/docker/api.config.yaml
    echo "Restart DFIR IRIS..."
    cd $SOC_DIR/iris-web
    sudo docker-compose down
    sudo docker-compose up -d
    echo "Integration Velociraptor - DFIR-IRIS deployed successfully."
    cd $SOC_DIR
#}

# Summary
echo "Installation completed for:
- Wazuh
- DFIR IRIS
- Shuffle
- MISP
- Velociraptor"

# Tips
echo "Ensure all services are running properly. Use 'docker ps' to check containers or refer to individual documentation for further configurations."
