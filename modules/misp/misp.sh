#!/bin/bash

install_misp() {
    echo "🚀 Installing MISP..."
    local BASE_DIR="/opt/socarium"
    local MISP_REPO="https://github.com/MISP/misp-docker.git"
    git clone $MISP_REPO $BASE_DIR/MISP || error_handler "Cloning MISP Repository"
    cd $BASE_DIR/MISP
    cp template.env .env
    sudo docker-compose pull
    sudo docker-compose up -d || error_handler "Starting MISP Containers"
    cd -
}
