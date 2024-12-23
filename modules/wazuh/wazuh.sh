#!/bin/bash

# Function to handle errors
#handle_error() {
#    echo "❌ $1. Exiting..."
#    exit 1
#}

# Function to check required tools
check_tools() {
    command -v git >/dev/null 2>&1 || handle_error "Git is required but not installed"
    command -v docker-compose >/dev/null 2>&1 || handle_error "Docker Compose is required but not installed"
    command -v docker >/dev/null 2>&1 || handle_error "Docker is required but not installed"
}

# Set vm.max_map_count temporarily
    sudo sysctl -w vm.max_map_count=262144 || handle_error "Failed to set vm.max_map_count temporarily"

# Function to ensure vm.max_map_count is set permanently
set_max_map_count() {
    # Check if the setting is already in /etc/sysctl.conf
    grep -q 'vm.max_map_count' /etc/sysctl.conf || {
        echo "Setting vm.max_map_count permanently..."
        # Append the setting to /etc/sysctl.conf
        echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf >/dev/null
        # Reload sysctl to apply changes
        sudo sysctl -p || handle_error "Failed to reload sysctl"
    }
}

# Ensure vm.max_map_count is set permanently
    set_max_map_count

install_wazuh() {
    echo "🚀 Installing Wazuh..."

    # Check if necessary tools are installed
    check_tools

    local BASE_DIR="/opt/socarium"
    local WAZUH_REPO="https://github.com/wazuh/wazuh-docker.git -b v4.9.2"

    # Create directory with proper permissions (if not exists)
    sudo mkdir -p $BASE_DIR || handle_error "Failed to create $BASE_DIR"
    sudo chown -R $USER:$USER $BASE_DIR || handle_error "Failed to set ownership for $BASE_DIR"

    # Clone Wazuh repository
    git clone $WAZUH_REPO $BASE_DIR/wazuh-docker || handle_error "Error cloning Wazuh repository"

    # Navigate to the directory
    cd $BASE_DIR/wazuh-docker/single-node || handle_error "Failed to change to Wazuh directory"

    # Generate self-signed certificate
    sudo docker-compose -f generate-indexer-certs.yml run --rm generator || handle_error "Failed to generate self-signed certificate"

    # Start Wazuh containers
    sudo docker-compose up -d || handle_error "Failed to start Wazuh containers"

    echo "✅ Wazuh installation completed successfully!"
    
    # Optional: Clean up unused Docker containers, volumes, and images
    # sudo docker system prune -f || handle_error "Failed to prune Docker system"
}
