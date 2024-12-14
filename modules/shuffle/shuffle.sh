#!/bin/bash

install_shuffle() {
    echo "🚀 Installing Shuffle (last)..."
    local BASE_DIR="/opt/socarium"
    local SHUFFLE_REPO="https://github.com/shuffle/Shuffle"
    git clone $SHUFFLE_REPO $BASE_DIR/Shuffle || error_handler "Cloning Shuffle Repository"
    cd $BASE_DIR/Shuffle
    docker-compose up -d || error_handler "Starting Shuffle Containers"
    cd -
}
