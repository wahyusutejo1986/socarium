#!/bin/bash

install_wazuh() {
    echo "🚀 Installing Wazuh..."

    # Check if necessary tools are installed
    command -v git >/dev/null 2>&1 || { echo "Git is required but not installed. Exiting..."; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Exiting..."; exi>
    local BASE_DIR="/opt/socarium"
    local WAZUH_REPO="https://github.com/wazuh/wazuh-docker.git -b v4.9.2"

    # Create directory with proper permissions (if not exists)
    sudo mkdir -p $BASE_DIR
    sudo chown -R $USER:$USER $BASE_DIR

    # Clone Wazuh repository
    git clone $WAZUH_REPO $BASE_DIR/wazuh-docker || { echo "Error cloning Wazuh repository. Exiting..."; exit 1; }

    # Navigate to the directory
    cd $BASE_DIR/wazuh-docker/single-node || { echo "Failed to change to Wazuh directory. Exiting..."; exit 1; }

    # Start Wazuh containers
    sudo docker-compose up -d || { echo "Failed to start Wazuh containers. Exiting..."; exit 1; }

    cd - || { echo "Failed to return to the original directory. Exiting..."; exit 1; }