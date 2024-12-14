#!/bin/bash

install_misp() {
    echo "🚀 Installing MISP..."
    local BASE_DIR="/opt/security-suite"
    local MISP_REPO="https://github.com/MISP/misp-docker.git"
    git clone $MISP_REPO $BASE_DIR/MISP || error_handler "Cloning MISP Repository"
    cd $BASE_DIR/MISP
    cp template.env .env
    docker compose pull
    docker compose up -d || error_handler "Starting MISP Containers"
    cd -
}
