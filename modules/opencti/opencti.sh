#!/bin/bash

install_opencti() {
    echo "🚀 Installing OpenCTI..."
    local BASE_DIR="/opt/security-suite"
    local OPENCTI_REPO="https://github.com/OpenCTI-Platform/docker.git"
    git clone $OPENCTI_REPO $BASE_DIR/opencti || error_handler "Cloning OpenCTI Repository"
    cd $BASE_DIR/opencti
    cp docker-compose.override.yml.example docker-compose.override.yml
    docker-compose up -d || error_handler "Starting OpenCTI Containers"
    cd -
}
