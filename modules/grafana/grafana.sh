#!/bin/bash

set -e  # Exit on error

# get directory where this script install_all.sh executed
BASE_DIR=$(pwd)

# Grafana installation
echo "Installing Grafana..."
if [ ! -d "grafana" ]; then    
    cd $BASE_DIR/modules/grafana/
    sudo docker-compose up -d
else
    echo "Grafana already installed. Checking health..."
    sudo docker ps --filter "name=grafana"
fi
