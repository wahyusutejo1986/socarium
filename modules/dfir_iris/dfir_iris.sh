#!/bin/bash

install_dfir_iris() {
    echo "🚀 Installing DFIR IRIS..."
    local BASE_DIR="/opt/security-suite"
    local DFIR_REPO="https://github.com/dfir-iris/iris-web.git"
    git clone $DFIR_REPO $BASE_DIR/iris-web || error_handler "Cloning DFIR IRIS Repository"
    cd $BASE_DIR/iris-web
    git checkout v2.3.7
    cp .env.model .env
    sudo docker compose build || error_handler "Building DFIR IRIS Containers"
    sudo docker-compose up -d || error_handler "Starting DFIR IRIS Containers"
    cd -
}
