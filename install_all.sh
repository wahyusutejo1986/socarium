#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get IP address of interface ens3
get_ip_address() {
    ip -o -4 addr list ens3 | awk '{print $4}' | cut -d'/' -f1
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

# Create /opt/soc directory if it doesn't exist
SOC_DIR="/opt/soc"
if [ ! -d "$SOC_DIR" ]; then
    echo "Creating directory $SOC_DIR..."
    sudo mkdir -p "$SOC_DIR"
else
    echo "Directory $SOC_DIR already exists."
fi

# Copy modules directory to /opt/soc if it doesn't already exist
MODULES_SRC="modules"
MODULES_DEST="$SOC_DIR/modules"
if [ ! -d "$MODULES_DEST" ]; then
    echo "Copying modules to $SOC_DIR..."
    sudo cp -r "$MODULES_SRC" "$MODULES_DEST"
else
    echo "Modules directory already exists in $SOC_DIR. Skipping copy."
fi

# Check and create Docker network socarium-network if it doesn't exist
if sudo docker network ls | grep "socarium-network"; then
    echo "Docker network 'socarium-network' already exists. Skipping creation."
else
    echo "Creating Docker network 'socarium-network'..."
    sudo docker network create socarium-network
fi

cd "$SOC_DIR"

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y

# Install common prerequisites
echo "Installing common prerequisites..."
for pkg in curl wget gnupg apt-transport-https unzip python3 python3-pip docker.io docker-compose git; do
    if ! command_exists "$pkg"; then
        echo "Installing $pkg..."
        sudo apt-get install -y "$pkg"
    else
        echo "$pkg is already installed. Skipping."
    fi
done

# Wazuh installation
echo "Installing Wazuh..."
if [ ! -d "wazuh-docker" ]; then
    echo "Cloning Wazuh Docker repository..."
    sudo git clone https://github.com/wazuh/wazuh-docker.git -b v4.9.2
    cd /opt/soc/wazuh-docker/single-node/

    echo "Setting max_map_count..."
    sudo sysctl -w vm.max_map_count=262144

    # Create the socarium-network if it doesn't exist
    echo "Ensuring socarium-network exists..."
    if ! sudo docker network ls | grep "socarium-network"; then
        echo "Creating external network: socarium-network"
        sudo docker network create socarium-network
    else
        echo "Network socarium-network already exists."
    fi

    # Add socarium-network to docker-compose.yml
    sudo cp /opt/soc/modules/wazuh/docker-compose.yml docker-compose.yml 
    # Check and handle SSL certificates folder
    echo "Checking and preparing SSL certificates..."
    if [ -d "config/wazuh_indexer_ssl_certs" ]; then
        echo "Removing existing SSL certificates folder..."
        sudo rm -rf config/wazuh_indexer_ssl_certs
    fi
    
    echo "Running certificate creation script..."
    sudo docker-compose -f generate-indexer-certs.yml run --rm generator

    echo "Starting Wazuh environment with Docker Compose..."
    sudo docker-compose up -d
    cd "$SOC_DIR"
else
    echo "Wazuh already installed."
    #ensure_container_health "wazuh" "wazuh-docker/single-node/docker-compose.yml"
fi

# DFIR IRIS installation
echo "Installing DFIR IRIS..."
if [ ! -d "iris-web" ]; then
    git clone https://github.com/dfir-iris/iris-web.git
    cd iris-web

    # Create the socarium-network if it doesn't exist
    echo "Ensuring socarium-network exists..."
    if ! sudo docker network ls | grep "socarium-network"; then
        echo "Creating external network: socarium-network"
        sudo docker network create socarium-network
    else
        echo "Network socarium-network already exists."
    fi
    # Rename env.model to .env
    sudo cp /opt/soc/modules/iris-web/.env.model .env
    sudo cp /opt/soc/modules/iris-web/docker-compose.yml docker-compose.yml 
    sudo cp /opt/soc/modules/iris-web/docker-compose.base.yml docker-compose.base.yml
    sudo cp /opt/soc/modules/iris-web/docker-compose.dev.yml docker-compose.dev.yml
    sudo docker-compose build
    sudo docker-compose up -d
    cd "$SOC_DIR"
else
    echo "DFIR IRIS already installed. Checking health..."
    #ensure_container_health "dfir-iris" "iris-web/docker-compose.yml"
fi

# Shuffle installation
echo "Installing Shuffle..."
if [ ! -d "Shuffle" ]; then
    git clone https://github.com/Shuffle/Shuffle.git
    cd Shuffle
    if [ ! -d "shuffle-database" ]; then
        mkdir shuffle-database
    fi
    sudo useradd opensearch
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
    sudo cp /opt/soc/modules/shuffle/docker-compose.yml docker-compose.yml
    sudo docker compose up -d
    cd "$SOC_DIR"
else
    echo "Shuffle already installed. Checking health..."
    #ensure_container_health "shuffle" "Shuffle/docker-compose.yml"
fi

# Summary
echo "Installation completed for:
- Wazuh
- DFIR IRIS
- Shuffle"

# Tips
echo "Ensure all services are running properly. Use 'docker ps' to check containers or refer to individual documentation for further configurations."
