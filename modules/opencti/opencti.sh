#!/bin/bash

install_opencti() {
    echo "🚀 Installing OpenCTI..."
    local BASE_DIR="/opt/socarium"
    local OPENCTI_REPO="https://github.com/OpenCTI-Platform/docker.git"
    git clone $OPENCTI_REPO $BASE_DIR/opencti || error_handler "Cloning OpenCTI Repository"
    cd $BASE_DIR/opencti
    sudo mv .env.sample .env
    sudo docker-compose up -d || error_handler "Starting OpenCTI Containers"
    cd -
}
