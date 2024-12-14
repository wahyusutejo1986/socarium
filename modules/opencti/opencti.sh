#!/bin/bash

install_opencti() {
    echo "🚀 Installing OpenCTI..."
    local BASE_DIR="/opt/socarium"
    local OPENCTI_REPO="https://github.com/OpenCTI-Platform/docker.git"
    local SYSCTL_CONF="/etc/sysctl.conf"
    local PARAM="vm.max_map_count=1048575"

    # Clone the OpenCTI repository
    git clone $OPENCTI_REPO $BASE_DIR/opencti || error_handler "Cloning OpenCTI Repository"
    cd $BASE_DIR/opencti

    # Rename .env.sample to .env
    sudo mv .env.sample .env

    # Set vm.max_map_count temporarily
    echo "🔧 Setting vm.max_map_count temporarily..."
    sudo sysctl -w vm.max_map_count=1048575

    # Ensure vm.max_map_count is persistent
    if grep -q "^$PARAM" "$SYSCTL_CONF"; then
        echo "🔧 vm.max_map_count is already set in $SYSCTL_CONF. Skipping persistence step."
    else
        echo "🔧 Adding vm.max_map_count=1048575 to $SYSCTL_CONF for persistence..."
        echo "$PARAM" | sudo tee -a $SYSCTL_CONF > /dev/null
    fi

    # Start OpenCTI containers
    echo "🚀 Starting OpenCTI containers..."
    sudo docker-compose up -d || error_handler "Starting OpenCTI Containers"
    cd -
}

error_handler() {
    local MESSAGE=$1
    echo "❌ Error: $MESSAGE. Exiting."
    exit 1
}

