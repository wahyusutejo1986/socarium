#!/bin/bash

install_shuffle() {
    echo "🚀 Installing Shuffle (last)..."
    local BASE_DIR="/opt/socarium"
    local SHUFFLE_REPO="https://github.com/shuffle/Shuffle"
    git clone $SHUFFLE_REPO $BASE_DIR/Shuffle || error_handler "Cloning Shuffle Repository"
    cd $BASE_DIR/Shuffle
    sudo mv docker-compose.yml docker-compose-original.yml #rename original docker-compose
    sudo cp /modules/shuffle/docker-compose.yml #replace original docker-compose to solve conflict port with wazuh
    sudo mkdir shuffle-database
    sudo useradd opensearch
    sudo chown -R 1000:1000 shuffle-database
    sudo swapoff -a
    sudo docker-compose up -d || error_handler "Starting Shuffle Containers"
    cd -
}
