#!/bin/bash

install_prerequisites() {
    echo "🛠 Installing prerequisites..."
    sudo apt update && sudo apt upgrade -y || error_handler "System Update"
    sudo apt install -y docker docker-compose git curl wget build-essential python3-pip || error_handler "Prerequisites Installation"
}

