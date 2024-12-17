#!/bin/bash

install_shuffle() {
    echo "🚀 Installing Shuffle (last)..."
    local BASE_DIR="/opt/socarium"
    local SHUFFLE_REPO="https://github.com/shuffle/Shuffle"
    local current_dir=$(pwd) # Get the current directory dynamically

    git clone $SHUFFLE_REPO $BASE_DIR/Shuffle || error_handler "Cloning Shuffle Repository"
    cd $BASE_DIR/Shuffle
    sudo mv docker-compose.yml docker-compose-original.yml # Rename original docker-compose
    sudo cp $current_dir/modules/shuffle/docker-compose.yml $BASE_DIR/Shuffle/docker-compose.yml # Copy new docker-compose

    # Check if the shuffle-database directory exists
    if [ ! -d "shuffle-database" ]; then
        echo "Creating shuffle-database directory..."
        sudo mkdir shuffle-database
    else
        echo "Directory shuffle-database already exists. Skipping creation."
    fi

    sudo useradd opensearch || true # Avoid error if user already exists
    sudo chown -R 1000:1000 shuffle-database
    sudo swapoff -a
    sudo docker-compose up -d || error_handler "Starting Shuffle Containers"
    cd -
}
