#!/bin/bash

install_wazuh() {
    echo "🚀 Installing Wazuh..."
    local BASE_DIR="/opt/socarium"
    local WAZUH_REPO="https://github.com/wazuh/wazuh-docker.git -b v4.9.2"
    git clone $WAZUH_REPO $BASE_DIR/wazuh-docker || error_handler "Cloning Wazuh Repository"
    cd $BASE_DIR/wazuh-docker/single-node
    sudo docker-compose up -d || error_handler "Starting Wazuh Containers"
    cd -
}
